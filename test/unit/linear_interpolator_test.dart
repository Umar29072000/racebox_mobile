import 'package:flutter_test/flutter_test.dart';
import 'package:racebox_mobile/core/math/linear_interpolator.dart';

void main() {
  group('LinearInterpolator Tests (FRD SEC-05 & SEC-11 Scenario 4)', () {
    test('Scenario 4 UAT: Exact Finish Time Interpolation at 201.0m is 8.00s', () {
      // Given: sample 1 at t1 = 7.80s, d1 = 195.0m
      // Given: sample 2 at t2 = 8.20s, d2 = 207.0m
      // Target: 201.0m
      // Calculation:
      // ratio = (201.0 - 195.0) / (207.0 - 195.0) = 6.0 / 12.0 = 0.5
      // tfinish = 7.80 + 0.5 * (8.20 - 7.80) = 7.80 + 0.20 = 8.00s
      final tFinish = LinearInterpolator.interpolateFinishTime(
        t1: 7.80,
        d1: 195.0,
        t2: 8.20,
        d2: 207.0,
        dTarget: 201.0,
      );

      expect(tFinish, closeTo(8.00, 0.0001));
    });

    test('Interpolate trap speed at target line', () {
      // At d1 = 195.0m, speed v1 = 110.0 km/h
      // At d2 = 207.0m, speed v2 = 116.0 km/h
      // Target = 201.0m (midpoint) -> vfinish = 113.0 km/h
      final vFinish = LinearInterpolator.interpolateTrapSpeed(
        v1: 110.0,
        d1: 195.0,
        v2: 116.0,
        d2: 207.0,
        dTarget: 201.0,
      );

      expect(vFinish, closeTo(113.0, 0.001));
    });

    test('Slope percentage and drag racing tolerance validation', () {
      // Start altitude: 125.0m, Finish altitude: 124.397m over 201m
      // deltaAlt = -0.603m
      // Slope % = (-0.603 / 201.0) * 100 = -0.3%
      final slope = LinearInterpolator.calculateSlopePercent(
        altitudeStart: 125.0,
        altitudeFinish: 124.397,
        distanceMeters: 201.0,
      );

      expect(slope, closeTo(-0.3, 0.01));
      expect(LinearInterpolator.isValidSlope(slope), isTrue);

      // Downhill steeper than -1.0% is invalid
      expect(LinearInterpolator.isValidSlope(-1.2), isFalse);
      expect(LinearInterpolator.isValidSlope(-0.8), isTrue);
      expect(LinearInterpolator.isValidSlope(0.5), isTrue);
    });

    test('FR-04: 1-Foot Rollout calculation', () {
      // If raw finish time is 8.00s and 1-foot rollout took 0.28s,
      // adjusted time should be 7.72s
      final adjusted = LinearInterpolator.applyOneFootRollout(
        rawFinishTimeSec: 8.00,
        rolloutTimeSec: 0.28,
      );

      expect(adjusted, closeTo(7.72, 0.001));
    });
  });
}

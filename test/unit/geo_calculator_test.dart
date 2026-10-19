import 'package:flutter_test/flutter_test.dart';
import 'package:racebox_mobile/core/math/geo_calculator.dart';

void main() {
  group('GeoCalculator Tests (FRD SEC-05 & SEC-14)', () {
    test('Haversine distance calculation between two GPS coordinates', () {
      // Sentul Dragway start and ~201m point
      const lat1 = -6.291245;
      const lon1 = 106.852418;
      // Moving North approx 201m (0.001809 degrees approx 201m)
      const lat2 = -6.289436;
      const lon2 = 106.852418;

      final dist = GeoCalculator.haversineDistanceMeters(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      expect(dist, closeTo(201.0, 2.0));
    });

    test('Speed conversions between m/s and km/h', () {
      expect(GeoCalculator.mpsToKmh(10.0), closeTo(36.0, 0.001));
      expect(GeoCalculator.kmhToMps(72.0), closeTo(20.0, 0.001));
    });

    test('Multipath outlier rejection rejects unrealistic coordinate jumps (SEC-14)', () {
      // Vehicle jumps 100 meters in 1 second (100 m/s = 360 km/h) -> reject
      final isOutlierValid = GeoCalculator.isValidGpsReading(
        prevLat: -6.291245,
        prevLon: 106.852418,
        newLat: -6.290245, // approx 111m jump
        newLon: 106.852418,
        deltaSeconds: 1.0,
        maxSpeedThresholdMps: 55.0, // 55 m/s threshold
      );

      expect(isOutlierValid, isFalse);

      // Normal movement of 20 meters in 1 second (20 m/s = 72 km/h) -> valid
      final isNormalValid = GeoCalculator.isValidGpsReading(
        prevLat: -6.291245,
        prevLon: 106.852418,
        newLat: -6.291065, // approx 20m jump
        newLon: 106.852418,
        deltaSeconds: 1.0,
        maxSpeedThresholdMps: 55.0,
      );

      expect(isNormalValid, isTrue);
    });
  });
}

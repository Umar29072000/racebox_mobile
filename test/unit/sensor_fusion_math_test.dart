import 'package:flutter_test/flutter_test.dart';
import 'package:racebox_mobile/core/constants/race_constants.dart';
import 'package:racebox_mobile/core/math/sensor_fusion_math.dart';

void main() {
  group('SensorFusionMath Tests (FRD SEC-05 A & SEC-11)', () {
    test('Magnitude calculation is orientation independent', () {
      // 3-axis acceleration: ax = 3.0, ay = 4.0, az = 0.0 -> sqrt(9+16) = 5.0
      final mag = SensorFusionMath.calculateMagnitude(3.0, 4.0, 0.0);
      expect(mag, closeTo(5.0, 0.0001));

      // Inverted orientation: ax = 0.0, ay = -3.0, az = -4.0 -> still 5.0
      final magInverted = SensorFusionMath.calculateMagnitude(0.0, -3.0, -4.0);
      expect(magInverted, closeTo(5.0, 0.0001));
    });

    test('Net acceleration subtracts engine vibration noise floor', () {
      // Calibrated noise floor is 0.5 m/s²
      // Sensed magnitude is 2.5 m/s²
      // Net should be 2.0 m/s²
      final net = SensorFusionMath.calculateNetAcceleration(
        ax: 2.0,
        ay: 1.5,
        az: 0.0,
        noiseFloorMps2: 0.5,
      );
      // magnitude = sqrt(4 + 2.25) = 2.5
      expect(net, closeTo(2.0, 0.0001));
    });

    test('Compute dynamic noise floor from stationary samples during Staging', () {
      final samples = [0.35, 0.40, 0.45, 0.40];
      final floor = SensorFusionMath.computeNoiseFloor(samples);
      expect(floor, closeTo(0.40, 0.0001));
    });

    test('Scenario 1 UAT: Launch triggered when accel >= 0.15G sustained for 40ms', () {
      // 4 samples @ 100Hz = 40ms
      // If G-forces exceed 0.15G (e.g. 0.20G, 0.35G, 0.50G, 0.80G), launch is triggered
      final launchSpike = [0.18, 0.25, 0.40, 0.70];
      final isTriggered = SensorFusionMath.isLaunchTriggered(
        recentGForces: launchSpike,
        thresholdG: RaceConstants.gForceTriggerThreshold,
        requiredConsecutiveSamples: 4,
      );
      expect(isTriggered, isTrue);

      // If only a transient 10ms-20ms vibration glitch occurred (e.g. 1-2 samples), NOT triggered
      final glitch = [0.05, 0.25, 0.20, 0.05];
      final isGlitchTriggered = SensorFusionMath.isLaunchTriggered(
        recentGForces: glitch,
        thresholdG: RaceConstants.gForceTriggerThreshold,
        requiredConsecutiveSamples: 4,
      );
      expect(isGlitchTriggered, isFalse);
    });

    test('IMU dead-reckoning initial velocity integration v_imu(t)', () {
      // Net accel = 4.0 m/s², deltaT = 0.1s
      // deltaV = 4.0 * 0.1 = 0.4 m/s = 0.4 * 3.6 = 1.44 km/h
      final newSpeed = SensorFusionMath.integrateImuVelocity(
        currentVelocityKmh: 0.0,
        netAccelMps2: 4.0,
        deltaSeconds: 0.1,
      );
      expect(newSpeed, closeTo(1.44, 0.001));
    });
  });
}

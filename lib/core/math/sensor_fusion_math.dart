import 'dart:math';

/// Sensor Fusion and IMU Dead-Reckoning Engine
/// Implements orientation-independent acceleration calculations from FRD SEC-05 (A).
class SensorFusionMath {
  static const double standardGravity = 9.80665; // m/s²

  /// Computes the magnitude (resultant) of 3-axis linear acceleration:
  /// magnitude = sqrt(ax² + ay² + az²)
  static double calculateMagnitude(double ax, double ay, double az) {
    return sqrt(ax * ax + ay * ay + az * az);
  }

  /// Converts acceleration in m/s² to G-force (1G ≈ 9.80665 m/s²)
  static double toGForce(double accelMps2) {
    return accelMps2 / standardGravity;
  }

  /// Converts G-force to m/s²
  static double fromGForce(double gForce) {
    return gForce * standardGravity;
  }

  /// Calculates net forward acceleration by subtracting the calibrated noise floor:
  /// anet = sqrt(ax² + ay² + az²) - anoise
  static double calculateNetAcceleration({
    required double ax,
    required double ay,
    required double az,
    required double noiseFloorMps2,
  }) {
    final rawMagnitude = calculateMagnitude(ax, ay, az);
    final net = rawMagnitude - noiseFloorMps2;
    return net > 0.0 ? net : 0.0;
  }

  /// Calibrates the engine vibration noise floor during the 2-second Staging period.
  /// Averages recorded stationary magnitudes to establish a dynamic noise baseline.
  static double computeNoiseFloor(List<double> stationaryMagnitudes) {
    if (stationaryMagnitudes.isEmpty) return 0.05 * standardGravity; // fallback ~0.05G
    final sum = stationaryMagnitudes.reduce((a, b) => a + b);
    return sum / stationaryMagnitudes.length;
  }

  /// Checks if vehicle launch condition is met:
  /// Consecutive samples exceeding threshold (0.15G) for required window (e.g. 40ms)
  static bool isLaunchTriggered({
    required List<double> recentGForces,
    double thresholdG = 0.15,
    int requiredConsecutiveSamples = 4, // 4 samples @ 100Hz = 40ms
  }) {
    if (recentGForces.length < requiredConsecutiveSamples) return false;
    final lastWindow = recentGForces.sublist(
      recentGForces.length - requiredConsecutiveSamples,
    );
    return lastWindow.every((g) => g >= thresholdG);
  }

  /// Dead-reckoning velocity integration for the first 500ms before GPS lock refreshes:
  /// vimu(t) = sum(anet * delta_t)
  /// Returns integrated velocity in km/h.
  static double integrateImuVelocity({
    required double currentVelocityKmh,
    required double netAccelMps2,
    required double deltaSeconds,
  }) {
    // a in m/s² * delta_t in seconds = delta_v in m/s
    final deltaVMps = netAccelMps2 * deltaSeconds;
    // convert m/s to km/h (multiply by 3.6)
    final deltaVKmh = deltaVMps * 3.6;
    return (currentVelocityKmh + deltaVKmh).clamp(0.0, 400.0);
  }
}

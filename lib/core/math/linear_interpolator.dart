/// Linear Interpolation Engine for Sub-Centisecond Precision Timing
/// Implements exact mathematical formulas from FRD SEC-05 (B) and SEC-11 (Scenario 4).
class LinearInterpolator {
  /// Computes exact timestamp when vehicle crossed target distance:
  /// tfinish = t1 + [ (dtarget - d1) / (d2 - d1) ] * (t2 - t1)
  ///
  /// [t1]: Timestamp (in seconds or ms) before target distance
  /// [d1]: Distance (meters) recorded at t1
  /// [t2]: Timestamp (in seconds or ms) after target distance
  /// [d2]: Distance (meters) recorded at t2
  /// [dTarget]: Target distance in meters (e.g. 201.0m, 402.0m)
  static double interpolateFinishTime({
    required double t1,
    required double d1,
    required double t2,
    required double d2,
    required double dTarget,
  }) {
    if (d2 <= d1) {
      return t2;
    }
    final ratio = (dTarget - d1) / (d2 - d1);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    return t1 + clampedRatio * (t2 - t1);
  }

  /// Computes exact trap speed when vehicle crossed target distance:
  /// vfinish = v1 + [ (dtarget - d1) / (d2 - d1) ] * (v2 - v1)
  static double interpolateTrapSpeed({
    required double v1,
    required double d1,
    required double v2,
    required double d2,
    required double dTarget,
  }) {
    if (d2 <= d1) {
      return v2;
    }
    final ratio = (dTarget - d1) / (d2 - d1);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    return v1 + clampedRatio * (v2 - v1);
  }

  /// Computes track slope percentage:
  /// Slope (%) = [ (Altfinish - Altstart) / dtarget ] * 100
  /// Standard drag racing rule: Slope must be between -1.0% and +1.0% for a valid record.
  static double calculateSlopePercent({
    required double altitudeStart,
    required double altitudeFinish,
    required double distanceMeters,
  }) {
    if (distanceMeters <= 0) return 0.0;
    return ((altitudeFinish - altitudeStart) / distanceMeters) * 100.0;
  }

  /// Validates if the slope is within drag racing tolerance (<= 1.0% decline)
  static bool isValidSlope(double slopePercent) {
    // Decline steeper than -1.0% is invalid downhill advantage
    // Uphill is always valid (disadvantage to racer), but standard rule checks |slope| <= 1.0%
    return slopePercent.abs() <= 1.0;
  }

  /// Computes 1-Foot Rollout adjustment (FR-04).
  /// Returns the adjusted finish time after deducting the time it took to travel the first 1 foot (0.3048m).
  static double applyOneFootRollout({
    required double rawFinishTimeSec,
    required double rolloutTimeSec,
  }) {
    if (rolloutTimeSec <= 0 || rolloutTimeSec >= rawFinishTimeSec) {
      return rawFinishTimeSec;
    }
    return rawFinishTimeSec - rolloutTimeSec;
  }
}

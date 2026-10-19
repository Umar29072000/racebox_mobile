class RaceConstants {
  // SEC-04 & FR-02: Auto-Start Trigger
  // Resultant linear acceleration >= 0.15G (≈ 1.47 m/s²)
  static const double gForceTriggerThreshold = 0.15; // in G
  static const double accelTriggerThresholdMps2 = 0.15 * 9.80665; // ≈ 1.471 m/s²

  // Accel trigger hold time required to confirm real movement vs vibration spike
  static const int triggerHoldDurationMs = 40; // 40 milliseconds

  // SEC-04 & FR-03: False-Start Cancellation
  // If within 1.5s after IMU trigger, GPS speed does not reach >= 3.0 km/h,
  // the start is cancelled and state resets back to ARMED.
  static const int falseStartWindowMs = 1500; // 1.5 seconds
  static const double falseStartMinSpeedKmh = 3.0; // 3 km/h

  // SEC-04 & FR-01: GNSS Accuracy & Staging requirements
  static const double maxGpsAccuracyForStaging = 2.5; // meters (≤ 2.5m required)
  static const int minSatellitesForStaging = 8; // Satellites ≥ 8 units

  // SEC-04 State 2: Staging duration (stationary at 0 km/h for 2.0s to calibrate idle engine noise)
  static const int stagingCalibrationDurationMs = 2000; // 2 seconds

  // SEC-04 State 5: Auto-arm reset duration (0 km/h for 3.0s after finish)
  static const int autoArmStopDurationMs = 3000; // 3 seconds

  // FR-09: Auto-Cutoff for battery saving (10 minutes idle)
  static const int autoCutoffInactivityMs = 10 * 60 * 1000; // 10 minutes

  // FR-04: 1-Foot Rollout Distance
  // Standard drag strip photocell rollout delay distance (1 foot = 0.3048 m)
  static const double oneFootRolloutMeters = 0.3048;

  // SEC-05 & SEC-12: High-Frequency Sensor Rates
  static const int imuTargetHz = 100; // 100Hz (10ms interval)
  static const int maxGpsMultipathSpeedMps = 50; // 50 m/s (180 km/h sudden jump in 1s)

  // Standard Split Distances in Meters
  static const double distance60ftMeters = 18.288; // 60 feet
  static const double distance100mMeters = 100.0;
  static const double distance201mMeters = 201.0; // 1/8 Mile
  static const double distance402mMeters = 402.0; // 1/4 Mile
}

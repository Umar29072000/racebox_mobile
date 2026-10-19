import 'dart:math';

/// Geographic and Kinematic Calculations
class GeoCalculator {
  static const double earthRadiusMeters = 6371000.0;

  /// Haversine formula to compute great-circle distance between two GPS coordinates in meters.
  static double haversineDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Converts speed in m/s to km/h
  static double mpsToKmh(double mps) => mps * 3.6;

  /// Converts speed in km/h to m/s
  static double kmhToMps(double kmh) => kmh / 3.6;

  /// Validates GPS sample against multipath reflections (SEC-14):
  /// Rejects outlier jumps that exceed physical vehicle performance limits (e.g. > 50 m/s jump).
  static bool isValidGpsReading({
    required double prevLat,
    required double prevLon,
    required double newLat,
    required double newLon,
    required double deltaSeconds,
    double maxSpeedThresholdMps = 55.0, // ≈ 200 km/h
  }) {
    if (deltaSeconds <= 0) return false;
    final dist = haversineDistanceMeters(
      lat1: prevLat,
      lon1: prevLon,
      lat2: newLat,
      lon2: newLon,
    );
    final impliedSpeedMps = dist / deltaSeconds;
    return impliedSpeedMps <= maxSpeedThresholdMps;
  }

  static double _toRadians(double degrees) => degrees * (pi / 180.0);
}

import 'package:equatable/equatable.dart';

/// Telemetry Sample Point (FRD SEC-10: TelemetrySamples)
class TelemetryPoint extends Equatable {
  final int? sampleId;
  final String sessionId;
  final int elapsedMs;
  final double speedKmh;
  final double distanceMeters;
  final double linearAccelG;
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const TelemetryPoint({
    this.sampleId,
    required this.sessionId,
    required this.elapsedMs,
    required this.speedKmh,
    required this.distanceMeters,
    required this.linearAccelG,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (sampleId != null) 'sampleId': sampleId,
      'sessionId': sessionId,
      'elapsedMs': elapsedMs,
      'speedKmh': speedKmh,
      'distanceMeters': distanceMeters,
      'linearAccelG': linearAccelG,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TelemetryPoint.fromMap(Map<String, dynamic> map) {
    return TelemetryPoint(
      sampleId: map['sampleId'] as int?,
      sessionId: map['sessionId'] as String,
      elapsedMs: map['elapsedMs'] as int,
      speedKmh: (map['speedKmh'] as num).toDouble(),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      linearAccelG: (map['linearAccelG'] as num).toDouble(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
        sampleId,
        sessionId,
        elapsedMs,
        speedKmh,
        distanceMeters,
        linearAccelG,
        latitude,
        longitude,
        altitude,
        timestamp,
      ];
}

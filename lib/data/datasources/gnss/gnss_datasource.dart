import 'package:equatable/equatable.dart';

class GnssReading extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedKmh;
  final double accuracyMeters;
  final int satellitesCount;
  final DateTime timestamp;

  const GnssReading({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedKmh,
    required this.accuracyMeters,
    required this.satellitesCount,
    required this.timestamp,
  });

  bool get isHighPrecision => accuracyMeters <= 2.5 && satellitesCount >= 8;

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        speedKmh,
        accuracyMeters,
        satellitesCount,
        timestamp,
      ];
}

abstract class GnssDataSource {
  Stream<GnssReading> get stream;
  Future<bool> requestPermission();
  Future<GnssReading?> getCurrentReading();
  void dispose();
}

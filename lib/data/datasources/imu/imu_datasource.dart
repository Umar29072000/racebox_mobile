import 'dart:math';
import 'package:equatable/equatable.dart';

class ImuReading extends Equatable {
  final double ax; // m/s²
  final double ay; // m/s²
  final double az; // m/s²
  final double magnitude; // m/s²
  final double gForce; // G (magnitude / 9.80665)
  final DateTime timestamp;

  ImuReading({
    required this.ax,
    required this.ay,
    required this.az,
    required this.timestamp,
  })  : magnitude = sqrt(ax * ax + ay * ay + az * az),
        gForce = sqrt(ax * ax + ay * ay + az * az) / 9.80665;

  @override
  List<Object?> get props => [ax, ay, az, magnitude, gForce, timestamp];
}

abstract class ImuDataSource {
  Stream<ImuReading> get stream;
  void dispose();
}

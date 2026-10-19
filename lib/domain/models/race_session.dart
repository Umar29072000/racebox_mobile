import 'package:equatable/equatable.dart';
import 'discipline_type.dart';
import 'telemetry_point.dart';

/// Race Session Record (FRD SEC-10: RaceSessions)
class RaceSession extends Equatable {
  final String sessionId;
  final String? vehicleId;
  final String vehicleName;
  final DisciplineType disciplineType;
  final DateTime createdAt;
  final double finalTimeSec;
  final double trapSpeedKmh;
  final double peakGForce;
  final double slopePercent;
  final bool isValidSlope;
  final double? split60ftSec;
  final double? split100mSec;
  final double? split201mSec;
  final double? split402mSec;
  final double? split0To100Sec;
  final double? oneFootRolloutSec;
  final bool isRolloutApplied;
  final List<TelemetryPoint> telemetrySamples;

  const RaceSession({
    required this.sessionId,
    this.vehicleId,
    required this.vehicleName,
    required this.disciplineType,
    required this.createdAt,
    required this.finalTimeSec,
    required this.trapSpeedKmh,
    required this.peakGForce,
    required this.slopePercent,
    required this.isValidSlope,
    this.split60ftSec,
    this.split100mSec,
    this.split201mSec,
    this.split402mSec,
    this.split0To100Sec,
    this.oneFootRolloutSec,
    this.isRolloutApplied = false,
    this.telemetrySamples = const [],
  });

  RaceSession copyWith({
    String? sessionId,
    String? vehicleId,
    String? vehicleName,
    DisciplineType? disciplineType,
    DateTime? createdAt,
    double? finalTimeSec,
    double? trapSpeedKmh,
    double? peakGForce,
    double? slopePercent,
    bool? isValidSlope,
    double? split60ftSec,
    double? split100mSec,
    double? split201mSec,
    double? split402mSec,
    double? split0To100Sec,
    double? oneFootRolloutSec,
    bool? isRolloutApplied,
    List<TelemetryPoint>? telemetrySamples,
  }) {
    return RaceSession(
      sessionId: sessionId ?? this.sessionId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      disciplineType: disciplineType ?? this.disciplineType,
      createdAt: createdAt ?? this.createdAt,
      finalTimeSec: finalTimeSec ?? this.finalTimeSec,
      trapSpeedKmh: trapSpeedKmh ?? this.trapSpeedKmh,
      peakGForce: peakGForce ?? this.peakGForce,
      slopePercent: slopePercent ?? this.slopePercent,
      isValidSlope: isValidSlope ?? this.isValidSlope,
      split60ftSec: split60ftSec ?? this.split60ftSec,
      split100mSec: split100mSec ?? this.split100mSec,
      split201mSec: split201mSec ?? this.split201mSec,
      split402mSec: split402mSec ?? this.split402mSec,
      split0To100Sec: split0To100Sec ?? this.split0To100Sec,
      oneFootRolloutSec: oneFootRolloutSec ?? this.oneFootRolloutSec,
      isRolloutApplied: isRolloutApplied ?? this.isRolloutApplied,
      telemetrySamples: telemetrySamples ?? this.telemetrySamples,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'disciplineType': disciplineType.name,
      'createdAt': createdAt.toIso8601String(),
      'finalTimeSec': finalTimeSec,
      'trapSpeedKmh': trapSpeedKmh,
      'peakGForce': peakGForce,
      'slopePercent': slopePercent,
      'isValidSlope': isValidSlope ? 1 : 0,
      'split60ftSec': split60ftSec,
      'split100mSec': split100mSec,
      'split201mSec': split201mSec,
      'split402mSec': split402mSec,
      'split0To100Sec': split0To100Sec,
      'oneFootRolloutSec': oneFootRolloutSec,
      'isRolloutApplied': isRolloutApplied ? 1 : 0,
    };
  }

  factory RaceSession.fromMap(
    Map<String, dynamic> map, {
    List<TelemetryPoint> samples = const [],
  }) {
    return RaceSession(
      sessionId: map['sessionId'] as String,
      vehicleId: map['vehicleId'] as String?,
      vehicleName: map['vehicleName'] as String? ?? 'Default Bike',
      disciplineType: DisciplineTypeExtension.fromString(
        map['disciplineType'] as String? ?? 'drag201m',
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      finalTimeSec: (map['finalTimeSec'] as num).toDouble(),
      trapSpeedKmh: (map['trapSpeedKmh'] as num).toDouble(),
      peakGForce: (map['peakGForce'] as num).toDouble(),
      slopePercent: (map['slopePercent'] as num).toDouble(),
      isValidSlope: (map['isValidSlope'] as int? ?? 1) == 1,
      split60ftSec: (map['split60ftSec'] as num?)?.toDouble(),
      split100mSec: (map['split100mSec'] as num?)?.toDouble(),
      split201mSec: (map['split201mSec'] as num?)?.toDouble(),
      split402mSec: (map['split402mSec'] as num?)?.toDouble(),
      split0To100Sec: (map['split0To100Sec'] as num?)?.toDouble(),
      oneFootRolloutSec: (map['oneFootRolloutSec'] as num?)?.toDouble(),
      isRolloutApplied: (map['isRolloutApplied'] as int? ?? 0) == 1,
      telemetrySamples: samples,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        vehicleId,
        vehicleName,
        disciplineType,
        createdAt,
        finalTimeSec,
        trapSpeedKmh,
        peakGForce,
        slopePercent,
        isValidSlope,
        split60ftSec,
        split100mSec,
        split201mSec,
        split402mSec,
        split0To100Sec,
        oneFootRolloutSec,
        isRolloutApplied,
        telemetrySamples,
      ];
}

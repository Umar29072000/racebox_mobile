import 'package:equatable/equatable.dart';
import '../../../domain/models/discipline_type.dart';
import '../../../domain/models/fsm_state.dart';
import '../../../domain/models/race_session.dart';
import '../../../domain/models/vehicle_profile.dart';

class RaceTimerState extends Equatable {
  final FsmState fsmState;
  final DisciplineType discipline;
  final VehicleProfile? currentVehicle;
  final double currentSpeedKmh;
  final double elapsedSeconds;
  final double currentDistanceMeters;
  final double currentGForce;
  final double peakGForce;
  final int gpsSatellites;
  final double gpsAccuracyMeters;
  final int imuSampleRateHz;
  final double slopePercent;
  final bool isValidSlope;

  // Split times
  final double? split60ft;
  final double? split100m;
  final double? split201m;
  final double? split402m;
  final double? split0To100;

  // Rollout & Settings
  final bool oneFootRolloutEnabled;
  final double? oneFootRolloutSec;
  final bool isPocketMode;
  final bool isSimulated;
  final double triggerThresholdG;

  // Completion
  final RaceSession? lastFinishedSession;
  final String? alertMessage;

  const RaceTimerState({
    this.fsmState = FsmState.idleGpsLock,
    this.discipline = DisciplineType.drag201m,
    this.currentVehicle,
    this.currentSpeedKmh = 0.0,
    this.elapsedSeconds = 0.0,
    this.currentDistanceMeters = 0.0,
    this.currentGForce = 0.0,
    this.peakGForce = 0.0,
    this.gpsSatellites = 0,
    this.gpsAccuracyMeters = 99.0,
    this.imuSampleRateHz = 100,
    this.slopePercent = 0.0,
    this.isValidSlope = true,
    this.split60ft,
    this.split100m,
    this.split201m,
    this.split402m,
    this.split0To100,
    this.oneFootRolloutEnabled = false,
    this.oneFootRolloutSec,
    this.isPocketMode = false,
    this.isSimulated = false,
    this.triggerThresholdG = 4.0,
    this.lastFinishedSession,
    this.alertMessage,
  });

  bool get isGpsReady => gpsAccuracyMeters <= 2.5 && gpsSatellites >= 8;

  RaceTimerState copyWith({
    FsmState? fsmState,
    DisciplineType? discipline,
    VehicleProfile? currentVehicle,
    double? currentSpeedKmh,
    double? elapsedSeconds,
    double? currentDistanceMeters,
    double? currentGForce,
    double? peakGForce,
    int? gpsSatellites,
    double? gpsAccuracyMeters,
    int? imuSampleRateHz,
    double? slopePercent,
    bool? isValidSlope,
    double? split60ft,
    double? split100m,
    double? split201m,
    double? split402m,
    double? split0To100,
    bool? oneFootRolloutEnabled,
    double? oneFootRolloutSec,
    bool? isPocketMode,
    bool? isSimulated,
    double? triggerThresholdG,
    RaceSession? lastFinishedSession,
    String? alertMessage,
    bool clearSplits = false,
    bool clearRollout = false,
    bool clearLastSession = false,
  }) {
    return RaceTimerState(
      fsmState: fsmState ?? this.fsmState,
      discipline: discipline ?? this.discipline,
      currentVehicle: currentVehicle ?? this.currentVehicle,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
      currentGForce: currentGForce ?? this.currentGForce,
      peakGForce: peakGForce ?? this.peakGForce,
      gpsSatellites: gpsSatellites ?? this.gpsSatellites,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      imuSampleRateHz: imuSampleRateHz ?? this.imuSampleRateHz,
      slopePercent: slopePercent ?? this.slopePercent,
      isValidSlope: isValidSlope ?? this.isValidSlope,
      split60ft: clearSplits ? null : (split60ft ?? this.split60ft),
      split100m: clearSplits ? null : (split100m ?? this.split100m),
      split201m: clearSplits ? null : (split201m ?? this.split201m),
      split402m: clearSplits ? null : (split402m ?? this.split402m),
      split0To100: clearSplits ? null : (split0To100 ?? this.split0To100),
      oneFootRolloutEnabled: oneFootRolloutEnabled ?? this.oneFootRolloutEnabled,
      oneFootRolloutSec: (clearSplits || clearRollout) ? null : (oneFootRolloutSec ?? this.oneFootRolloutSec),
      isPocketMode: isPocketMode ?? this.isPocketMode,
      isSimulated: isSimulated ?? this.isSimulated,
      triggerThresholdG: triggerThresholdG ?? this.triggerThresholdG,
      lastFinishedSession: clearLastSession ? null : (lastFinishedSession ?? this.lastFinishedSession),
      alertMessage: alertMessage,
    );
  }

  @override
  List<Object?> get props => [
        fsmState,
        discipline,
        currentVehicle,
        currentSpeedKmh,
        elapsedSeconds,
        currentDistanceMeters,
        currentGForce,
        peakGForce,
        gpsSatellites,
        gpsAccuracyMeters,
        imuSampleRateHz,
        slopePercent,
        isValidSlope,
        split60ft,
        split100m,
        split201m,
        split402m,
        split0To100,
        oneFootRolloutEnabled,
        oneFootRolloutSec,
        isPocketMode,
        isSimulated,
        triggerThresholdG,
        lastFinishedSession,
        alertMessage,
      ];
}

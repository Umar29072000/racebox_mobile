import 'package:equatable/equatable.dart';
import '../../../data/datasources/gnss/gnss_datasource.dart';
import '../../../data/datasources/imu/imu_datasource.dart';
import '../../../domain/models/discipline_type.dart';
import '../../../domain/models/vehicle_profile.dart';

abstract class RaceTimerEvent extends Equatable {
  const RaceTimerEvent();

  @override
  List<Object?> get props => [];
}

class InitTelemetryServices extends RaceTimerEvent {
  final bool isSimulated;
  const InitTelemetryServices({this.isSimulated = false});

  @override
  List<Object?> get props => [isSimulated];
}

class GnssDataReceived extends RaceTimerEvent {
  final GnssReading reading;
  const GnssDataReceived(this.reading);

  @override
  List<Object?> get props => [reading];
}

class ImuDataReceived extends RaceTimerEvent {
  final ImuReading reading;
  const ImuDataReceived(this.reading);

  @override
  List<Object?> get props => [reading];
}

class ChangeDiscipline extends RaceTimerEvent {
  final DisciplineType discipline;
  const ChangeDiscipline(this.discipline);

  @override
  List<Object?> get props => [discipline];
}

class ToggleOneFootRollout extends RaceTimerEvent {
  final bool enabled;
  const ToggleOneFootRollout(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class TogglePocketMode extends RaceTimerEvent {
  final bool enabled;
  const TogglePocketMode(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetActiveVehicle extends RaceTimerEvent {
  final VehicleProfile vehicle;
  const SetActiveVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class ForceArmRace extends RaceTimerEvent {
  const ForceArmRace();
}

class ResetRaceToIdle extends RaceTimerEvent {
  const ResetRaceToIdle();
}

class SimulateTriggerLaunchEvent extends RaceTimerEvent {
  const SimulateTriggerLaunchEvent();
}

class SimulateFalseStartEvent extends RaceTimerEvent {
  const SimulateFalseStartEvent();
}

class TimerTickEvent extends RaceTimerEvent {
  const TimerTickEvent();
}

class UpdateTriggerThreshold extends RaceTimerEvent {
  final double thresholdG;
  const UpdateTriggerThreshold(this.thresholdG);

  @override
  List<Object?> get props => [thresholdG];
}

class ForceFinishAndSaveRace extends RaceTimerEvent {
  const ForceFinishAndSaveRace();
}

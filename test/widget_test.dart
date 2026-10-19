import 'package:flutter_test/flutter_test.dart';
import 'package:racebox_mobile/core/constants/race_constants.dart';
import 'package:racebox_mobile/domain/models/discipline_type.dart';
import 'package:racebox_mobile/domain/models/fsm_state.dart';
import 'package:racebox_mobile/domain/models/vehicle_profile.dart';

void main() {
  test('Domain models and FSM states are correctly defined', () {
    expect(FsmState.idleGpsLock.displayName, 'KUNCI GPS');
    expect(FsmState.staging.displayName, 'STAGING (SIAGA)');
    expect(FsmState.armed.displayName, 'SIAP GAS (ARMED)');
    expect(FsmState.running.displayName, 'TARIKAN GAS');
    expect(FsmState.finished.displayName, 'FINIS');

    expect(DisciplineType.drag201m.targetDistanceMeters, 201.0);
    expect(DisciplineType.drag402m.targetDistanceMeters, 402.0);
    expect(DisciplineType.sprint0To100.targetSpeedKmh, 100.0);

    const vehicle = VehicleProfile(
      id: 'test-vario',
      vehicleName: 'Vario 160 Bore-Up',
      kerbWeightKg: 118.0,
      sprocketOrRollerNote: 'Roller 12gr, Per CVT 1500 RPM',
      isDefault: true,
    );

    final map = vehicle.toMap();
    expect(map['vehicleName'], 'Vario 160 Bore-Up');
    expect(map['kerbWeightKg'], 118.0);

    final recreated = VehicleProfile.fromMap(map);
    expect(recreated.vehicleName, 'Vario 160 Bore-Up');
    expect(recreated.isDefault, isTrue);

    expect(RaceConstants.gForceTriggerThreshold, 0.15);
    expect(RaceConstants.maxGpsAccuracyForStaging, 2.5);
    expect(RaceConstants.minSatellitesForStaging, 8);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:racebox_mobile/core/audio/audio_cue_service.dart';
import 'package:racebox_mobile/data/datasources/gnss/gnss_datasource.dart';
import 'package:racebox_mobile/data/datasources/imu/imu_datasource.dart';
import 'package:racebox_mobile/domain/models/discipline_type.dart';
import 'package:racebox_mobile/domain/models/fsm_state.dart';
import 'package:racebox_mobile/domain/models/race_session.dart';
import 'package:racebox_mobile/domain/models/telemetry_point.dart';
import 'package:racebox_mobile/domain/models/vehicle_profile.dart';
import 'package:racebox_mobile/domain/repositories/race_session_repository.dart';
import 'package:racebox_mobile/domain/repositories/vehicle_repository.dart';
import 'package:racebox_mobile/presentation/bloc/timer/race_timer_bloc.dart';
import 'package:racebox_mobile/presentation/bloc/timer/race_timer_event.dart';

class MockSessionRepository implements RaceSessionRepository {
  final List<RaceSession> savedSessions = [];

  @override
  Future<void> saveRaceSession(RaceSession session) async {
    savedSessions.add(session);
  }

  @override
  Future<List<RaceSession>> getAllSessions({DisciplineType? discipline, String? vehicleId}) async => savedSessions;

  @override
  Future<RaceSession?> getSessionById(String sessionId) async => null;

  @override
  Future<List<TelemetryPoint>> getTelemetryPoints(String sessionId) async => [];

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<RaceSession?> getBestSession(DisciplineType discipline, {String? vehicleId}) async => null;

  @override
  Future<String> exportSessionToCsv(String sessionId) async => '';
}

class MockVehicleRepository implements VehicleRepository {
  @override
  Future<List<VehicleProfile>> getVehicles() async => [];

  @override
  Future<VehicleProfile?> getDefaultVehicle() async => const VehicleProfile(
        id: 'vario-mock',
        vehicleName: 'Vario 160 Bore-Up',
        kerbWeightKg: 118.0,
        sprocketOrRollerNote: 'Roller 12gr',
        isDefault: true,
      );

  @override
  Future<void> saveVehicle(VehicleProfile vehicle) async {}

  @override
  Future<void> setDefaultVehicle(String vehicleId) async {}

  @override
  Future<void> deleteVehicle(String vehicleId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RaceTimer FSM Logic & UAT Scenarios (FRD SEC-04 & SEC-11)', () {
    late MockSessionRepository mockSessionRepo;
    late MockVehicleRepository mockVehicleRepo;
    late AudioCueService mockAudioCue;
    late RaceTimerBloc bloc;

    setUp(() {
      mockSessionRepo = MockSessionRepository();
      mockVehicleRepo = MockVehicleRepository();
      mockAudioCue = AudioCueService.mock();
      bloc = RaceTimerBloc(
        sessionRepo: mockSessionRepo,
        vehicleRepo: mockVehicleRepo,
        audioCue: mockAudioCue,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is IDLE / GPS LOCK', () {
      expect(bloc.state.fsmState, FsmState.idleGpsLock);
      expect(bloc.state.elapsedSeconds, 0.0);
      expect(bloc.state.discipline, DisciplineType.drag201m);
    });

    test('Scenario 1 UAT: Staging blocks if GPS accuracy > 2.5m (FR-01)', () async {
      // Send poor GPS accuracy (3.5m)
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291245,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 0.0,
        accuracyMeters: 3.5, // > 2.5m
        satellitesCount: 6, // < 8
        timestamp: DateTime.now(),
      )));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.idleGpsLock);
      expect(bloc.state.isGpsReady, isFalse);
    });

    test('State 1 to State 2: Enters STAGING when GPS accuracy <= 2.5m, sat >= 8 and speed == 0', () async {
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291245,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 0.0,
        accuracyMeters: 1.5, // <= 2.5m
        satellitesCount: 12, // >= 8
        timestamp: DateTime.now(),
      )));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.staging);
      expect(bloc.state.isGpsReady, isTrue);
    });

    test('ForceArmRace bypasses to ARMED state and sets origin', () async {
      bloc.add(const ForceArmRace());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.fsmState, FsmState.armed);
      expect(bloc.state.elapsedSeconds, 0.0);
    });

    test('Scenario 1 UAT: Launch trigger from ARMED when IMU accel >= 0.15G sustained', () async {
      bloc.add(const ForceArmRace());
      bloc.add(const UpdateTriggerThreshold(0.15));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.armed);

      // Send 5 IMU events exceeding 0.15G (40ms @ 100Hz)
      // 0.20G = ~1.96 m/s²
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.2,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }

      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.running);
    });

    test('Scenario 2 UAT: Anti False-Trigger cancels start if speed < 3 km/h after 1.5s', () async {
      bloc.add(const ForceArmRace());
      bloc.add(const UpdateTriggerThreshold(0.15));
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger launch
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.5,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.running);

      // Wait 1550ms with vehicle speed remaining < 3 km/h (revving engine in place)
      await Future.delayed(const Duration(milliseconds: 1550));

      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291245,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 1.2, // < 3.0 km/h
        accuracyMeters: 1.2,
        satellitesCount: 14,
        timestamp: DateTime.now(),
      )));

      await Future.delayed(const Duration(milliseconds: 50));
      // Must automatically reset back to ARMED!
      expect(bloc.state.fsmState, FsmState.armed);
      expect(bloc.state.alertMessage, contains('Start Palsu'));
    });

    test('Anti-Vibration: Stationary engine idle vibration (0.22G) does NOT trigger timer', () async {
      // Simulate engine idle vibration while waiting in IDLE
      for (int i = 0; i < 20; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.15, // ~0.22G engine idle vibration
          ay: 0.2,
          az: 0.1,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 20));

      // User arms the race
      bloc.add(const ForceArmRace());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.armed);

      // Bike continues to idle at 0.22G for 30 samples
      for (int i = 0; i < 30; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.15,
          ay: 0.2,
          az: 0.1,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));

      // MUST REMAIN IN ARMED (timer must NOT start!)
      expect(bloc.state.fsmState, FsmState.armed);
      expect(bloc.state.elapsedSeconds, 0.0);
    });

    test('Anti-Jitter: Stationary GPS speed jitter (1.2 km/h) does NOT trigger timer in ARMED', () async {
      bloc.add(const ForceArmRace());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.armed);

      // GPS jitter: 1.2 km/h without physical displacement
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291245,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 1.2,
        accuracyMeters: 5.0,
        satellitesCount: 10,
        timestamp: DateTime.now(),
      )));
      await Future.delayed(const Duration(milliseconds: 50));

      // MUST REMAIN IN ARMED
      expect(bloc.state.fsmState, FsmState.armed);
    });

    test('Manual Finish & Save: Ends run early and persists session', () async {
      bloc.add(const ForceArmRace());
      bloc.add(const UpdateTriggerThreshold(0.15));
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger launch
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.5,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.running);

      // Rider taps FINIS & SIMPAN early
      bloc.add(const ForceFinishAndSaveRace());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.fsmState, FsmState.finished);
      expect(bloc.state.lastFinishedSession, isNotNull);
    });
    test('User Threshold 4.0G: Accelerations below 4.0G (e.g. 0.8G) do not trigger, >= 4.0G triggers', () async {
      bloc.add(const ForceArmRace());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.armed);
      expect(bloc.state.triggerThresholdG, 4.0);

      // Send 0.8G launch (typical motorcycle launch: ~7.8 m/s²)
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 7.8,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      // Must NOT trigger because threshold is 4.0G
      expect(bloc.state.fsmState, FsmState.armed);

      // Now send >= 4.0G launch (ax >= 40.0 m/s²)
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 42.0,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      // Triggers running!
      expect(bloc.state.fsmState, FsmState.running);
    });
    test('Split Times Reset: New run or ForceArmRace resets previous split times', () async {
      bloc.add(const ForceArmRace());
      bloc.add(const UpdateTriggerThreshold(0.15));
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger launch
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.5,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.running);

      // Simulate vehicle passing 60ft (18.288m)
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291000,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 45.0,
        accuracyMeters: 1.5,
        satellitesCount: 14,
        timestamp: DateTime.now(),
      )));
      await Future.delayed(const Duration(milliseconds: 50));

      // End first run
      bloc.add(const ForceFinishAndSaveRace());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.finished);

      // Start second run by ForceArmRace
      bloc.add(const ForceArmRace());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.armed);
      // Splits MUST be null, not keeping old run's values!
      expect(bloc.state.split60ft, isNull);
      expect(bloc.state.split100m, isNull);
      expect(bloc.state.split201m, isNull);
      expect(bloc.state.split402m, isNull);
      expect(bloc.state.oneFootRolloutSec, isNull);
      expect(bloc.state.split0To100, isNull);
    });

    test('0-100 km/h is recorded when vehicle speed reaches >= 100 km/h', () async {
      bloc.add(const ForceArmRace());
      bloc.add(const UpdateTriggerThreshold(0.15));
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger launch
      for (int i = 0; i < 5; i++) {
        bloc.add(ImuDataReceived(ImuReading(
          ax: 2.5,
          ay: 0.0,
          az: 0.0,
          timestamp: DateTime.now(),
        )));
      }
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.fsmState, FsmState.running);

      final now = DateTime.now();

      // Vehicle accelerating: speed 85 km/h at t = 1s, distance ~15m
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291200,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 85.0,
        accuracyMeters: 1.5,
        satellitesCount: 14,
        timestamp: now.add(const Duration(seconds: 1)),
      )));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.split0To100, isNull);

      // Vehicle crosses 100 km/h (speed 105 km/h) at t = 2s, distance ~40m
      bloc.add(GnssDataReceived(GnssReading(
        latitude: -6.291000,
        longitude: 106.852418,
        altitude: 125.0,
        speedKmh: 105.0,
        accuracyMeters: 1.5,
        satellitesCount: 14,
        timestamp: now.add(const Duration(seconds: 2)),
      )));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.split0To100, isNotNull);
      expect(bloc.state.split0To100!, greaterThan(0.0));
    });
  });
}

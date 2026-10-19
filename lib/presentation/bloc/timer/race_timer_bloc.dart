import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/audio/audio_cue_service.dart';
import '../../../core/constants/race_constants.dart';
import '../../../core/math/geo_calculator.dart';
import '../../../core/math/linear_interpolator.dart';
import '../../../core/math/sensor_fusion_math.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../../core/services/wakelock_service.dart';
import '../../../data/datasources/gnss/gnss_datasource.dart';
import '../../../data/datasources/gnss/phone_gnss_datasource.dart';
import '../../../data/datasources/gnss/simulated_gnss_datasource.dart';
import '../../../data/datasources/imu/imu_datasource.dart';
import '../../../data/datasources/imu/phone_imu_datasource.dart';
import '../../../data/datasources/imu/simulated_imu_datasource.dart';
import '../../../domain/models/discipline_type.dart';
import '../../../domain/models/fsm_state.dart';
import '../../../domain/models/race_session.dart';
import '../../../domain/models/telemetry_point.dart';
import '../../../domain/repositories/race_session_repository.dart';
import '../../../domain/repositories/vehicle_repository.dart';
import 'race_timer_event.dart';
import 'race_timer_state.dart';

class RaceTimerBloc extends Bloc<RaceTimerEvent, RaceTimerState> {
  final RaceSessionRepository sessionRepo;
  final VehicleRepository vehicleRepo;
  final AudioCueService audioCue;

  GnssDataSource? _gnssDataSource;
  ImuDataSource? _imuDataSource;
  StreamSubscription<GnssReading>? _gnssSub;
  StreamSubscription<ImuReading>? _imuSub;
  Timer? _uiTicker;

  final Stopwatch _stopwatch = Stopwatch();
  final List<TelemetryPoint> _telemetryBuffer = [];
  final List<double> _stagingNoiseSamples = [];
  final List<double> _recentGForces = [];
  final List<double> _idleVibrationSamples = [];

  double _noiseFloorMps2 = 0.05 * 9.80665;
  double? _originLat;
  double? _originLon;
  double? _originAlt;
  double? _prevValidLat;
  double? _prevValidLon;
  double? _prevValidAlt;
  DateTime? _prevValidGpsTime;

  DateTime? _stagingStartTime;
  DateTime? _finishedStopTime;
  DateTime? _runningStopTime;
  bool _isAutoArming = false;
  bool _hasConfirmedMovement = false;

  // Stored for finish interpolation
  TelemetryPoint? _pointBeforeTarget;
  TelemetryPoint? _pointAfterTarget;

  RaceTimerBloc({
    required this.sessionRepo,
    required this.vehicleRepo,
    AudioCueService? audioCue,
  })  : audioCue = audioCue ?? AudioCueService(),
        super(const RaceTimerState()) {
    on<InitTelemetryServices>(_onInitTelemetryServices);
    on<GnssDataReceived>(_onGnssDataReceived);
    on<ImuDataReceived>(_onImuDataReceived);
    on<ChangeDiscipline>(_onChangeDiscipline);
    on<ToggleOneFootRollout>(_onToggleOneFootRollout);
    on<TogglePocketMode>(_onTogglePocketMode);
    on<SetActiveVehicle>(_onSetActiveVehicle);
    on<ForceArmRace>(_onForceArmRace);
    on<ResetRaceToIdle>(_onResetRaceToIdle);
    on<SimulateTriggerLaunchEvent>(_onSimulateTriggerLaunch);
    on<SimulateFalseStartEvent>(_onSimulateFalseStart);
    on<TimerTickEvent>(_onTimerTick);
    on<UpdateTriggerThreshold>((event, emit) {
      emit(state.copyWith(triggerThresholdG: event.thresholdG));
    });
    on<ForceFinishAndSaveRace>(_onForceFinishAndSaveRace);
  }

  Future<void> _onInitTelemetryServices(
    InitTelemetryServices event,
    Emitter<RaceTimerState> emit,
  ) async {
    await audioCue.init();
    await WakelockService.enable();

    // Load default vehicle
    final defaultVehicle = await vehicleRepo.getDefaultVehicle();

    // Load persistent user settings
    double savedThreshold = state.triggerThresholdG;
    bool savedRollout = state.oneFootRolloutEnabled;
    bool savedPocket = state.isPocketMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedThreshold = prefs.getDouble('racebox_trigger_sensitivity_g') ?? savedThreshold;
      savedRollout = prefs.getBool('racebox_one_foot_rollout') ?? savedRollout;
      savedPocket = prefs.getBool('racebox_pocket_mode') ?? savedPocket;
    } catch (_) {}

    emit(state.copyWith(
      currentVehicle: defaultVehicle,
      isSimulated: event.isSimulated,
      triggerThresholdG: savedThreshold,
      oneFootRolloutEnabled: savedRollout,
      isPocketMode: savedPocket,
    ));

    await _initDataSources(isSimulated: event.isSimulated);

    // UI Refresh Ticker (Runs smoothly via TimerTickEvent)
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (state.fsmState == FsmState.running) {
        add(const TimerTickEvent());
      }
    });
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<RaceTimerState> emit,
  ) {
    if (state.fsmState == FsmState.running) {
      final elapsed = _stopwatch.elapsedMicroseconds / 1000000.0;

      // Anti-False Trigger Check (SEC-04 State 4 & FR-03):
      // Only abort via UI ticker if 3.0 full seconds have elapsed, vehicle NEVER moved,
      // and is still completely stationary (< 2.5 km/h AND < 1.0m, e.g. accidental bump/screen tap)
      if (!_hasConfirmedMovement &&
          elapsed >= 3.0 &&
          state.currentSpeedKmh < 2.5 &&
          state.currentDistanceMeters < 1.0) {
        _stopwatch.stop();
        _stopwatch.reset();
        _hasConfirmedMovement = false;
        audioCue.playFalseStartAlert();
        _telemetryBuffer.clear();

        if (state.isPocketMode) {
          ForegroundServiceManager.updateNotification(
            title: '⚠️ Start Palsu Terdeteksi',
            text: 'Kesenggol / tidak ada laju motor. Reset ke SIAP GAS.',
          );
        }

        emit(state.copyWith(
          fsmState: FsmState.armed,
          elapsedSeconds: 0.0,
          currentSpeedKmh: 0.0,
          currentDistanceMeters: 0.0,
          peakGForce: 0.0,
          clearSplits: true,
          alertMessage: 'Start Palsu Terdeteksi (< 3 km/jam). Otomatis reset ke SIAP GAS.',
        ));
        return;
      }

      emit(state.copyWith(elapsedSeconds: elapsed));
    }
  }

  Future<void> _initDataSources({required bool isSimulated}) async {
    await _gnssSub?.cancel();
    await _imuSub?.cancel();
    _gnssDataSource?.dispose();
    _imuDataSource?.dispose();

    if (isSimulated) {
      _gnssDataSource = SimulatedGnssDataSource();
      _imuDataSource = SimulatedImuDataSource();
    } else {
      _gnssDataSource = PhoneGnssDataSource();
      _imuDataSource = PhoneImuDataSource();
    }

    await _gnssDataSource!.requestPermission();

    _gnssSub = _gnssDataSource!.stream.listen((reading) {
      add(GnssDataReceived(reading));
    });

    _imuSub = _imuDataSource!.stream.listen((reading) {
      add(ImuDataReceived(reading));
    });
  }

  void _onGnssDataReceived(
    GnssDataReceived event,
    Emitter<RaceTimerState> emit,
  ) {
    final g = event.reading;

    // Filter GPS multipath glitch (SEC-14)
    if (_prevValidLat != null && _prevValidLon != null && _prevValidGpsTime != null) {
      final deltaSec = g.timestamp.difference(_prevValidGpsTime!).inMilliseconds / 1000.0;
      if (deltaSec > 0.0) {
        final isValid = GeoCalculator.isValidGpsReading(
          prevLat: _prevValidLat!,
          prevLon: _prevValidLon!,
          newLat: g.latitude,
          newLon: g.longitude,
          deltaSeconds: deltaSec,
        );
        if (!isValid) return; // Drop multipath outlier
      }
    }
    _prevValidLat = g.latitude;
    _prevValidLon = g.longitude;
    _prevValidAlt = g.altitude;
    _prevValidGpsTime = g.timestamp;

    // Update GPS indicators
    double speed = g.speedKmh;
    double accuracy = g.accuracyMeters;
    int satellites = g.satellitesCount;

    // FSM State Logic
    switch (state.fsmState) {
      case FsmState.idleGpsLock:
        emit(state.copyWith(
          currentSpeedKmh: speed,
          gpsAccuracyMeters: accuracy,
          gpsSatellites: satellites,
        ));

        // GPS Lock condition (FR-01: Satellites >= 8, Accuracy <= 2.5m)
        if (accuracy <= RaceConstants.maxGpsAccuracyForStaging &&
            satellites >= RaceConstants.minSatellitesForStaging) {
          if (speed <= 0.8) {
            _stagingStartTime = DateTime.now();
            _stagingNoiseSamples.clear();
            emit(state.copyWith(fsmState: FsmState.staging));
          }
        }
        break;

      case FsmState.staging:
        emit(state.copyWith(
          currentSpeedKmh: speed,
          gpsAccuracyMeters: accuracy,
          gpsSatellites: satellites,
        ));

        if (speed > 1.2) {
          // Motor moved, reset staging calibration timer
          _stagingStartTime = DateTime.now();
          _stagingNoiseSamples.clear();
        } else if (_stagingStartTime != null) {
          final elapsedStagingMs = DateTime.now().difference(_stagingStartTime!).inMilliseconds;
          if (elapsedStagingMs >= RaceConstants.stagingCalibrationDurationMs) {
            // Calibrate noise floor
            _noiseFloorMps2 = SensorFusionMath.computeNoiseFloor(_stagingNoiseSamples);

            // Lock origin
            _originLat = g.latitude;
            _originLon = g.longitude;
            _originAlt = g.altitude;

            // Trigger ARMED beep
            audioCue.playArmedBeep();

            if (state.isPocketMode) {
              ForegroundServiceManager.updateNotification(
                title: '🎯 SIAP GAS (ARMED) - RaceBox',
                text: 'Titik start terkunci. Bejek gas kapan saja!',
              );
            }

            // Prepare stopwatch
            _stopwatch.reset();
            _telemetryBuffer.clear();
            _recentGForces.clear();

            emit(state.copyWith(
              fsmState: FsmState.armed,
              elapsedSeconds: 0.0,
              currentDistanceMeters: 0.0,
              currentSpeedKmh: 0.0,
              peakGForce: 0.0,
              clearSplits: true,
              alertMessage: null,
            ));
          }
        }
        break;

      case FsmState.armed:
        if (_originLat == null) {
          _originLat = g.latitude;
          _originLon = g.longitude;
          _originAlt = g.altitude;
        }

        emit(state.copyWith(
          currentSpeedKmh: speed,
          gpsAccuracyMeters: accuracy,
          gpsSatellites: satellites,
        ));

        // GPS fallback trigger: only if real physical vehicle movement is confirmed
        // (speed >= 4.0 km/h AND moved at least 1.5m from start line)
        if (_originLat != null && _originLon != null) {
          final distFromOrigin = GeoCalculator.haversineDistanceMeters(
            lat1: _originLat!,
            lon1: _originLon!,
            lat2: g.latitude,
            lon2: g.longitude,
          );
          if (speed >= 4.0 && distFromOrigin >= 1.5) {
            _triggerLaunch(emit, movementConfirmed: true);
          }
        }
        break;

      case FsmState.running:
        final elapsedMs = _stopwatch.elapsedMilliseconds;
        final elapsedSec = elapsedMs / 1000.0;

        // Ensure origin is locked to the vehicle start line
        if (_originLat == null || _originLon == null) {
          _originLat = g.latitude;
          _originLon = g.longitude;
          _originAlt = g.altitude;
        }

        // Distance from locked origin
        double distanceMeters = 0.0;
        if (_originLat != null && _originLon != null) {
          distanceMeters = GeoCalculator.haversineDistanceMeters(
            lat1: _originLat!,
            lon1: _originLon!,
            lat2: g.latitude,
            lon2: g.longitude,
          );
        }

        // If vehicle has achieved speed >= 3.0 km/h or moved >= 1.2m, movement is confirmed!
        if (speed >= 3.0 || distanceMeters >= 1.2) {
          _hasConfirmedMovement = true;
        }

        // Anti-False Trigger Check (SEC-04 State 4 & FR-03):
        // Only trigger false start if vehicle NEVER moved, is still within 1.2m start box,
        // within the initial start check window (1.5s - 3.5s), and GPS speed is < 3.0 km/h
        if (!_hasConfirmedMovement &&
            distanceMeters < 1.2 &&
            elapsedMs >= RaceConstants.falseStartWindowMs &&
            elapsedMs <= 3500 &&
            speed < RaceConstants.falseStartMinSpeedKmh) {
          _stopwatch.stop();
          _stopwatch.reset();
          _hasConfirmedMovement = false;
          audioCue.playFalseStartAlert();
          _telemetryBuffer.clear();

          if (state.isPocketMode) {
            ForegroundServiceManager.updateNotification(
              title: '⚠️ Start Palsu Terdeteksi',
              text: 'Kecepatan < 3 km/jam. Otomatis reset ke SIAP GAS.',
            );
          }

          emit(state.copyWith(
            fsmState: FsmState.armed,
            elapsedSeconds: 0.0,
            currentSpeedKmh: 0.0,
            currentDistanceMeters: 0.0,
            peakGForce: 0.0,
            clearSplits: true,
            alertMessage: 'Start Palsu Terdeteksi (< 3 km/jam). Otomatis reset ke SIAP GAS.',
          ));
          return;
        }

        // Track 1-Foot Rollout point (FR-04: 0.3048m, requires real vehicle speed >= 1.5 km/h)
        double? rolloutSec = state.oneFootRolloutSec;
        if (rolloutSec == null && distanceMeters >= RaceConstants.oneFootRolloutMeters && speed >= 1.5) {
          if (_telemetryBuffer.isNotEmpty && distanceMeters > _telemetryBuffer.last.distanceMeters) {
            final prev = _telemetryBuffer.last;
            rolloutSec = LinearInterpolator.interpolateFinishTime(
              t1: prev.elapsedMs / 1000.0,
              d1: prev.distanceMeters,
              t2: elapsedSec,
              d2: distanceMeters,
              dTarget: RaceConstants.oneFootRolloutMeters,
            );
          } else {
            rolloutSec = elapsedSec;
          }
        }

        // Track Splits (FR-05)
        double? s60ft = state.split60ft;
        double? s100m = state.split100m;
        double? s201m = state.split201m;
        double? s402m = state.split402m;
        double? s0To100 = state.split0To100;

        if (s60ft == null && distanceMeters >= RaceConstants.distance60ftMeters) {
          if (_telemetryBuffer.isNotEmpty && distanceMeters > _telemetryBuffer.last.distanceMeters) {
            final prev = _telemetryBuffer.last;
            s60ft = LinearInterpolator.interpolateFinishTime(
              t1: prev.elapsedMs / 1000.0,
              d1: prev.distanceMeters,
              t2: elapsedSec,
              d2: distanceMeters,
              dTarget: RaceConstants.distance60ftMeters,
            );
          } else {
            s60ft = elapsedSec;
          }
        }
        if (s100m == null && distanceMeters >= RaceConstants.distance100mMeters) {
          if (_telemetryBuffer.isNotEmpty && distanceMeters > _telemetryBuffer.last.distanceMeters) {
            final prev = _telemetryBuffer.last;
            s100m = LinearInterpolator.interpolateFinishTime(
              t1: prev.elapsedMs / 1000.0,
              d1: prev.distanceMeters,
              t2: elapsedSec,
              d2: distanceMeters,
              dTarget: RaceConstants.distance100mMeters,
            );
          } else {
            s100m = elapsedSec;
          }
        }
        if (s201m == null && distanceMeters >= RaceConstants.distance201mMeters) {
          if (_telemetryBuffer.isNotEmpty && distanceMeters > _telemetryBuffer.last.distanceMeters) {
            final prev = _telemetryBuffer.last;
            s201m = LinearInterpolator.interpolateFinishTime(
              t1: prev.elapsedMs / 1000.0,
              d1: prev.distanceMeters,
              t2: elapsedSec,
              d2: distanceMeters,
              dTarget: RaceConstants.distance201mMeters,
            );
          } else {
            s201m = elapsedSec;
          }
        }
        if (s402m == null && distanceMeters >= RaceConstants.distance402mMeters) {
          if (_telemetryBuffer.isNotEmpty && distanceMeters > _telemetryBuffer.last.distanceMeters) {
            final prev = _telemetryBuffer.last;
            s402m = LinearInterpolator.interpolateFinishTime(
              t1: prev.elapsedMs / 1000.0,
              d1: prev.distanceMeters,
              t2: elapsedSec,
              d2: distanceMeters,
              dTarget: RaceConstants.distance402mMeters,
            );
          } else {
            s402m = elapsedSec;
          }
        }
        if (s0To100 == null && speed >= 100.0) {
          if (_telemetryBuffer.isNotEmpty) {
            final prev = _telemetryBuffer.last;
            final v1 = prev.speedKmh;
            final t1 = prev.elapsedMs / 1000.0;
            final v2 = speed;
            final t2 = elapsedSec;
            if (v2 > v1 && v1 < 100.0) {
              s0To100 = t1 + ((100.0 - v1) / (v2 - v1)) * (t2 - t1);
            } else {
              s0To100 = elapsedSec;
            }
          } else {
            s0To100 = elapsedSec;
          }
        }

        // Create sample
        final sample = TelemetryPoint(
          sessionId: '',
          elapsedMs: elapsedMs,
          speedKmh: speed,
          distanceMeters: distanceMeters,
          linearAccelG: state.currentGForce,
          latitude: g.latitude,
          longitude: g.longitude,
          altitude: g.altitude,
          timestamp: g.timestamp,
        );

        // Keep last points for finish line interpolation
        final targetDist = state.discipline.targetDistanceMeters;
        if (targetDist != null) {
          if (distanceMeters < targetDist) {
            _pointBeforeTarget = sample;
          } else {
            _pointAfterTarget ??= sample;
          }
        }

        _telemetryBuffer.add(sample);

        emit(state.copyWith(
          currentSpeedKmh: speed,
          currentDistanceMeters: distanceMeters,
          elapsedSeconds: elapsedSec,
          gpsAccuracyMeters: accuracy,
          gpsSatellites: satellites,
          oneFootRolloutSec: rolloutSec,
          split60ft: s60ft,
          split100m: s100m,
          split201m: s201m,
          split402m: s402m,
          split0To100: s0To100,
        ));

        // Check Target Completion
        _checkTargetFinished(emit, distanceMeters, speed, elapsedSec, g.altitude);

        // Auto-finalize if vehicle stops completely (<= 0.8 km/h) for >= 3.5 seconds
        // after having started and traveled at least 15 meters (e.g. aborting run or stopping after 60ft/100m)
        if (state.fsmState == FsmState.running && speed <= 0.8 && distanceMeters >= 15.0 && elapsedSec >= 1.5) {
          _runningStopTime ??= DateTime.now();
          if (DateTime.now().difference(_runningStopTime!).inMilliseconds >= 3500) {
            _runningStopTime = null;
            add(const ForceFinishAndSaveRace());
          }
        } else {
          _runningStopTime = null;
        }
        break;

      case FsmState.finished:
        emit(state.copyWith(
          currentSpeedKmh: speed,
          gpsAccuracyMeters: accuracy,
          gpsSatellites: satellites,
        ));

        // Auto-Arm Loop (SEC-04 State 5 & FR-09):
        // When vehicle stops (0 km/h) for 3.0 seconds, auto-reset to STAGING/ARMED
        if (speed <= 0.8) {
          _finishedStopTime ??= DateTime.now();
          final stoppedDurationMs = DateTime.now().difference(_finishedStopTime!).inMilliseconds;
          if (stoppedDurationMs >= RaceConstants.autoArmStopDurationMs && !_isAutoArming) {
            _isAutoArming = true;
            _finishedStopTime = null;
            _stagingStartTime = DateTime.now();
            _stagingNoiseSamples.clear();
            emit(state.copyWith(
              fsmState: FsmState.staging,
              elapsedSeconds: 0.0,
              currentDistanceMeters: 0.0,
              clearSplits: true,
              alertMessage: 'Auto-Arm: Motor berhenti 3 detik. Menyiapkan tarikan berikutnya...',
            ));
            _isAutoArming = false;
          }
        } else {
          _finishedStopTime = null;
        }
        break;
    }
  }

  void _onImuDataReceived(
    ImuDataReceived event,
    Emitter<RaceTimerState> emit,
  ) {
    final imu = event.reading;
    final magnitude = imu.magnitude;
    // Filter vehicle propulsion G-force:
    // Physical forward acceleration on a motorcycle rarely exceeds 2.0G.
    // Road bumps / pothole vibrations can produce 5G - 15G momentary mechanical shocks.
    final vehicleG = imu.gForce.clamp(0.0, 2.5);

    // Peak G-Force tracking
    final peakG = vehicleG > state.peakGForce ? vehicleG : state.peakGForce;

    // Track baseline engine idle vibration while stationary in IDLE or STAGING
    if (state.fsmState == FsmState.staging || state.fsmState == FsmState.idleGpsLock) {
      if (magnitude < 3.5) { // < 3.5 m/s² (~0.35G) is idle engine vibration, not a launch spike
        _idleVibrationSamples.add(magnitude);
        if (_idleVibrationSamples.length > 50) {
          _idleVibrationSamples.removeAt(0);
        }
        if (_idleVibrationSamples.length >= 5) {
          final peakIdle = _idleVibrationSamples.reduce(max);
          _noiseFloorMps2 = peakIdle.clamp(0.05 * 9.80665, 0.40 * 9.80665);
        }
      }
    }

    // In STAGING: record engine idle vibration
    if (state.fsmState == FsmState.staging) {
      _stagingNoiseSamples.add(magnitude);
      emit(state.copyWith(currentGForce: vehicleG, peakGForce: peakG));
      return;
    }

    // In ARMED: check for launch trigger
    if (state.fsmState == FsmState.armed) {
      final netAccel = SensorFusionMath.calculateNetAcceleration(
        ax: imu.ax,
        ay: imu.ay,
        az: imu.az,
        noiseFloorMps2: _noiseFloorMps2,
      );
      final netGForce = SensorFusionMath.toGForce(netAccel);
      _recentGForces.add(netGForce);
      if (_recentGForces.length > 10) _recentGForces.removeAt(0);

      final triggered = SensorFusionMath.isLaunchTriggered(
        recentGForces: _recentGForces,
        thresholdG: state.triggerThresholdG,
        requiredConsecutiveSamples: 4, // 40ms @ 100Hz
      );

      if (triggered) {
        _triggerLaunch(emit);
      } else {
        emit(state.copyWith(currentGForce: vehicleG, peakGForce: peakG));
      }
      return;
    }

    emit(state.copyWith(currentGForce: vehicleG, peakGForce: peakG));
  }

  void _triggerLaunch(Emitter<RaceTimerState> emit, {bool movementConfirmed = false}) {
    if (_prevValidLat != null && _prevValidLon != null) {
      _originLat = _prevValidLat;
      _originLon = _prevValidLon;
      _originAlt = _prevValidAlt;
    }
    _hasConfirmedMovement = movementConfirmed;
    _stopwatch.reset();
    _stopwatch.start();
    _telemetryBuffer.clear();
    _pointBeforeTarget = null;
    _pointAfterTarget = null;

    // Anchor initial launch point at t=0 so telemetry curves start cleanly from origin
    _telemetryBuffer.add(TelemetryPoint(
      sessionId: '',
      elapsedMs: 0,
      speedKmh: 0.0,
      distanceMeters: 0.0,
      linearAccelG: state.currentGForce,
      latitude: _originLat ?? 0.0,
      longitude: _originLon ?? 0.0,
      altitude: _originAlt ?? 0.0,
      timestamp: DateTime.now(),
    ));

    emit(state.copyWith(
      fsmState: FsmState.running,
      elapsedSeconds: 0.0,
      currentDistanceMeters: 0.0,
      peakGForce: 0.0,
      clearSplits: true,
      alertMessage: null,
    ));

    if (state.isPocketMode) {
      ForegroundServiceManager.updateNotification(
        title: 'RaceBox TARIKAN GAS',
        text: 'Gas terbuka! Waktu sedang berjalan...',
      );
    }
  }

  void _checkTargetFinished(
    Emitter<RaceTimerState> emit,
    double distanceMeters,
    double currentSpeed,
    double rawElapsedSec,
    double currentAltitude,
  ) {
    bool isFinished = false;
    double interpolatedTimeSec = rawElapsedSec;
    double interpolatedTrapSpeed = currentSpeed;

    final targetDist = state.discipline.targetDistanceMeters;
    final targetSpeed = state.discipline.targetSpeedKmh;

    if (targetDist != null && distanceMeters >= targetDist) {
      isFinished = true;

      // Linear Interpolation calculation (SEC-05 & SEC-11 Scenario 4)
      if (_pointBeforeTarget != null && _pointAfterTarget != null) {
        final t1 = _pointBeforeTarget!.elapsedMs / 1000.0;
        final d1 = _pointBeforeTarget!.distanceMeters;
        final t2 = _pointAfterTarget!.elapsedMs / 1000.0;
        final d2 = _pointAfterTarget!.distanceMeters;

        interpolatedTimeSec = LinearInterpolator.interpolateFinishTime(
          t1: t1,
          d1: d1,
          t2: t2,
          d2: d2,
          dTarget: targetDist,
        );

        interpolatedTrapSpeed = LinearInterpolator.interpolateTrapSpeed(
          v1: _pointBeforeTarget!.speedKmh,
          d1: d1,
          v2: _pointAfterTarget!.speedKmh,
          d2: d2,
          dTarget: targetDist,
        );
      }
    } else if (targetSpeed != null && currentSpeed >= targetSpeed) {
      isFinished = true;
      interpolatedTimeSec = state.split0To100 ?? rawElapsedSec;
      interpolatedTrapSpeed = currentSpeed;
    }

    if (isFinished) {
      _stopwatch.stop();
      _hasConfirmedMovement = false;

      // 1-Foot Rollout calculation (FR-04)
      double finalDisplayTime = interpolatedTimeSec;
      if (state.oneFootRolloutEnabled && state.oneFootRolloutSec != null) {
        finalDisplayTime = LinearInterpolator.applyOneFootRollout(
          rawFinishTimeSec: interpolatedTimeSec,
          rolloutTimeSec: state.oneFootRolloutSec!,
        );
      }

      // Track Slope calculation (SEC-05)
      final altStart = _originAlt ?? (_telemetryBuffer.isNotEmpty ? _telemetryBuffer.first.altitude : currentAltitude);
      final altFinish = currentAltitude;
      final runDistance = targetDist ?? distanceMeters;
      final slopePercent = LinearInterpolator.calculateSlopePercent(
        altitudeStart: altStart,
        altitudeFinish: altFinish,
        distanceMeters: runDistance,
      );
      final isValidSlope = LinearInterpolator.isValidSlope(slopePercent);

      // Play 2x Finish Beep
      audioCue.playFinishedBeep();

      // Persist to Database
      final sessionId = const Uuid().v4();
      final sessionSamples = _telemetryBuffer.map((s) {
        return TelemetryPoint(
          sessionId: sessionId,
          elapsedMs: s.elapsedMs,
          speedKmh: s.speedKmh,
          distanceMeters: s.distanceMeters,
          linearAccelG: s.linearAccelG,
          latitude: s.latitude,
          longitude: s.longitude,
          altitude: s.altitude,
          timestamp: s.timestamp,
        );
      }).toList();

      final session = RaceSession(
        sessionId: sessionId,
        vehicleId: state.currentVehicle?.id,
        vehicleName: state.currentVehicle?.vehicleName ?? 'Default Bike',
        disciplineType: state.discipline,
        createdAt: DateTime.now(),
        finalTimeSec: double.parse(finalDisplayTime.toStringAsFixed(2)),
        trapSpeedKmh: double.parse(interpolatedTrapSpeed.toStringAsFixed(2)),
        peakGForce: double.parse(state.peakGForce.toStringAsFixed(2)),
        slopePercent: double.parse(slopePercent.toStringAsFixed(2)),
        isValidSlope: isValidSlope,
        split60ftSec: state.split60ft != null ? double.parse(state.split60ft!.toStringAsFixed(2)) : null,
        split100mSec: state.split100m != null ? double.parse(state.split100m!.toStringAsFixed(2)) : null,
        split201mSec: state.split201m != null ? double.parse(state.split201m!.toStringAsFixed(2)) : null,
        split402mSec: state.split402m != null ? double.parse(state.split402m!.toStringAsFixed(2)) : null,
        split0To100Sec: state.split0To100 != null ? double.parse(state.split0To100!.toStringAsFixed(2)) : null,
        oneFootRolloutSec: state.oneFootRolloutSec,
        isRolloutApplied: state.oneFootRolloutEnabled,
        telemetrySamples: sessionSamples,
      );

      sessionRepo.saveRaceSession(session);

      emit(state.copyWith(
        fsmState: FsmState.finished,
        elapsedSeconds: finalDisplayTime,
        slopePercent: slopePercent,
        isValidSlope: isValidSlope,
        lastFinishedSession: session,
        alertMessage: 'FINIS! Waktu: ${finalDisplayTime.toStringAsFixed(2)}s | Kecepatan Finis: ${interpolatedTrapSpeed.toStringAsFixed(1)} km/j',
      ));

      if (state.isPocketMode) {
        ForegroundServiceManager.updateNotification(
          title: 'Tarikan Finis!',
          text: '${finalDisplayTime.toStringAsFixed(2)}s @ ${interpolatedTrapSpeed.toStringAsFixed(1)} km/j',
        );
      }
    }
  }

  void _onChangeDiscipline(
    ChangeDiscipline event,
    Emitter<RaceTimerState> emit,
  ) {
    emit(state.copyWith(discipline: event.discipline));
  }

  void _onToggleOneFootRollout(
    ToggleOneFootRollout event,
    Emitter<RaceTimerState> emit,
  ) {
    emit(state.copyWith(oneFootRolloutEnabled: event.enabled));
  }

  Future<void> _onTogglePocketMode(
    TogglePocketMode event,
    Emitter<RaceTimerState> emit,
  ) async {
    if (event.enabled) {
      await ForegroundServiceManager.init();
      await ForegroundServiceManager.startService();
    } else {
      await ForegroundServiceManager.stopService();
    }
    emit(state.copyWith(isPocketMode: event.enabled));
  }

  void _onSetActiveVehicle(
    SetActiveVehicle event,
    Emitter<RaceTimerState> emit,
  ) {
    emit(state.copyWith(currentVehicle: event.vehicle));
  }

  void _onForceArmRace(
    ForceArmRace event,
    Emitter<RaceTimerState> emit,
  ) {
    if (_prevValidLat != null && _prevValidLon != null) {
      _originLat = _prevValidLat;
      _originLon = _prevValidLon;
      _originAlt = _prevValidAlt;
    } else if (state.isSimulated) {
      _originLat = -6.291245;
      _originLon = 106.852418;
      _originAlt = 125.0;
    } else {
      _originLat = null;
      _originLon = null;
      _originAlt = null;
    }
    _stopwatch.reset();
    _hasConfirmedMovement = false;
    _telemetryBuffer.clear();
    _recentGForces.clear();
    audioCue.playArmedBeep();

    // Adapt noise floor immediately from recent idle vibration
    if (_idleVibrationSamples.isNotEmpty) {
      final peakIdle = _idleVibrationSamples.reduce(max);
      _noiseFloorMps2 = peakIdle.clamp(0.05 * 9.80665, 0.40 * 9.80665);
    } else {
      _noiseFloorMps2 = 0.05 * 9.80665;
    }

    emit(state.copyWith(
      fsmState: FsmState.armed,
      elapsedSeconds: 0.0,
      currentDistanceMeters: 0.0,
      currentSpeedKmh: 0.0,
      peakGForce: 0.0,
      clearSplits: true,
      alertMessage: 'Timer disiapkan manual. Siap bejek gas!',
    ));
  }

  void _onResetRaceToIdle(
    ResetRaceToIdle event,
    Emitter<RaceTimerState> emit,
  ) {
    _stopwatch.stop();
    _stopwatch.reset();
    _hasConfirmedMovement = false;
    _telemetryBuffer.clear();
    _pointBeforeTarget = null;
    _pointAfterTarget = null;
    _finishedStopTime = null;
    _runningStopTime = null;
    _isAutoArming = false;
    if (_gnssDataSource is SimulatedGnssDataSource) {
      (_gnssDataSource as SimulatedGnssDataSource).resetPosition();
    }
    emit(state.copyWith(
      fsmState: FsmState.idleGpsLock,
      elapsedSeconds: 0.0,
      currentDistanceMeters: 0.0,
      currentSpeedKmh: 0.0,
      peakGForce: 0.0,
      clearSplits: true,
      clearLastSession: true,
      alertMessage: 'Sesi di-reset ke IDLE. Menunggu sinyal GPS...',
    ));
  }

  void _onSimulateTriggerLaunch(
    SimulateTriggerLaunchEvent event,
    Emitter<RaceTimerState> emit,
  ) {
    if (_gnssDataSource is SimulatedGnssDataSource && _imuDataSource is SimulatedImuDataSource) {
      (_imuDataSource as SimulatedImuDataSource).simulateLaunchSpike();
      (_gnssDataSource as SimulatedGnssDataSource).simulateLaunch();
    }
  }

  void _onSimulateFalseStart(
    SimulateFalseStartEvent event,
    Emitter<RaceTimerState> emit,
  ) {
    if (_gnssDataSource is SimulatedGnssDataSource && _imuDataSource is SimulatedImuDataSource) {
      (_imuDataSource as SimulatedImuDataSource).simulateEngineRev();
      (_gnssDataSource as SimulatedGnssDataSource).simulateFalseStart();
    }
  }

  void _onForceFinishAndSaveRace(
    ForceFinishAndSaveRace event,
    Emitter<RaceTimerState> emit,
  ) {
    if (state.fsmState != FsmState.running) return;
    _stopwatch.stop();
    _hasConfirmedMovement = false;

    final elapsedSec = state.elapsedSeconds;
    final trapSpeed = state.currentSpeedKmh;
    final distanceMeters = state.currentDistanceMeters;
    final altStart = _originAlt ?? (_telemetryBuffer.isNotEmpty ? _telemetryBuffer.first.altitude : 0.0);
    final altFinish = _telemetryBuffer.isNotEmpty ? _telemetryBuffer.last.altitude : altStart;

    final slopePercent = LinearInterpolator.calculateSlopePercent(
      altitudeStart: altStart,
      altitudeFinish: altFinish,
      distanceMeters: distanceMeters > 0 ? distanceMeters : 1.0,
    );
    final isValidSlope = LinearInterpolator.isValidSlope(slopePercent);

    audioCue.playFinishedBeep();

    final sessionId = const Uuid().v4();
    final sessionSamples = _telemetryBuffer.map((s) {
      return TelemetryPoint(
        sessionId: sessionId,
        elapsedMs: s.elapsedMs,
        speedKmh: s.speedKmh,
        distanceMeters: s.distanceMeters,
        linearAccelG: s.linearAccelG,
        latitude: s.latitude,
        longitude: s.longitude,
        altitude: s.altitude,
        timestamp: s.timestamp,
      );
    }).toList();

    // Use the furthest split achieved, or 0-100 for sprint discipline, or current elapsed time
    final finalDisplayTime = state.discipline == DisciplineType.sprint0To100
        ? (state.split0To100 ?? elapsedSec)
        : (state.split402m ??
            state.split201m ??
            state.split100m ??
            state.split60ft ??
            elapsedSec);

    final session = RaceSession(
      sessionId: sessionId,
      vehicleId: state.currentVehicle?.id,
      vehicleName: state.currentVehicle?.vehicleName ?? 'Default Bike',
      disciplineType: state.discipline,
      createdAt: DateTime.now(),
      finalTimeSec: double.parse(finalDisplayTime.toStringAsFixed(2)),
      trapSpeedKmh: double.parse(trapSpeed.toStringAsFixed(2)),
      peakGForce: double.parse(state.peakGForce.toStringAsFixed(2)),
      slopePercent: double.parse(slopePercent.toStringAsFixed(2)),
      isValidSlope: isValidSlope,
      split60ftSec: state.split60ft != null ? double.parse(state.split60ft!.toStringAsFixed(2)) : null,
      split100mSec: state.split100m != null ? double.parse(state.split100m!.toStringAsFixed(2)) : null,
      split201mSec: state.split201m != null ? double.parse(state.split201m!.toStringAsFixed(2)) : null,
      split402mSec: state.split402m != null ? double.parse(state.split402m!.toStringAsFixed(2)) : null,
      split0To100Sec: state.split0To100 != null ? double.parse(state.split0To100!.toStringAsFixed(2)) : null,
      oneFootRolloutSec: state.oneFootRolloutSec,
      isRolloutApplied: state.oneFootRolloutEnabled,
      telemetrySamples: sessionSamples,
    );

    sessionRepo.saveRaceSession(session);

    emit(state.copyWith(
      fsmState: FsmState.finished,
      elapsedSeconds: finalDisplayTime,
      slopePercent: slopePercent,
      isValidSlope: isValidSlope,
      lastFinishedSession: session,
      alertMessage: 'FINIS! Waktu: ${finalDisplayTime.toStringAsFixed(2)}s | Kecepatan: ${trapSpeed.toStringAsFixed(1)} km/j',
    ));

    if (state.isPocketMode) {
      ForegroundServiceManager.updateNotification(
        title: 'Tarikan Finis Disimpan!',
        text: '${finalDisplayTime.toStringAsFixed(2)}s @ ${trapSpeed.toStringAsFixed(1)} km/j',
      );
    }
  }

  @override
  Future<void> close() async {
    _uiTicker?.cancel();
    await _gnssSub?.cancel();
    await _imuSub?.cancel();
    _gnssDataSource?.dispose();
    _imuDataSource?.dispose();
    audioCue.dispose();
    await WakelockService.disable();
    return super.close();
  }
}

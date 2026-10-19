/// Finite State Machine (FSM) States according to FRD SEC-04
enum FsmState {
  /// State 1: IDLE / GPS LOCK
  /// System validates satellites count (≥8) and horizontal accuracy (≤2.5m).
  /// Staging is blocked until GPS accuracy meets standards.
  idleGpsLock,

  /// State 2: STAGING
  /// Vehicle is completely stopped (0 km/h) for 2.0s.
  /// System calibrates idle engine vibration noise floor.
  staging,

  /// State 3: ARMED (Ready to Gas)
  /// Origin coordinates locked, timer at 00.00, 1x long beep sounded.
  /// Actively monitoring IMU 100Hz stream for launch spike (>= 0.15G).
  armed,

  /// State 4: RUNNING (Active Acquisition)
  /// Launched. Stopwatch running.
  /// System monitors for false start within 1.5s (must reach ≥ 3 km/h).
  running,

  /// State 5: FINISHED & AUTO-ARM
  /// Target distance/speed crossed. Exact time calculated via linear interpolation.
  /// 2x Beep sounded, session saved to SQLite.
  /// When rider stops (0 km/h for 3s), automatically resets to STAGING/ARMED for next pull.
  finished,
}

extension FsmStateExtension on FsmState {
  String get displayName {
    switch (this) {
      case FsmState.idleGpsLock:
        return 'KUNCI GPS';
      case FsmState.staging:
        return 'STAGING (SIAGA)';
      case FsmState.armed:
        return 'SIAP GAS (ARMED)';
      case FsmState.running:
        return 'TARIKAN GAS';
      case FsmState.finished:
        return 'FINIS';
    }
  }

  String get guidanceText {
    switch (this) {
      case FsmState.idleGpsLock:
        return 'Menunggu sinyal GPS presisi (≤ 2.5m)...';
      case FsmState.staging:
        return 'Tahan motor berhenti (2 dtk) — Kalibrasi getaran mesin...';
      case FsmState.armed:
        return 'SIAP! Putar gas saat siap meluncur.';
      case FsmState.running:
        return 'TARIKAN BERJALAN — GAS SAMPAI FINIS!';
      case FsmState.finished:
        return 'FINIS! Berhenti 3 detik untuk Auto-Arm tarikan berikutnya.';
    }
  }
}

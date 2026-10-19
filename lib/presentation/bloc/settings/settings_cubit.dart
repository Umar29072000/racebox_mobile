import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  final bool soundEnabled;
  final bool simulationMode;
  final bool pocketModeEnabled;
  final bool oneFootRolloutEnabled;
  final double triggerSensitivityG;

  const SettingsState({
    this.soundEnabled = true,
    this.simulationMode = false,
    this.pocketModeEnabled = false,
    this.oneFootRolloutEnabled = false,
    this.triggerSensitivityG = 4.0,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? simulationMode,
    bool? pocketModeEnabled,
    bool? oneFootRolloutEnabled,
    double? triggerSensitivityG,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      simulationMode: simulationMode ?? this.simulationMode,
      pocketModeEnabled: pocketModeEnabled ?? this.pocketModeEnabled,
      oneFootRolloutEnabled: oneFootRolloutEnabled ?? this.oneFootRolloutEnabled,
      triggerSensitivityG: triggerSensitivityG ?? this.triggerSensitivityG,
    );
  }

  @override
  List<Object?> get props => [
        soundEnabled,
        simulationMode,
        pocketModeEnabled,
        oneFootRolloutEnabled,
        triggerSensitivityG,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  static const _keySound = 'racebox_sound_enabled';
  static const _keySimulation = 'racebox_simulation_mode';
  static const _keyPocket = 'racebox_pocket_mode';
  static const _keyRollout = 'racebox_one_foot_rollout';
  static const _keySensitivity = 'racebox_trigger_sensitivity_g';

  SettingsCubit() : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sound = prefs.getBool(_keySound) ?? true;
      final simulation = prefs.getBool(_keySimulation) ?? false;
      final pocket = prefs.getBool(_keyPocket) ?? false;
      final rollout = prefs.getBool(_keyRollout) ?? false;
      final sensitivity = prefs.getDouble(_keySensitivity) ?? 4.0;

      emit(state.copyWith(
        soundEnabled: sound,
        simulationMode: simulation,
        pocketModeEnabled: pocket,
        oneFootRolloutEnabled: rollout,
        triggerSensitivityG: sensitivity,
      ));
    } catch (_) {}
  }

  Future<void> toggleSound(bool enabled) async {
    emit(state.copyWith(soundEnabled: enabled));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, enabled);
    } catch (_) {}
  }

  Future<void> toggleSimulation(bool enabled) async {
    emit(state.copyWith(simulationMode: enabled));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySimulation, enabled);
    } catch (_) {}
  }

  Future<void> togglePocketMode(bool enabled) async {
    emit(state.copyWith(pocketModeEnabled: enabled));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPocket, enabled);
    } catch (_) {}
  }

  Future<void> toggleOneFootRollout(bool enabled) async {
    emit(state.copyWith(oneFootRolloutEnabled: enabled));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRollout, enabled);
    } catch (_) {}
  }

  Future<void> setTriggerSensitivity(double val) async {
    emit(state.copyWith(triggerSensitivityG: val));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySensitivity, val);
    } catch (_) {}
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/audio/audio_cue_service.dart';
import '../../core/constants/app_colors.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/timer/race_timer_bloc.dart';
import '../bloc/timer/race_timer_event.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'PENGATURAN & PREFERENSI',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader('ATURAN & PENCATATAN WAKTU'),
              _buildSwitchTile(
                title: '1-Foot Rollout',
                subtitle: 'Memotong catatan waktu 30.48 cm (1 kaki) pertama agar hasil pengukuran setara dengan sensor photocell sirkuit drag resmi.',
                value: state.oneFootRolloutEnabled,
                activeColor: AppColors.yellow,
                onChanged: (val) {
                  context.read<SettingsCubit>().toggleOneFootRollout(val);
                  context.read<RaceTimerBloc>().add(ToggleOneFootRollout(val));
                },
              ),

              const SizedBox(height: 16.0),
              _buildSectionHeader('MODE OPERASIONAL'),
              _buildSwitchTile(
                title: 'Mode Saku / Latar Belakang',
                subtitle: 'Menjalankan notifikasi mengambang (Foreground Service) terus aktif. GPS dan sensor akselerasi tetap membaca tarikan saat HP berada di dalam saku jaket dengan layar mati.',
                value: state.pocketModeEnabled,
                activeColor: AppColors.cyan,
                onChanged: (val) {
                  context.read<SettingsCubit>().togglePocketMode(val);
                  context.read<RaceTimerBloc>().add(TogglePocketMode(val));
                },
              ),
              _buildSensitivityCard(context, state),
              _buildSwitchTile(
                title: 'Isyarat Suara Beep (TWS / Speaker)',
                subtitle: '1x Beep Panjang saat SIAP (ARMED), 2x Beep Cepat saat FINIS, Suara Peringatan saat FALSE START.',
                value: state.soundEnabled,
                activeColor: AppColors.green,
                onChanged: (val) async {
                  context.read<SettingsCubit>().toggleSound(val);
                  AudioCueService().soundEnabled = val;
                  if (val) {
                    await AudioCueService().playArmedBeep();
                  }
                },
                extraAction: state.soundEnabled
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await AudioCueService().playArmedBeep();
                          },
                          icon: const Icon(Icons.volume_up, size: 14.0, color: AppColors.green),
                          label: const Text(
                            'UJI BUNYI BEEP',
                            style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11.0),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.green),
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 16.0),
              _buildSectionHeader('PENGEMBANGAN & PENGUJIAN'),
              _buildSwitchTile(
                title: 'Mode Simulator Sensor',
                subtitle: 'Mensimulasikan lonjakan akselerasi IMU 100Hz dan GPS 5Hz. Memungkinkan uji coba sistem di meja kerja tanpa perlu mengendarai motor.',
                value: state.simulationMode,
                activeColor: AppColors.purple,
                onChanged: (val) {
                  context.read<SettingsCubit>().toggleSimulation(val);
                  context.read<RaceTimerBloc>().add(InitTelemetryServices(isSimulated: val));
                },
              ),

              const SizedBox(height: 16.0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.cyan,
          fontWeight: FontWeight.w900,
          fontSize: 12.0,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    Widget? extraAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Switch(
                value: value,
                activeTrackColor: activeColor.withValues(alpha: 0.5),
                activeThumbColor: activeColor,
                onChanged: onChanged,
              ),
            ],
          ),
          ?extraAction,
        ],
      ),
    );
  }

  Widget _buildSensitivityCard(BuildContext context, SettingsState state) {
    final currentVal = state.triggerSensitivityG;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 18.0, color: AppColors.orange),
              const SizedBox(width: 8.0),
              const Expanded(
                child: Text(
                  'Sensitivitas Pemicu Gas (Launch Trigger)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${currentVal.toStringAsFixed(1)} G',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Ambang batas gaya dorong maju minimal agar stopwatch mulai mencatat waktu tarikan balap.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              _buildSensitivityPreset(context, '0.5 G', 0.5, (currentVal - 0.5).abs() < 0.1),
              const SizedBox(width: 8.0),
              _buildSensitivityPreset(context, '1.0 G', 1.0, (currentVal - 1.0).abs() < 0.1),
              const SizedBox(width: 8.0),
              _buildSensitivityPreset(context, '2.0 G', 2.0, (currentVal - 2.0).abs() < 0.1),
              const SizedBox(width: 8.0),
              _buildSensitivityPreset(context, '4.0 G', 4.0, (currentVal - 4.0).abs() < 0.1),
            ],
          ),
          const SizedBox(height: 10.0),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentVal.clamp(0.2, 5.0),
              min: 0.2,
              max: 5.0,
              divisions: 24,
              label: '${currentVal.toStringAsFixed(1)} G',
              onChanged: (val) {
                final rounded = double.parse(val.toStringAsFixed(1));
                context.read<SettingsCubit>().setTriggerSensitivity(rounded);
                context.read<RaceTimerBloc>().add(UpdateTriggerThreshold(rounded));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityPreset(
    BuildContext context,
    String label,
    double val,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<SettingsCubit>().setTriggerSensitivity(val);
          context.read<RaceTimerBloc>().add(UpdateTriggerThreshold(val));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange.withValues(alpha: 0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected ? AppColors.orange : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.orange : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

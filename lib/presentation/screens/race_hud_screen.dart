import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/models/discipline_type.dart';
import '../../domain/models/fsm_state.dart';
import '../bloc/timer/race_timer_bloc.dart';
import '../bloc/timer/race_timer_event.dart';
import '../bloc/timer/race_timer_state.dart';
import '../widgets/digital_hud_metric.dart';
import '../widgets/fsm_status_badge.dart';
import '../widgets/gnss_signal_badge.dart';
import '../widgets/split_times_table.dart';
import 'session_detail_screen.dart';

class RaceHudScreen extends StatelessWidget {
  const RaceHudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RaceTimerBloc, RaceTimerState>(
      listener: (context, state) {
        if (state.alertMessage != null && state.alertMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.alertMessage!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: state.fsmState == FsmState.finished
                  ? AppColors.purple
                  : (state.fsmState == FsmState.armed
                      ? AppColors.cyan
                      : AppColors.red),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return _buildLandscapeLayout(context, state);
                }
                return _buildPortraitLayout(context, state);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, RaceTimerState state) {
    return Column(
      children: [
        // Top Telemetry Header
        _buildTopHeader(context, state),
        const SizedBox(height: 12.0),

        // Discipline & FSM Badges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                GestureDetector(
                  onTap: () => _showDisciplinePicker(context, state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 14.0, color: AppColors.cyan),
                        const SizedBox(width: 6.0),
                        Text(
                          state.discipline.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FsmStatusBadge(state: state.fsmState),
              ],
            ),
          ),

        const Spacer(),

        // Primary Metrics: TIME and SPEED (64pt Digital Displays)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Timer Display
              DigitalHudMetric(
                label: 'WAKTU TEMPUH',
                value: state.elapsedSeconds.toStringAsFixed(2),
                unit: 's',
                valueColor: state.fsmState == FsmState.running
                    ? AppColors.green
                    : (state.fsmState == FsmState.finished
                        ? AppColors.purple
                        : AppColors.cyan),
                fontSize: 68.0,
              ),

              const SizedBox(height: 12.0),

              // Speedometer Display
              DigitalHudMetric(
                label: 'KECEPATAN',
                value: state.currentSpeedKmh.toStringAsFixed(1),
                unit: 'km/j',
                valueColor: AppColors.textPrimary,
                fontSize: 60.0,
              ),

              const SizedBox(height: 8.0),

              // Distance counter
              Text(
                '${state.currentDistanceMeters.toStringAsFixed(1)} METER',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Split Times Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SplitTimesTable(
            split60ft: state.split60ft,
            split100m: state.split100m,
            split201m: state.split201m,
            split402m: state.split402m,
            split0To100: state.split0To100,
            rolloutSec: state.oneFootRolloutSec,
            activeDiscipline: state.discipline,
          ),
        ),

        const SizedBox(height: 12.0),

        // Action & Control Panel
        _buildBottomControls(context, state),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, RaceTimerState state) {
    return Row(
      children: [
        // Left Column: Big Timer & G-Force
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTopHeader(context, state),
                DigitalHudMetric(
                  label: 'WAKTU TEMPUH',
                  value: state.elapsedSeconds.toStringAsFixed(2),
                  unit: 's',
                  valueColor: state.fsmState == FsmState.running
                      ? AppColors.green
                      : AppColors.cyan,
                  fontSize: 72.0,
                ),
              ],
            ),
          ),
        ),

        // Right Column: Speed, Splits & Controls
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        state.discipline.displayName,
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FsmStatusBadge(state: state.fsmState),
                  ],
                ),
                DigitalHudMetric(
                  label: 'KECEPATAN',
                  value: state.currentSpeedKmh.toStringAsFixed(1),
                  unit: 'km/j',
                  valueColor: AppColors.textPrimary,
                  fontSize: 64.0,
                ),
                SplitTimesTable(
                  split60ft: state.split60ft,
                  split100m: state.split100m,
                  split201m: state.split201m,
                  split402m: state.split402m,
                  split0To100: state.split0To100,
                  rolloutSec: state.oneFootRolloutSec,
                  activeDiscipline: state.discipline,
                ),
                _buildBottomControls(context, state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context, RaceTimerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GPS Satellites & Accuracy
          GnssSignalBadge(
            satellites: state.gpsSatellites,
            accuracyMeters: state.gpsAccuracyMeters,
          ),

          // Vehicle Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler, size: 14.0, color: AppColors.cyan),
                const SizedBox(width: 4.0),
                Text(
                  state.currentVehicle?.vehicleName ?? 'Default Bike',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Slope & IMU Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'SLOPE: ${state.slopePercent >= 0 ? "+" : ""}${state.slopePercent.toStringAsFixed(1)}% '
              '${state.isValidSlope ? "(VALID)" : "(TIDAK VALID)"}',
              style: TextStyle(
                color: state.isValidSlope ? AppColors.green : AppColors.red,
                fontWeight: FontWeight.bold,
                fontSize: 11.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, RaceTimerState state) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Main Action Button: If RUNNING, allow Finish & Save; otherwise Prepare Timer
              if (state.fsmState == FsmState.running)
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<RaceTimerBloc>().add(const ForceFinishAndSaveRace());
                    },
                    icon: const Icon(Icons.flag, size: 18.0),
                    label: const Text(
                      'FINIS & SIMPAN',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<RaceTimerBloc>().add(const ForceArmRace());
                    },
                    icon: const Icon(Icons.flash_on, size: 18.0),
                    label: const Text(
                      'SIAPKAN TIMER',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8.0),

              // View Last Finished Session Button (if available)
              if (state.lastFinishedSession != null) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionDetailScreen(
                            sessionId: state.lastFinishedSession!.sessionId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics, size: 16.0),
                    label: const Text(
                      'GRAFIK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
              ],

              // Reset Button
              IconButton(
                onPressed: () {
                  context.read<RaceTimerBloc>().add(const ResetRaceToIdle());
                },
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Reset Timer',
              ),
            ],
          ),

          // Simulation Mode Quick Actions (if simulator active)
          if (state.isSimulated) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<RaceTimerBloc>().add(const SimulateTriggerLaunchEvent());
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.green),
                      foregroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    child: const Text('SIMULASI GAS (>0.15G)'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<RaceTimerBloc>().add(const SimulateFalseStartEvent());
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.red),
                      foregroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    child: const Text('SIMULASI FALSE START'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDisciplinePicker(BuildContext context, RaceTimerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'PILIH KATEGORI BALAP',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Divider(color: AppColors.border),
              ...DisciplineType.values.map((disc) {
                final isSelected = disc == state.discipline;
                return ListTile(
                  title: Text(
                    disc.displayName,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.cyan)
                      : null,
                  onTap: () {
                    context.read<RaceTimerBloc>().add(ChangeDiscipline(disc));
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12.0),
            ],
          ),
        );
      },
    );
  }
}

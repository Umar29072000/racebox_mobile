import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/models/discipline_type.dart';
import '../../domain/models/race_session.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DisciplineType? _selectedDiscipline;

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadHistorySessions());
  }

  void _onFilterChanged(DisciplineType? discipline) {
    setState(() {
      _selectedDiscipline = discipline;
    });
    context.read<HistoryBloc>().add(LoadHistorySessions(
      filterDiscipline: discipline,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'RIWAYAT & LOG BALAP',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Body Content
          Expanded(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                if (state is HistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  );
                }

                if (state is HistoryError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  );
                }

                if (state is HistoryLoaded) {
                  if (state.sessions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppColors.cyan,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      context.read<HistoryBloc>().add(LoadHistorySessions(
                        filterDiscipline: _selectedDiscipline,
                      ));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.sessions.length + (state.bestSession != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (state.bestSession != null && index == 0) {
                          return _buildBestRecordCard(state.bestSession!);
                        }
                        final actualIndex = state.bestSession != null ? index - 1 : index;
                        final session = state.sessions[actualIndex];
                        return _buildSessionCard(context, session);
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 48.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildTabChip('SEMUA', _selectedDiscipline == null, () => _onFilterChanged(null)),
          ...DisciplineType.values.map((disc) {
            final isSelected = _selectedDiscipline == disc;
            return _buildTabChip(
              disc.shortCode,
              isSelected,
              () => _onFilterChanged(disc),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBestRecordCard(RaceSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.25),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.purple, size: 28.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'REKOR TERBAIK (PB)',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.0,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      session.disciplineType.shortCode,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${session.finalTimeSec.toStringAsFixed(2)}s @ ${session.trapSpeedKmh.toStringAsFixed(1)} km/j',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  session.vehicleName,
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, RaceSession s) {
    final dateStr = DateFormat('dd MMM, HH:mm').format(s.createdAt);

    return Dismissible(
      key: Key(s.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: AppColors.red.withValues(alpha: 0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<HistoryBloc>().add(DeleteHistorySession(s.sessionId));
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(sessionId: s.sessionId),
            ),
          );
        },
        child: Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              s.disciplineType.shortCode,
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            s.vehicleName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),

                  // Right: Time & Speed
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.finalTimeSec.toStringAsFixed(2)}s',
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: AppColors.green,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${s.trapSpeedKmh.toStringAsFixed(1)} km/j',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Icon(
                            s.isValidSlope ? Icons.check_circle : Icons.warning,
                            size: 13.0,
                            color: s.isValidSlope ? AppColors.green : AppColors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (s.split60ftSec != null || s.split100mSec != null || s.split0To100Sec != null) ...[
                const SizedBox(height: 8.0),
                const Divider(color: AppColors.border, height: 1.0),
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    if (s.split60ftSec != null)
                      _buildMiniSplitBadge('60ft', '${s.split60ftSec!.toStringAsFixed(2)}s'),
                    if (s.split100mSec != null)
                      _buildMiniSplitBadge('100m', '${s.split100mSec!.toStringAsFixed(2)}s'),
                    if (s.split201mSec != null && s.disciplineType != DisciplineType.drag201m)
                      _buildMiniSplitBadge('201m', '${s.split201mSec!.toStringAsFixed(2)}s'),
                    if (s.split0To100Sec != null)
                      _buildMiniSplitBadge('0-100', '${s.split0To100Sec!.toStringAsFixed(2)}s', highlight: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSplitBadge(String label, String val, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: highlight ? AppColors.yellow.withValues(alpha: 0.15) : AppColors.card,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: highlight ? AppColors.yellow.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Text(
        '$label: $val',
        style: TextStyle(
          color: highlight ? AppColors.yellow : AppColors.textSecondary,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 54.0, color: AppColors.textMuted),
          SizedBox(height: 12.0),
          Text(
            'Belum ada riwayat tarikan tercatat',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'Buka menu Race HUD dan lakukan tarikan gas!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.0),
          ),
        ],
      ),
    );
  }
}

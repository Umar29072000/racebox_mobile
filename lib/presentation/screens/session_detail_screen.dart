import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../data/datasources/database/app_database.dart';
import '../../data/repositories/race_session_repository_impl.dart';
import '../../domain/models/discipline_type.dart';
import '../../domain/models/race_session.dart';
import '../widgets/split_times_table.dart';
import '../widgets/telemetry_chart_widget.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _repository = RaceSessionRepositoryImpl(AppDatabase());
  RaceSession? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final s = await _repository.getSessionById(widget.sessionId);
      if (mounted) {
        setState(() {
          _session = s;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_session == null) return;
    try {
      final csvString = await _repository.exportSessionToCsv(_session!.sessionId);
      final filename = 'racebox_${_session!.disciplineType.shortCode}_${_session!.finalTimeSec.toStringAsFixed(2)}s.csv';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Ekspor Telemetri RaceBox - $filename',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor CSV: $e')),
        );
      }
    }
  }

  Future<void> _shareSummary() async {
    if (_session == null) return;
    final s = _session!;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(s.createdAt);

    final text = '''
🏁 HASIL RACEBOX PERFORMANCE TIMER 🏁
Kategori: ${s.disciplineType.displayName}
Motor: ${s.vehicleName}
Tanggal: $dateStr

⏱ Waktu Akhir: ${s.finalTimeSec.toStringAsFixed(2)}s
🚀 Kecepatan Finis: ${s.trapSpeedKmh.toStringAsFixed(1)} km/j
⚡ G-Force Puncak: ${s.peakGForce.toStringAsFixed(2)} G
📐 Kemiringan (Slope): ${s.slopePercent.toStringAsFixed(1)}% (${s.isValidSlope ? "VALID" : "TIDAK VALID"})
${s.isRolloutApplied ? "🏎 Rollout 1-Kaki: ${s.oneFootRolloutSec?.toStringAsFixed(2)}s dipotong" : ""}

SPLITS (WAKTU ANTARA):
• 60ft: ${s.split60ftSec?.toStringAsFixed(2) ?? '--'}s
• 100m: ${s.split100mSec?.toStringAsFixed(2) ?? '--'}s
• 201m: ${s.split201mSec?.toStringAsFixed(2) ?? '--'}s
• 402m: ${s.split402mSec?.toStringAsFixed(2) ?? '--'}s
• 0-100: ${s.split0To100Sec?.toStringAsFixed(2) ?? '--'}s
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Hasil RaceBox: ${s.finalTimeSec}s',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'DETAIL TELEMETRI SESI',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppColors.cyan),
            tooltip: 'Ekspor CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.green),
            tooltip: 'Bagikan Hasil',
            onPressed: _shareSummary,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }

    if (_error != null || _session == null) {
      return Center(
        child: Text(
          _error ?? 'Session not found',
          style: const TextStyle(color: AppColors.red),
        ),
      );
    }

    final s = _session!;
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm:ss').format(s.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle & Discipline banner
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.vehicleName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: s.isValidSlope
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: s.isValidSlope ? AppColors.green : AppColors.red,
                    ),
                  ),
                  child: Text(
                    '${s.slopePercent >= 0 ? "+" : ""}${s.slopePercent.toStringAsFixed(1)}% SLOPE',
                    style: TextStyle(
                      color: s.isValidSlope ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // Primary Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'WAKTU AKHIR',
                  value: '${s.finalTimeSec.toStringAsFixed(2)}s',
                  color: AppColors.purple,
                  sublabel: s.isRolloutApplied ? 'Rollout 1-Kaki Aktif' : 'Murni Tanpa Rollout',
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricCard(
                  label: 'KECEPATAN FINIS',
                  value: '${s.trapSpeedKmh.toStringAsFixed(1)} km/j',
                  color: AppColors.green,
                  sublabel: 'Di Garis Finis',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'G-FORCE PUNCAK',
                  value: '${s.peakGForce.toStringAsFixed(2)} G',
                  color: AppColors.cyan,
                  sublabel: 'Akselerasi Start',
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricCard(
                  label: 'KATEGORI',
                  value: s.disciplineType.shortCode,
                  color: AppColors.yellow,
                  sublabel: s.disciplineType.displayName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // Splits Section
          SplitTimesTable(
            split60ft: s.split60ftSec,
            split100m: s.split100mSec,
            split201m: s.split201mSec,
            split402m: s.split402mSec,
            split0To100: s.split0To100Sec,
            rolloutSec: s.oneFootRolloutSec,
            activeDiscipline: s.disciplineType,
          ),

          const SizedBox(height: 20.0),

          // Telemetry Speed vs Time Graph
          const Row(
            children: [
              Icon(Icons.show_chart, size: 18.0, color: AppColors.cyan),
              SizedBox(width: 8.0),
              Text(
                'KURVA TELEMETRI KECEPATAN & G-FORCE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          TelemetryChartWidget(
            samples: s.telemetrySamples,
            targetDistance: s.disciplineType.targetDistanceMeters,
          ),

          const SizedBox(height: 12.0),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 10.0, color: AppColors.green),
              SizedBox(width: 6.0),
              Text('Kecepatan (km/j)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.0)),
              SizedBox(width: 20.0),
              Icon(Icons.circle, size: 10.0, color: AppColors.cyan),
              SizedBox(width: 6.0),
              Text('G-Force (0 - 2.0G)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.0)),
            ],
          ),

          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

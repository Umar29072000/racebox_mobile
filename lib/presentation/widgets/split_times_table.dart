import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/discipline_type.dart';

class SplitTimesTable extends StatelessWidget {
  final double? split60ft;
  final double? split100m;
  final double? split201m;
  final double? split402m;
  final double? split0To100;
  final double? rolloutSec;
  final DisciplineType? activeDiscipline;

  const SplitTimesTable({
    super.key,
    this.split60ft,
    this.split100m,
    this.split201m,
    this.split402m,
    this.split0To100,
    this.rolloutSec,
    this.activeDiscipline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
              const Text(
                'WAKTU ANTARA (SPLIT)',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              if (rolloutSec != null)
                Text(
                  '1-FT: ${rolloutSec!.toStringAsFixed(2)}s',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.yellow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSplitItem('60ft', split60ft, highlight: activeDiscipline == DisciplineType.drag60ft),
              _buildDivider(),
              _buildSplitItem('100m', split100m, highlight: activeDiscipline == DisciplineType.drag100m),
              _buildDivider(),
              _buildSplitItem('201m', split201m, highlight: activeDiscipline == null || activeDiscipline == DisciplineType.drag201m),
              _buildDivider(),
              _buildSplitItem('402m', split402m, highlight: activeDiscipline == DisciplineType.drag402m),
              _buildDivider(),
              _buildSplitItem('0-100', split0To100, highlight: activeDiscipline == DisciplineType.sprint0To100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitItem(String label, double? timeSec, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.cyan : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          timeSec != null ? '${timeSec.toStringAsFixed(2)}s' : '--.--',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: timeSec != null
                ? (highlight ? AppColors.cyan : AppColors.textPrimary)
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 24.0,
      color: AppColors.border,
    );
  }
}

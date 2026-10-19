import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/race_constants.dart';

class GnssSignalBadge extends StatelessWidget {
  final int satellites;
  final double accuracyMeters;

  const GnssSignalBadge({
    super.key,
    required this.satellites,
    required this.accuracyMeters,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrecise = accuracyMeters <= RaceConstants.maxGpsAccuracyForStaging &&
        satellites >= RaceConstants.minSatellitesForStaging;

    final Color statusColor = isPrecise ? AppColors.green : AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.6),
                  blurRadius: 6.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            '$satellites SAT',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(width: 4.0),
          Text(
            '(${accuracyMeters.toStringAsFixed(1)}m)',
            style: TextStyle(
              color: isPrecise ? AppColors.green : AppColors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GForceMeter extends StatelessWidget {
  final double currentG;
  final double peakG;

  const GForceMeter({
    super.key,
    required this.currentG,
    required this.peakG,
  });

  @override
  Widget build(BuildContext context) {
    final double normalizedCurrent = (currentG / 1.5).clamp(0.0, 1.0);
    final double normalizedPeak = (peakG / 1.5).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, size: 16.0, color: AppColors.cyan),
                  const SizedBox(width: 6.0),
                  const Text(
                    'G-FORCE',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'PUNCAK: ${peakG.toStringAsFixed(2)} G',
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Stack(
            children: [
              // Track
              Container(
                height: 8.0,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              // Current G fill
              FractionallySizedBox(
                widthFactor: normalizedCurrent,
                child: Container(
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.5),
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                ),
              ),
              // Peak marker
              if (normalizedPeak > 0)
                Align(
                  alignment: Alignment(normalizedPeak * 2 - 1, 0),
                  child: Container(
                    width: 3.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

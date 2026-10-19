import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DigitalHudMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final double fontSize;

  const DigitalHudMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.valueColor = AppColors.textPrimary,
    this.fontSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: valueColor,
                letterSpacing: -1.0,
                shadows: [
                  Shadow(
                    color: valueColor.withValues(alpha: 0.35),
                    blurRadius: 16.0,
                  ),
                ],
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4.0),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

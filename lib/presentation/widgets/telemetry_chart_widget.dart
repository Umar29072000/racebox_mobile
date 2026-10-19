import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/telemetry_point.dart';

class TelemetryChartWidget extends StatelessWidget {
  final List<TelemetryPoint> samples;
  final double? targetDistance;

  const TelemetryChartWidget({
    super.key,
    required this.samples,
    this.targetDistance,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return Container(
        height: 220.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Belum ada data telemetri tercatat',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final speedSpots = <FlSpot>[];
    final gForceSpots = <FlSpot>[];

    double maxTime = 1.0;
    double maxSpeed = 20.0;

    for (final s in samples) {
      final t = s.elapsedMs / 1000.0;
      if (t > maxTime) maxTime = t;
      if (s.speedKmh > maxSpeed) maxSpeed = s.speedKmh;
    }

    final maxY = (maxSpeed * 1.15).ceilToDouble();

    if (samples.isNotEmpty && (samples.first.elapsedMs / 1000.0) > 0.1) {
      speedSpots.add(const FlSpot(0.0, 0.0));
      gForceSpots.add(const FlSpot(0.0, 0.0));
    }

    // Map Speed & G-Force:
    // G-Force scale (0.0G - 2.0G) is mapped to 0% - 70% of maxY so it never exceeds chart height
    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      final t = s.elapsedMs / 1000.0;
      speedSpots.add(FlSpot(t, s.speedKmh));

      // 3-point moving average to smooth mechanical pothole/vibration noise
      double rawG = s.linearAccelG.clamp(0.0, 2.0);
      if (i > 0 && i < samples.length - 1) {
        final prevG = samples[i - 1].linearAccelG.clamp(0.0, 2.0);
        final nextG = samples[i + 1].linearAccelG.clamp(0.0, 2.0);
        rawG = (prevG + rawG + nextG) / 3.0;
      }

      // Map 0.0G - 2.0G proportionally to 0.0 - (maxY * 0.70)
      final mappedG = (rawG / 2.0) * (maxY * 0.70);
      gForceSpots.add(FlSpot(t, mappedG));
    }

    return Container(
      height: 240.0,
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, right: 12.0, left: 4.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          // Guaranteed clipping: never allow curve drawing to bleed outside the chart viewport
          clipData: const FlClipData.all(),
          minX: 0,
          maxX: maxTime,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY / 4).clamp(5.0, 50.0),
            getDrawingHorizontalLine: (val) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (val) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: maxY / 2,
                getTitlesWidget: (val, meta) {
                  // Calculate corresponding G-Force value from mapped Y
                  final gVal = (val / (maxY * 0.70)) * 2.0;
                  if (gVal < 0 || gVal > 2.2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '${gVal.toStringAsFixed(1)}G',
                      style: TextStyle(
                        color: AppColors.cyan.withValues(alpha: 0.7),
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (maxTime / 4).clamp(1.0, 10.0),
                getTitlesWidget: (val, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${val.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.0,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: (maxY / 4).clamp(5.0, 50.0),
                getTitlesWidget: (val, meta) {
                  return Text(
                    '${val.toInt()}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.border),
          ),
          lineBarsData: [
            // Speed Curve (Green)
            LineChartBarData(
              spots: speedSpots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.green,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.green.withValues(alpha: 0.15),
              ),
            ),
            // G-Force Curve (Cyan)
            LineChartBarData(
              spots: gForceSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.cyan,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

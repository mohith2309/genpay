import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class TrendGraph extends StatelessWidget {
  final Map<DateTime, double> data;
  final Color lineColor;
  final bool showDots;
  final double height;

  const TrendGraph({
    super.key,
    required this.data,
    this.lineColor = AppColors.accent,
    this.showDots = false,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final sorted = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1000,
            getDrawingHorizontalLine: (val) => FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: maxY > 0 ? maxY / 4 : 1000,
                getTitlesWidget: (val, meta) => Text(
                  AppUtils.formatAmount(val),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: (sorted.length / 5).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                  return Text(
                    AppUtils.formatShortDate(sorted[idx].key),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeColor: Theme.of(context).colorScheme.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Theme.of(context).colorScheme.onSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = idx < sorted.length ? sorted[idx].key : DateTime.now();
                  return LineTooltipItem(
                    '${AppUtils.formatShortDate(date)}\n${AppUtils.formatCurrency(spot.y)}',
                    TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SparklineGraph extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  const SparklineGraph({
    super.key,
    required this.values,
    this.color = AppColors.electricBlue,
    this.width = 60,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);

    final spots = values.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

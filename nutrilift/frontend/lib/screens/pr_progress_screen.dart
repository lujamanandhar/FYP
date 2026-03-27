import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/personal_record.dart';
import '../widgets/nutrilift_header.dart';

const Color _kRed = Color(0xFFE53935);

/// PR Progress Screen — shows weight/reps/volume chart for a single exercise.
class PRProgressScreen extends StatefulWidget {
  final PersonalRecord record;
  const PRProgressScreen({super.key, required this.record});

  @override
  State<PRProgressScreen> createState() => _PRProgressScreenState();
}

class _PRProgressScreenState extends State<PRProgressScreen> {
  int _selectedMetric = 0; // 0=Weight, 1=Reps, 2=Volume

  static const _metrics = ['Weight (kg)', 'Reps', 'Volume'];

  // Build chart data from the single PR record + previous values
  List<FlSpot> get _spots {
    final pr = widget.record;
    final spots = <FlSpot>[];

    // If we have previous values, show progression
    if (_selectedMetric == 0) {
      // Weight progression
      final prev = pr.improvementPercentage != null && pr.improvementPercentage! > 0
          ? pr.maxWeight / (1 + pr.improvementPercentage! / 100)
          : pr.maxWeight * 0.9;
      spots.add(FlSpot(0, prev));
      spots.add(FlSpot(1, pr.maxWeight));
    } else if (_selectedMetric == 1) {
      // Reps progression
      final prev = pr.maxReps > 1 ? (pr.maxReps - 1).toDouble() : pr.maxReps.toDouble();
      spots.add(FlSpot(0, prev));
      spots.add(FlSpot(1, pr.maxReps.toDouble()));
    } else {
      // Volume progression
      final prev = pr.improvementPercentage != null && pr.improvementPercentage! > 0
          ? pr.maxVolume / (1 + pr.improvementPercentage! / 100)
          : pr.maxVolume * 0.9;
      spots.add(FlSpot(0, prev));
      spots.add(FlSpot(1, pr.maxVolume));
    }
    return spots;
  }

  double get _currentValue {
    if (_selectedMetric == 0) return widget.record.maxWeight;
    if (_selectedMetric == 1) return widget.record.maxReps.toDouble();
    return widget.record.maxVolume;
  }

  String get _unit {
    if (_selectedMetric == 0) return 'kg';
    if (_selectedMetric == 1) return 'reps';
    return 'kg·reps';
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.record;
    final dateStr = DateFormat('MMM d, yyyy').format(pr.achievedDate);

    return NutriLiftScaffold(
      title: pr.exerciseName,
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PR summary card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kRed, Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kRed.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFFC107), size: 22),
                    const SizedBox(width: 8),
                    const Text('Personal Record',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PRStat(
                          label: 'Max Weight',
                          value: '${pr.maxWeight.toStringAsFixed(1)} kg'),
                      _PRStat(
                          label: 'Max Reps',
                          value: '${pr.maxReps}'),
                      _PRStat(
                          label: 'Max Volume',
                          value: '${pr.maxVolume.toStringAsFixed(0)}'),
                    ],
                  ),
                  if (pr.improvementPercentage != null &&
                      pr.improvementPercentage! > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '↑ ${pr.improvementPercentage!.toStringAsFixed(1)}% improvement',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Metric selector ───────────────────────────────────
            const Text('Progress Chart',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_metrics.length, (i) {
                final selected = _selectedMetric == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMetric = i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kRed : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _kRed : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _metrics[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // ── Chart ─────────────────────────────────────────────
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final labels = ['Previous', 'Current'];
                          final i = v.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(labels[i],
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: _kRed,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 5,
                          color: _kRed,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _kRed.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Current best ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRed.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.trending_up_rounded, color: _kRed, size: 20),
                const SizedBox(width: 10),
                Text('Current Best: ',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 14)),
                Text(
                  '${_currentValue.toStringAsFixed(_selectedMetric == 1 ? 0 : 1)} $_unit',
                  style: const TextStyle(
                      color: _kRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PRStat extends StatelessWidget {
  final String label;
  final String value;
  const _PRStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}

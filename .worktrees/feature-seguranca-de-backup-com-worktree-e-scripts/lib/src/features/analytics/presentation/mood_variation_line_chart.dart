import 'package:collection/collection.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/gen/assets.gen.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MoodVariationLineChart extends StatefulWidget {
  const MoodVariationLineChart({Key? key, required this.moodRecords}) : super(key: key);

  final List<MoodRecord> moodRecords;

  @override
  State<MoodVariationLineChart> createState() => _MoodVariationLineChartState();
}

class _MoodVariationLineChartState extends State<MoodVariationLineChart> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasAnimated = false;
  final _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // Anima quando pelo menos 30% do widget está visível
    if (info.visibleFraction > 0.3 && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    } else if (info.visibleFraction == 0) {
      // Reseta quando sai da tela completamente
      _hasAnimated = false;
      _controller.reset();
    }
  }

  @override
  void didUpdateWidget(MoodVariationLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodRecords != widget.moodRecords && _hasAnimated) {
      _controller.reset();
      _controller.forward();
    }
  }

  Map<String, List<MoodRecord>> groupRecordsByDate(List<MoodRecord> records) {
    final groups = groupBy(
      records,
      (MoodRecord r) {
        return DateFormat('yyyy-MM-dd').format(r.date);
      },
    );
    return groups;
  }

  List<FlSpot> getDots(Map<String, List<MoodRecord>> groupedRecords, double animProgress) {
    if (groupedRecords.isEmpty) return [];
    
    List<FlSpot> dots = [];
    final firstKey = groupedRecords.keys.first;
    final firstRecords = groupedRecords[firstKey];
    if (firstRecords == null || firstRecords.isEmpty) return [];
    
    var initialDate = firstRecords[0].date;
    var from = DateTime(initialDate.year, initialDate.month, initialDate.day);
    
    int index = 0;
    groupedRecords.forEach(
      (key, value) {
        if (value.isNotEmpty) {
          final fullY = value.fold(0, (previousValue, element) => previousValue + element.score) / value.length;
          // Anima cada ponto com delay baseado no índice
          final delayedProgress = ((animProgress * 1.3) - (index * 0.08)).clamp(0.0, 1.0);
          
          dots.add(
            FlSpot(
              (DateTime.parse(key).difference(from).inHours / 24).round().toDouble(),
              1.0 + (fullY - 1.0) * delayedProgress, // Anima de 1 até o valor final
            ),
          );
          index++;
        }
      },
    );
    return dots;
  }

  (int, int) getMinMaxScores(List<MoodRecord> records) {
    if (records.isEmpty) return (1, 5);
    
    int minScore = records.map((r) => r.score).reduce((a, b) => a < b ? a : b);
    int maxScore = records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    
    minScore = minScore.clamp(1, 5);
    maxScore = maxScore.clamp(1, 5);
    
    return (minScore, maxScore);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moodRecords.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(AppLocalizations.of(context)!.semDadosSuficientes),
        ),
      );
    }

    final groupedRecords = groupRecordsByDate(widget.moodRecords);
    
    if (groupedRecords.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(AppLocalizations.of(context)!.precisaDePeloMenos2Registros),
        ),
      );
    }

    final (minScore, maxScore) = getMinMaxScores(widget.moodRecords);

    return VisibilityDetector(
      key: Key('line-chart-${_visibilityKey.toString()}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: SizedBox(
        height: 180,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final List<FlSpot> dots = getDots(groupedRecords, _animation.value);
            
            return LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: dots,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                        color: Theme.of(context).colorScheme.primary,
                        radius: 4 * _animation.value,
                        strokeColor: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
                        strokeWidth: 2,
                      ),
                    ),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: _animation.value),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .1 * _animation.value),
                    ),
                  ),
                ],
                minY: (minScore - 1).toDouble().clamp(0.0, 5.0),
                maxY: (maxScore + 1).toDouble().clamp(1.0, 6.0),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getLeftTitleWidgets,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => getBottomTitleWidgets(value, meta, dots),
                      interval: 1,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ),
    );
  }

  Color _getMoodColor(int score) {
    switch (score) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.blue;
      case 4: return Colors.cyan;
      case 5: return Colors.green;
      default: return Colors.blue;
    }
  }

  List<Color> _getGradientColors(int minScore, int maxScore) {
    final allColors = [Colors.red, Colors.orange, Colors.blue, Colors.cyan, Colors.green];
    final clampedMin = minScore.clamp(1, 5);
    final clampedMax = maxScore.clamp(1, 5);
    final start = (clampedMin - 1).clamp(0, 4);
    final end = (clampedMax - 1).clamp(0, 4) + 1;
    
    if (start >= allColors.length || end > allColors.length || start >= end) {
      return [allColors[start.clamp(0, allColors.length - 1)]];
    }
    final finalStart = start.clamp(0, allColors.length - 1);
    final finalEnd = (end).clamp(finalStart + 1, allColors.length);
    return allColors.sublist(finalStart, finalEnd);
  }

  List<Color> _getGradientColorsWithOpacity(int minScore, int maxScore) {
    return _getGradientColors(minScore, maxScore)
        .map((c) => c.withValues(alpha: 0.35))
        .toList();
  }

  Widget getLeftTitleWidgets(double value, TitleMeta meta) {
    String icon;
    Color color;
    switch (value.toInt()) {
      case 1:
        icon = Assets.moodIcons.crying;
        color = Colors.red;
        break;
      case 2:
        icon = Assets.moodIcons.confused;
        color = Colors.orange;
        break;
      case 3:
        icon = Assets.moodIcons.neutral;
        color = Colors.blue;
        break;
      case 4:
        icon = Assets.moodIcons.smile;
        color = Colors.cyan;
        break;
      case 5:
        icon = Assets.moodIcons.happy;
        color = Colors.green;
        break;
      default:
        return const SizedBox();
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: SvgPicture.asset(
        icon,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        height: 32,
        width: 32,
      ),
    );
  }

  Widget getBottomTitleWidgets(double value, TitleMeta meta, List<FlSpot> dots) {
    if (widget.moodRecords.isEmpty || value.toInt() >= dots.length) {
      return const SizedBox();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        DateFormat("dd").format(
          widget.moodRecords.first.date.add(
            Duration(days: value.toInt()),
          ),
        ),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

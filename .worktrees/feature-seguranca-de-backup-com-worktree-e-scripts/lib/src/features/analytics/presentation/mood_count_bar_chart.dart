import 'package:collection/collection.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odyssey/gen/assets.gen.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MoodCountBarChart extends StatefulWidget {
  const MoodCountBarChart({
    super.key,
    required this.moodRecords,
  });

  final List<MoodRecord> moodRecords;

  @override
  State<MoodCountBarChart> createState() => _MoodCountBarChartState();
}

class _MoodCountBarChartState extends State<MoodCountBarChart> 
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
      duration: const Duration(milliseconds: 1200),
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
  void didUpdateWidget(MoodCountBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-anima quando dados mudam (se já estiver visível)
    if (oldWidget.moodRecords != widget.moodRecords && _hasAnimated) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('bar-chart-${_visibilityKey.toString()}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: SizedBox(
        height: 180,
        child: widget.moodRecords.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)!.notEnoughData),
              )
            : AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      barGroups: _getBarChartGroups(widget.moodRecords, _animation.value),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: titleWidgets,
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                      ),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
      ),
    );
  }

  List<BarChartGroupData> _getBarChartGroups(List<MoodRecord> records, double animProgress) {
    var groups = groupBy(
      records,
      (e) {
        return e.score;
      },
    );

    var list = List.generate(
      5,
      (index) {
        final fullHeight = groups[index + 1] != null ? groups[index + 1]!.length.toDouble() : 0.0;
        // Anima cada barra com um pequeno delay baseado no índice
        final delayedProgress = ((animProgress * 1.5) - (index * 0.1)).clamp(0.0, 1.0);
        
        return BarChartGroupData(
          x: index + 1,
          barRods: [
            BarChartRodData(
              toY: fullHeight * delayedProgress,
              color: _getColorByMoodScore(index + 1),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: fullHeight > 0 ? fullHeight + 1 : 5,
                color: _getColorByMoodScore(index + 1)?.withValues(alpha: 0.1),
              ),
            )
          ],
        );
      },
    );
    return list;
  }

  Color? _getColorByMoodScore(int score) {
    Color? color;
    switch (score) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.orange;
        break;
      case 3:
        color = Colors.blue;
        break;
      case 4:
        color = Colors.cyan;
        break;
      case 5:
        color = Colors.green;
        break;
      default:
        color = null;
    }
    return color;
  }

  Widget titleWidgets(double score, TitleMeta meta) {
    String icon;
    Color color;
    switch (score.toInt()) {
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
        throw StateError('Invalid');
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: SvgPicture.asset(
        icon,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        height: 32,
        width: 32,
      ),
    );
  }
}

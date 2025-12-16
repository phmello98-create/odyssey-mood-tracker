import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

/// Dados de humor para análise
class MoodAnalysisData {
  final DateTime date;
  final int moodScore;
  final List<String> activities;
  final String? note;

  MoodAnalysisData({
    required this.date,
    required this.moodScore,
    this.activities = const [],
    this.note,
  });
}

/// Widget de análise detalhada de humor
class MoodAnalysisWidget extends StatefulWidget {
  final List<MoodAnalysisData> moodData;
  final int daysToShow;
  final VoidCallback? onViewMore;

  const MoodAnalysisWidget({
    super.key,
    required this.moodData,
    this.daysToShow = 14,
    this.onViewMore,
  });

  @override
  State<MoodAnalysisWidget> createState() => _MoodAnalysisWidgetState();
}

class _MoodAnalysisWidgetState extends State<MoodAnalysisWidget> {
  int _selectedDayIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.moodData.isEmpty) {
      return _EmptyMoodState();
    }

    final sortedData = List<MoodAnalysisData>.from(widget.moodData)
      ..sort((a, b) => a.date.compareTo(b.date));

    final displayData = sortedData.length > widget.daysToShow
        ? sortedData.sublist(sortedData.length - widget.daysToShow)
        : sortedData;

    // Calcular estatísticas
    final avgMood =
        displayData.map((d) => d.moodScore).reduce((a, b) => a + b) /
            displayData.length;
    final maxMood = displayData.map((d) => d.moodScore).reduce(
          (a, b) => a > b ? a : b,
        );
    final minMood = displayData.map((d) => d.moodScore).reduce(
          (a, b) => a < b ? a : b,
        );

    // Calcular tendência
    final firstHalf =
        displayData.take(displayData.length ~/ 2).map((d) => d.moodScore);
    final secondHalf =
        displayData.skip(displayData.length ~/ 2).map((d) => d.moodScore);
    final firstAvg = firstHalf.isEmpty
        ? 0
        : firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.isEmpty
        ? 0
        : secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    final trend = (secondAvg - firstAvg).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mood_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise de Humor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Últimos ${displayData.length} dias',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onViewMore != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: widget.onViewMore,
                  tooltip: 'Ver mais',
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats rápidos
          Row(
            children: [
              _MoodStatChip(
                label: 'Média',
                value: avgMood.toStringAsFixed(1),
                icon: Icons.analytics_outlined,
                color: _getMoodColor(avgMood.round()),
              ),
              const SizedBox(width: 12),
              _MoodStatChip(
                label: 'Melhor',
                value: maxMood.toString(),
                icon: Icons.arrow_upward_rounded,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _MoodStatChip(
                label: 'Pior',
                value: minMood.toString(),
                icon: Icons.arrow_downward_rounded,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              _TrendChip(trend: trend),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico
          SizedBox(
            height: 180,
            child: _buildMoodChart(displayData, colorScheme),
          ),

          // Detalhe do dia selecionado
          if (_selectedDayIndex >= 0 && _selectedDayIndex < displayData.length)
            _buildSelectedDayDetail(
              displayData[_selectedDayIndex],
              colorScheme,
            ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(
      List<MoodAnalysisData> data, ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].moodScore.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 6,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 6) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _getMoodEmoji(value.round()),
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = data[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final spotIndex = response.lineBarSpots!.first.spotIndex;
              if (event is FlTapUpEvent) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDayIndex =
                      _selectedDayIndex == spotIndex ? -1 : spotIndex;
                });
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final mood = spot.y.round();
                return LineTooltipItem(
                  '${_getMoodEmoji(mood)} $mood',
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.8),
                colorScheme.tertiary.withValues(alpha: 0.8),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isSelected = index == _selectedDayIndex;
                final color = _getMoodColor(spot.y.round());
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 4,
                  color: color,
                  strokeWidth: isSelected ? 3 : 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetail(
      MoodAnalysisData data, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getMoodEmoji(data.moodScore),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(data.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Humor: ${data.moodScore}/5 - ${_getMoodLabel(data.moodScore)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _selectedDayIndex = -1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (data.activities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.activities.map((activity) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (data.note != null && data.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${data.note}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.amber.shade400;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Muito mal';
      case 2:
        return 'Mal';
      case 3:
        return 'Neutro';
      case 4:
        return 'Bem';
      case 5:
        return 'Muito bem';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    final months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

class _MoodStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MoodStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final double trend;

  const _TrendChip({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isPositive = trend > 0.1;
    final isNegative = trend < -0.1;
    final color = isPositive
        ? Colors.green
        : isNegative
            ? Colors.red
            : Colors.grey;
    final icon = isPositive
        ? Icons.trending_up_rounded
        : isNegative
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final label = isPositive
        ? 'Subindo'
        : isNegative
            ? 'Caindo'
            : 'Estável';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMoodState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mood_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sem dados de humor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre seu humor para ver análises',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de resumo semanal de humor
class WeeklyMoodSummary extends StatelessWidget {
  final List<MoodAnalysisData> weekData;

  const WeeklyMoodSummary({
    super.key,
    required this.weekData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Organizar por dia da semana
    final moodByDay = <int, List<int>>{};
    for (final data in weekData) {
      final day = data.date.weekday;
      moodByDay.putIfAbsent(day, () => []).add(data.moodScore);
    }

    // Calcular média por dia
    final avgByDay = <int, double>{};
    for (final entry in moodByDay.entries) {
      avgByDay[entry.key] = entry.value.isEmpty
          ? 0
          : entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Encontrar melhor e pior dia
    int? bestDay;
    int? worstDay;
    double bestAvg = 0;
    double worstAvg = 6;

    for (final entry in avgByDay.entries) {
      if (entry.value > bestAvg) {
        bestAvg = entry.value;
        bestDay = entry.key;
      }
      if (entry.value < worstAvg && entry.value > 0) {
        worstAvg = entry.value;
        worstDay = entry.key;
      }
    }

    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Humor por Dia da Semana',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = index + 1;
              final avg = avgByDay[day] ?? 0;
              final isBest = day == bestDay;
              final isWorst = day == worstDay;

              return Column(
                children: [
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isBest || isWorst
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isBest
                          ? Colors.green
                          : isWorst
                              ? Colors.red
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: avg > 0
                          ? _getMoodColor(avg.round()).withValues(alpha: 0.2)
                          : colorScheme.outline.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: isBest || isWorst
                          ? Border.all(
                              color: isBest ? Colors.green : Colors.red,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        avg > 0 ? _getMoodEmoji(avg.round()) : '—',
                        style: TextStyle(fontSize: avg > 0 ? 18 : 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avg > 0 ? avg.toStringAsFixed(1) : '-',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: avg > 0
                          ? _getMoodColor(avg.round())
                          : colorScheme.outline,
                    ),
                  ),
                ],
              );
            }),
          ),
          if (bestDay != null && worstDay != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu melhor dia é ${weekdays[bestDay - 1]} e o mais difícil é ${weekdays[worstDay - 1]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.amber.shade400;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/user_pattern.dart';

/// Widget para visualizar padrões detectados
class PatternChart extends StatelessWidget {
  final UserPattern pattern;
  final double height;

  const PatternChart({
    super.key,
    required this.pattern,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
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
              Text(
                pattern.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pattern.description,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StrengthBadge(strength: pattern.strength),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, ColorScheme colorScheme) {
    switch (pattern.type) {
      case PatternType.temporal:
        return _buildTemporalChart(colorScheme);
      case PatternType.behavioral:
        return _buildBehavioralChart(colorScheme);
      case PatternType.cyclical:
        return _buildTrendChart(colorScheme);
      case PatternType.correlation:
        return _buildCorrelationChart(colorScheme);
    }
  }

  Widget _buildTemporalChart(ColorScheme colorScheme) {
    // Verifica se é padrão por dia da semana ou hora
    final moodByDay = pattern.data['moodByDay'] as Map<int, double>?;
    final moodByHour = pattern.data['moodByHour'] as Map<int, double>?;

    if (moodByDay != null) {
      return _DayOfWeekChart(data: moodByDay, colorScheme: colorScheme);
    } else if (moodByHour != null) {
      return _HourOfDayChart(data: moodByHour, colorScheme: colorScheme);
    }

    return const Center(child: Text('Sem dados para visualizar'));
  }

  Widget _buildBehavioralChart(ColorScheme colorScheme) {
    final byHour = pattern.data['byHour'] as Map<int, int>?;

    if (byHour != null) {
      final data = byHour.map((k, v) => MapEntry(k, v.toDouble()));
      return _HourOfDayChart(data: data, colorScheme: colorScheme);
    }

    return const Center(child: Text('Sem dados para visualizar'));
  }

  Widget _buildTrendChart(ColorScheme colorScheme) {
    final trend = pattern.data['trend'] as String?;
    final slope = pattern.data['slope'] as double?;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            trend == 'rising'
                ? Icons.trending_up_rounded
                : trend == 'falling'
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
            size: 64,
            color: trend == 'rising'
                ? Colors.green
                : trend == 'falling'
                    ? Colors.red
                    : colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            trend == 'rising'
                ? 'Tendência de Alta'
                : trend == 'falling'
                    ? 'Tendência de Queda'
                    : 'Estável',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: trend == 'rising'
                  ? Colors.green
                  : trend == 'falling'
                      ? Colors.red
                      : colorScheme.onSurface,
            ),
          ),
          if (slope != null)
            Text(
              'Variação: ${(slope * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorrelationChart(ColorScheme colorScheme) {
    return const Center(child: Text('Correlação'));
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final Map<int, double> data;
  final ColorScheme colorScheme;

  const _DayOfWeekChart({
    required this.data,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final maxValue = data.values.isEmpty ? 5.0 : data.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + 0.5,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
        barGroups: List.generate(7, (index) {
          final dayOfWeek = index + 1;
          final value = data[dayOfWeek] ?? 0;
          final isHighest = value == maxValue;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: isHighest ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.5),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HourOfDayChart extends StatelessWidget {
  final Map<int, double> data;
  final ColorScheme colorScheme;

  const _HourOfDayChart({
    required this.data,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final periods = ['00h', '04h', '08h', '12h', '16h', '20h'];
    final maxValue = data.values.isEmpty ? 5.0 : data.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + 0.5,
        minY: 0,
        barTouchData: const BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < periods.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      periods[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
        barGroups: List.generate(6, (index) {
          final hour = index * 4;
          final value = data[hour] ?? 0;
          final isHighest = value == maxValue;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: isHighest ? colorScheme.tertiary : colorScheme.tertiary.withValues(alpha: 0.5),
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StrengthBadge extends StatelessWidget {
  final double strength;

  const _StrengthBadge({required this.strength});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (strength * 100).toStringAsFixed(0);

    final color = strength >= 0.7
        ? Colors.green
        : strength >= 0.4
            ? Colors.orange
            : colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Lista de padrões em cards
class PatternsList extends StatelessWidget {
  final List<UserPattern> patterns;
  final void Function(UserPattern)? onPatternTap;

  const PatternsList({
    super.key,
    required this.patterns,
    this.onPatternTap,
  });

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return const Center(
        child: Text('Nenhum padrão detectado ainda'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: patterns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pattern = patterns[index];
        return GestureDetector(
          onTap: () => onPatternTap?.call(pattern),
          child: PatternChart(pattern: pattern),
        );
      },
    );
  }
}

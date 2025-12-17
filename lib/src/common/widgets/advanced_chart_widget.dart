import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipos de gráficos disponíveis
enum ChartType { line, bar, pie }

/// Widget de gráficos avançados com múltiplas visualizações
class AdvancedChartWidget extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final List<ChartType> availableTypes;
  final ChartType initialType;
  final double height;

  const AdvancedChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.availableTypes = const [ChartType.line, ChartType.bar, ChartType.pie],
    this.initialType = ChartType.bar,
    this.height = 200,
  });

  @override
  State<AdvancedChartWidget> createState() => _AdvancedChartWidgetState();
}

class _AdvancedChartWidgetState extends State<AdvancedChartWidget> {
  late ChartType _currentType;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com título e seletor de tipo
          _buildHeader(colors),
          const SizedBox(height: 20),
          // Gráfico
          SizedBox(
            height: widget.height,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildChart(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        // Seletor de tipo de gráfico
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.availableTypes.map((type) {
              final isSelected = _currentType == type;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentType = type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForType(type),
                    size: 16,
                    color: isSelected ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart_rounded;
      case ChartType.bar:
        return Icons.bar_chart_rounded;
      case ChartType.pie:
        return Icons.pie_chart_rounded;
    }
  }

  Widget _buildChart(ColorScheme colors) {
    switch (_currentType) {
      case ChartType.line:
        return _buildLineChart(colors);
      case ChartType.bar:
        return _buildBarChart(colors);
      case ChartType.pie:
        return _buildPieChart(colors);
    }
  }

  Widget _buildLineChart(ColorScheme colors) {
    if (widget.data.isEmpty) return _buildEmptyState(colors);

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: colors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: colors.primary,
                  strokeWidth: 2,
                  strokeColor: colors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colors.primary.withOpacity(0.3),
                  colors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colors.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.data[index].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 5,
      ),
    );
  }

  Widget _buildBarChart(ColorScheme colors) {
    if (widget.data.isEmpty) return _buildEmptyState(colors);

    return BarChart(
      BarChartData(
        barGroups: widget.data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: e.value.color ?? colors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 5,
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colors.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.data[index].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: 5,
      ),
    );
  }

  Widget _buildPieChart(ColorScheme colors) {
    if (widget.data.isEmpty) return _buildEmptyState(colors);

    // Agrupar dados para pizza
    final groupedData = <String, double>{};
    for (final point in widget.data) {
      final key = _getMoodLabel(point.value);
      groupedData[key] = (groupedData[key] ?? 0) + 1;
    }

    final sections = groupedData.entries.map((e) {
      final index = groupedData.keys.toList().indexOf(e.key);
      final isTouched = index == _touchedIndex;
      final color = _getMoodColorFromLabel(e.key, colors);

      return PieChartSectionData(
        value: e.value,
        title: isTouched ? '${e.value.toInt()}' : '',
        color: color,
        radius: isTouched ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched ? null : _buildBadge(e.key, color),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedData.entries.map((e) {
              final color = _getMoodColorFromLabel(e.key, colors);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 48,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Sem dados disponíveis',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _getMoodLabel(double value) {
    if (value >= 4.5) return 'Ótimo';
    if (value >= 3.5) return 'Bem';
    if (value >= 2.5) return 'Ok';
    if (value >= 1.5) return 'Mal';
    return 'Péssimo';
  }

  Color _getMoodColorFromLabel(String label, ColorScheme colors) {
    switch (label) {
      case 'Ótimo':
        return const Color(0xFF4CAF50);
      case 'Bem':
        return const Color(0xFF8BC34A);
      case 'Ok':
        return const Color(0xFFFFEB3B);
      case 'Mal':
        return const Color(0xFFFF9800);
      case 'Péssimo':
        return const Color(0xFFF44336);
      default:
        return colors.primary;
    }
  }
}

/// Ponto de dados para o gráfico
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;

  const ChartDataPoint({required this.label, required this.value, this.color});
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/correlation.dart';

/// Dados de atividade para análise
class ActivityAnalysisData {
  final String id;
  final String name;
  final String icon;
  final int totalCount;
  final double avgMoodWhenDone;
  final double avgMoodWhenNotDone;
  final Correlation? moodCorrelation;
  final Map<int, int> frequencyByDay;
  final Map<int, int> frequencyByHour;

  ActivityAnalysisData({
    required this.id,
    required this.name,
    required this.icon,
    required this.totalCount,
    required this.avgMoodWhenDone,
    required this.avgMoodWhenNotDone,
    this.moodCorrelation,
    this.frequencyByDay = const {},
    this.frequencyByHour = const {},
  });

  double get moodImpact => avgMoodWhenDone - avgMoodWhenNotDone;
  bool get hasPositiveImpact => moodImpact > 0;
}

/// Widget de análise de atividades
class ActivityAnalysisWidget extends StatefulWidget {
  final List<ActivityAnalysisData> activities;
  final void Function(ActivityAnalysisData)? onActivityTap;
  final int maxToShow;

  const ActivityAnalysisWidget({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.maxToShow = 10,
  });

  @override
  State<ActivityAnalysisWidget> createState() => _ActivityAnalysisWidgetState();
}

class _ActivityAnalysisWidgetState extends State<ActivityAnalysisWidget> {
  int _sortMode = 0; // 0: impacto, 1: frequência, 2: correlação
  ActivityAnalysisData? _selectedActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.activities.isEmpty) {
      return _EmptyActivitiesState();
    }

    // Ordenar atividades
    final sorted = List<ActivityAnalysisData>.from(widget.activities);
    switch (_sortMode) {
      case 0:
        sorted.sort((a, b) => b.moodImpact.abs().compareTo(a.moodImpact.abs()));
        break;
      case 1:
        sorted.sort((a, b) => b.totalCount.compareTo(a.totalCount));
        break;
      case 2:
        sorted.sort((a, b) => (b.moodCorrelation?.coefficient.abs() ?? 0)
            .compareTo(a.moodCorrelation?.coefficient.abs() ?? 0));
        break;
    }

    final displayActivities = sorted.take(widget.maxToShow).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
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
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: colorScheme.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise de Atividades',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.activities.length} atividades registradas',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filtros de ordenação
          _buildSortFilters(colorScheme),

          const SizedBox(height: 16),

          // Lista de atividades
          ...displayActivities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityListItem(
                  activity: activity,
                  isSelected: _selectedActivity == activity,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedActivity =
                          _selectedActivity == activity ? null : activity;
                    });
                    widget.onActivityTap?.call(activity);
                  },
                ),
              )),

          // Detalhe da atividade selecionada
          if (_selectedActivity != null)
            _buildActivityDetail(_selectedActivity!, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSortFilters(ColorScheme colorScheme) {
    final filters = [
      ('Impacto', Icons.trending_up_rounded),
      ('Frequência', Icons.repeat_rounded),
      ('Correlação', Icons.link_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final (label, icon) = entry.value;
          final isSelected = _sortMode == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sortMode = index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityDetail(
      ActivityAnalysisData activity, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
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
                activity.icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Feito ${activity.totalCount} vezes',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _selectedActivity = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _DetailStat(
                label: 'Humor quando faz',
                value: activity.avgMoodWhenDone.toStringAsFixed(1),
                icon: Icons.mood_rounded,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _DetailStat(
                label: 'Humor quando não faz',
                value: activity.avgMoodWhenNotDone.toStringAsFixed(1),
                icon: Icons.mood_bad_rounded,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _DetailStat(
                label: 'Impacto',
                value:
                    '${activity.moodImpact >= 0 ? '+' : ''}${activity.moodImpact.toStringAsFixed(1)}',
                icon: activity.hasPositiveImpact
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: activity.hasPositiveImpact ? Colors.green : Colors.red,
              ),
            ],
          ),

          // Correlação
          if (activity.moodCorrelation != null) ...[
            const SizedBox(height: 16),
            _buildCorrelationInfo(activity.moodCorrelation!, colorScheme),
          ],

          // Frequência por dia da semana
          if (activity.frequencyByDay.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFrequencyChart(activity, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrelationInfo(
      Correlation correlation, ColorScheme colorScheme) {
    final isPositive = correlation.isPositive;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correlation.strengthText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  correlation.description ??
                      'Coeficiente: ${correlation.coefficient.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              correlation.percentageText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(
      ActivityAnalysisData activity, ColorScheme colorScheme) {
    final weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final maxFreq = activity.frequencyByDay.values.isEmpty
        ? 1
        : activity.frequencyByDay.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequência por dia da semana',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = index + 1;
            final freq = activity.frequencyByDay[day] ?? 0;
            final height = maxFreq > 0 ? (freq / maxFreq) * 40 + 10 : 10.0;

            return Column(
              children: [
                Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final ActivityAnalysisData activity;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ActivityListItem({
    required this.activity,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final impactColor = activity.hasPositiveImpact ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              activity.icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${activity.totalCount}x feito',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Impacto no humor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: impactColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activity.hasPositiveImpact
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: impactColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.moodImpact >= 0 ? '+' : ''}${activity.moodImpact.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: impactColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
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
                fontSize: 8,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivitiesState extends StatelessWidget {
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
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: 48,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sem dados de atividades',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre atividades para ver análises',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de atividades mais impactantes
class TopActivitiesChart extends StatelessWidget {
  final List<ActivityAnalysisData> activities;
  final int maxToShow;

  const TopActivitiesChart({
    super.key,
    required this.activities,
    this.maxToShow = 5,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordenar por impacto absoluto
    final sorted = List<ActivityAnalysisData>.from(activities)
      ..sort((a, b) => b.moodImpact.abs().compareTo(a.moodImpact.abs()));
    final displayActivities = sorted.take(maxToShow).toList();

    final maxImpact = displayActivities
        .map((a) => a.moodImpact.abs())
        .reduce((a, b) => a > b ? a : b);

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
                Icons.bar_chart_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Atividades por Impacto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayActivities.map((activity) {
            final barWidth =
                (activity.moodImpact.abs() / maxImpact) * 0.7 + 0.1;
            final color =
                activity.hasPositiveImpact ? Colors.green : Colors.red;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(activity.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barWidth,
                                  backgroundColor:
                                      colorScheme.outline.withValues(alpha: 0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${activity.moodImpact >= 0 ? '+' : ''}${activity.moodImpact.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/features/water_tracker/data/water_tracker_provider.dart';
import 'package:odyssey/src/features/water_tracker/domain/water_record.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Tela de histórico do Water Tracker
class WaterHistoryScreen extends ConsumerStatefulWidget {
  const WaterHistoryScreen({super.key});

  @override
  ConsumerState<WaterHistoryScreen> createState() => _WaterHistoryScreenState();
}

class _WaterHistoryScreenState extends ConsumerState<WaterHistoryScreen> {
  static const Color _waterColor = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          l10n.waterTrackerTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats semanais
            _WeeklyStatsCard(),
            const SizedBox(height: 24),

            // Gráfico semanal
            _WeeklyChartSection(),
            const SizedBox(height: 24),

            // Histórico dos últimos 7 dias
            Text(
              'Últimos 7 dias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _WeekHistoryList(),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.water_drop_rounded, color: _waterColor),
            const SizedBox(width: 12),
            const Text('Sobre Hidratação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoItem(
              icon: Icons.local_drink_rounded,
              text: 'Recomendação: 2L de água por dia',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.schedule_rounded,
              text: 'Beba água regularmente ao longo do dia',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.fitness_center_rounded,
              text: 'Aumente a ingestão em dias de exercício',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.wb_sunny_rounded,
              text: 'Em dias quentes, beba mais água',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendi', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF42A5F5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Card de estatísticas semanais
class _WeeklyStatsCard extends ConsumerWidget {
  static const Color _waterColor = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return ref
        .watch(waterWeekStatsProvider)
        .when(
          data: (stats) {
            final totalMl = stats['totalMl'] as int? ?? 0;
            final totalGlasses = stats['totalGlasses'] as int? ?? 0;
            final avgGlasses = stats['avgGlasses'] as double? ?? 0.0;
            final daysWithGoal = stats['daysWithGoal'] as int? ?? 0;
            final streak = stats['streak'] as int? ?? 0;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _waterColor.withValues(alpha: 0.15),
                    _waterColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _waterColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _waterColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: _waterColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumo da Semana',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              'Últimos 7 dias',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$streak dias',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.water_drop_rounded,
                          value: '${(totalMl / 1000).toStringAsFixed(1)}L',
                          label: 'Total',
                          color: _waterColor,
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.local_drink_rounded,
                          value: '$totalGlasses',
                          label: 'Copos',
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.show_chart_rounded,
                          value: avgGlasses.toStringAsFixed(1),
                          label: 'Média/dia',
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.check_circle_rounded,
                          value: '$daysWithGoal/7',
                          label: 'Metas',
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colors.error),
                const SizedBox(width: 12),
                Text(
                  'Erro ao carregar estatísticas',
                  style: TextStyle(color: colors.error),
                ),
              ],
            ),
          ),
        );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Gráfico semanal de consumo de água
class _WeeklyChartSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final repository = ref.watch(waterTrackerRepositoryProvider);

    return FutureBuilder<List<WaterRecord>>(
      future: repository.getWeekRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sem dados de água ainda',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data!;
        final maxGlasses = records
            .map((r) => r.goalGlasses)
            .reduce((a, b) => a > b ? a : b);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consumo Semanal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Gráfico de barras
              SizedBox(
                height: 150,
                child: _WaterBarChart(
                  records: records,
                  maxValue: maxGlasses.toDouble(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Gráfico de barras personalizado
class _WaterBarChart extends StatelessWidget {
  final List<WaterRecord> records;
  final double maxValue;

  const _WaterBarChart({required this.records, required this.maxValue});

  static const Color _waterColor = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    // Criar mapa de registros por data
    final recordMap = <String, WaterRecord>{};
    for (final record in records) {
      recordMap[record.id] = record;
    }

    // Gerar os últimos 7 dias
    final days = List.generate(7, (i) {
      return today.subtract(Duration(days: 6 - i));
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final dateId =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final record = recordMap[dateId];
        final glasses = record?.glassesCount ?? 0;
        final isToday =
            day.day == today.day &&
            day.month == today.month &&
            day.year == today.year;
        final goalReached = record?.goalReached ?? false;
        final progress = maxValue > 0
            ? (glasses / maxValue).clamp(0.0, 1.0)
            : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Valor
                Text(
                  '$glasses',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: goalReached
                        ? const Color(0xFF4CAF50)
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),

                // Barra
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 90 * progress + 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: goalReached
                          ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                          : [_waterColor, const Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: _waterColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Dia da semana
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: isToday
                      ? BoxDecoration(
                          color: _waterColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        )
                      : null,
                  child: Text(
                    weekDays[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? _waterColor : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Lista de histórico da semana
class _WeekHistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final repository = ref.watch(waterTrackerRepositoryProvider);

    return FutureBuilder<List<WaterRecord>>(
      future: repository.getWeekRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Nenhum registro ainda',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          );
        }

        // Ordenar do mais recente para o mais antigo
        final records = snapshot.data!.reversed.toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _WaterHistoryItem(record: record);
          },
        );
      },
    );
  }
}

/// Item do histórico
class _WaterHistoryItem extends StatelessWidget {
  final WaterRecord record;

  const _WaterHistoryItem({required this.record});

  static const Color _waterColor = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isToday =
        record.date.day == today.day &&
        record.date.month == today.month &&
        record.date.year == today.year;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: _waterColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Data
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: record.goalReached
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : _waterColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: record.goalReached
                        ? const Color(0xFF4CAF50)
                        : _waterColor,
                  ),
                ),
                Text(
                  _getMonthAbbr(record.date.month),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isToday
                          ? 'Hoje'
                          : DateFormat('EEEE', 'pt_BR').format(record.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (record.goalReached) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Meta atingida!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.totalMl}ml • ${record.glassesCount} copos de ${record.glassSizeMl}ml',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Progresso
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.glassesCount}/${record.goalGlasses}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: record.goalReached
                      ? const Color(0xFF4CAF50)
                      : _waterColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: record.progress.clamp(0.0, 1.0),
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      record.goalReached
                          ? const Color(0xFF4CAF50)
                          : _waterColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
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
      'dez',
    ];
    return months[month - 1];
  }
}

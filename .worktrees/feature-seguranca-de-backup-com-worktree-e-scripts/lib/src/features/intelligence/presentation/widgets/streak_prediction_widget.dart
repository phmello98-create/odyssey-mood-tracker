import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../domain/models/prediction.dart';

/// Widget para exibir previsão de streak
class StreakPredictionWidget extends StatefulWidget {
  final String habitName;
  final int currentStreak;
  final Prediction? streakPrediction;
  final List<bool> last7Days;
  final VoidCallback? onProtect;
  final VoidCallback? onViewHabit;

  const StreakPredictionWidget({
    super.key,
    required this.habitName,
    required this.currentStreak,
    this.streakPrediction,
    required this.last7Days,
    this.onProtect,
    this.onViewHabit,
  });

  @override
  State<StreakPredictionWidget> createState() => _StreakPredictionWidgetState();
}

class _StreakPredictionWidgetState extends State<StreakPredictionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pulsa se há risco alto
    if (widget.streakPrediction?.isHighRisk == true) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAtRisk = widget.streakPrediction?.isHighRisk == true &&
        widget.streakPrediction?.type == PredictionType.streakBreak;
    final riskProbability = widget.streakPrediction?.probability ?? 0.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isAtRisk ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAtRisk
                    ? [
                        Colors.orange.shade50,
                        Colors.red.shade50,
                      ]
                    : [
                        colorScheme.surface,
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAtRisk
                    ? Colors.orange.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: isAtRisk ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAtRisk
                      ? Colors.orange.withValues(alpha: 0.15)
                      : colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 12,
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
                    _buildStreakIcon(colorScheme, isAtRisk),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.habitName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '🔥 ${widget.currentStreak} dias',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              if (isAtRisk) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'EM RISCO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.onViewHabit != null)
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: widget.onViewHabit,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Histórico dos últimos 7 dias
                _buildWeekHistory(colorScheme),

                if (widget.streakPrediction != null) ...[
                  const SizedBox(height: 20),
                  _buildPredictionInfo(colorScheme, riskProbability),
                ],

                if (isAtRisk && widget.onProtect != null) ...[
                  const SizedBox(height: 16),
                  _buildProtectButton(colorScheme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakIcon(ColorScheme colorScheme, bool isAtRisk) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isAtRisk
                  ? [Colors.orange, Colors.red]
                  : [Colors.orange.shade400, Colors.deepOrange.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isAtRisk ? Colors.red : Colors.orange)
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            '🔥',
            style: TextStyle(fontSize: 28),
          ),
        ),
        if (isAtRisk)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekHistory(ColorScheme colorScheme) {
    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final today = DateTime.now().weekday - 1;

    // Reorganizar para começar 7 dias atrás
    final reorderedDays = <int>[];
    for (int i = 6; i >= 0; i--) {
      reorderedDays.add((today - i + 7) % 7);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos 7 dias',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final completed = index < widget.last7Days.length
                ? widget.last7Days[index]
                : false;
            final isToday = index == 6;
            final dayIndex = reorderedDays[index];

            return Column(
              children: [
                Text(
                  weekdays[dayIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 18,
                    color: completed
                        ? Colors.green
                        : Colors.red.withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPredictionInfo(ColorScheme colorScheme, double probability) {
    final prediction = widget.streakPrediction!;
    final isRisk = prediction.type == PredictionType.streakBreak;
    final color = isRisk ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRisk
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prediction.typeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              _buildProbabilityIndicator(probability, color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prediction.reasoning,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityIndicator(double probability, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: probability,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(probability * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          widget.onProtect?.call();
        },
        icon: const Icon(Icons.shield_rounded, size: 18),
        label: const Text('Proteger Streak'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Lista de previsões de streak
class StreakPredictionsList extends StatelessWidget {
  final List<StreakPredictionItem> predictions;
  final void Function(StreakPredictionItem)? onItemTap;

  const StreakPredictionsList({
    super.key,
    required this.predictions,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return _EmptyPredictionsState();
    }

    // Ordenar por risco (maiores riscos primeiro)
    final sorted = List<StreakPredictionItem>.from(predictions)
      ..sort((a, b) => (b.prediction?.probability ?? 0)
          .compareTo(a.prediction?.probability ?? 0));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sorted[index];
        return StreakPredictionCard(
          item: item,
          onTap: () => onItemTap?.call(item),
        );
      },
    );
  }
}

/// Item de previsão de streak
class StreakPredictionItem {
  final String habitId;
  final String habitName;
  final String habitIcon;
  final int currentStreak;
  final Prediction? prediction;
  final List<bool> last7Days;

  StreakPredictionItem({
    required this.habitId,
    required this.habitName,
    required this.habitIcon,
    required this.currentStreak,
    this.prediction,
    required this.last7Days,
  });
}

/// Card compacto de previsão de streak
class StreakPredictionCard extends StatelessWidget {
  final StreakPredictionItem item;
  final VoidCallback? onTap;

  const StreakPredictionCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAtRisk = item.prediction?.isHighRisk == true &&
        item.prediction?.type == PredictionType.streakBreak;
    final probability = item.prediction?.probability ?? 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAtRisk
                ? Colors.orange.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isAtRisk ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAtRisk
                    ? Colors.orange.withValues(alpha: 0.15)
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.habitIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.habitName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.currentStreak} dias',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (isAtRisk) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(probability * 100).toStringAsFixed(0)}% risco',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Mini histórico
            Row(
              children: List.generate(
                math.min(3, item.last7Days.length),
                (index) {
                  final completed = item.last7Days[
                      item.last7Days.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: completed
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 12,
                        color: completed
                            ? Colors.green
                            : Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ).reversed.toList(),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPredictionsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma previsão de streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione hábitos para gerar previsões',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

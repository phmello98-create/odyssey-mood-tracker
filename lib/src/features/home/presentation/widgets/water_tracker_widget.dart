import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/water_tracker/data/water_tracker_provider.dart';
import 'package:odyssey/src/features/water_tracker/domain/water_record.dart';
import 'package:odyssey/src/features/water_tracker/presentation/water_history_screen.dart';
import 'package:odyssey/src/features/home/presentation/widgets/modern_home_card.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Widget de Water Tracker para a Home
/// Permite marcar copos de água bebidos durante o dia
class WaterTrackerWidget extends ConsumerWidget {
  const WaterTrackerWidget({super.key});

  static const Color _waterColor = Color(0xFF42A5F5);
  static const Color _waterColorDark = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waterTrackerProvider);
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    if (state.isLoading && state.record == null) {
      return const ModernHomeCard(
        accentColor: _waterColor,
        child: Center(
          child: SizedBox(
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final record = state.record;
    if (record == null) {
      return const SizedBox.shrink();
    }

    final progress = record.progress.clamp(0.0, 1.0);
    final isComplete = record.goalReached;

    return ModernHomeCard(
      accentColor: _waterColor,
      enableGlow: isComplete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ModernCardHeader(
            icon: Icons.water_drop_rounded,
            title: l10n.waterTrackerTitle,
            color: _waterColor,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de histórico
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WaterHistoryScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _waterColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: _waterColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _WaterSettingsButton(record: record),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contador principal
          _WaterCounter(
            glassesCount: record.glassesCount,
            goalGlasses: record.goalGlasses,
            glassSizeMl: record.glassSizeMl,
            isComplete: isComplete,
          ),
          const SizedBox(height: 16),

          // Barra de progresso
          _WaterProgressBar(progress: progress, isComplete: isComplete),
          const SizedBox(height: 12),

          // Mini gráfico semanal
          const _MiniWeekChart(),
          const SizedBox(height: 16),

          // Botões de ação
          Row(
            children: [
              // Botão remover
              _WaterActionButton(
                icon: Icons.remove_rounded,
                onTap: record.glassesCount > 0
                    ? () {
                        HapticFeedback.lightImpact();
                        SoundService().playTap();
                        ref.read(waterTrackerProvider.notifier).removeGlass();
                      }
                    : null,
                color: colors.error,
              ),
              const SizedBox(width: 12),

              // Botão adicionar (principal)
              Expanded(
                child: _AddWaterButton(
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    final wasComplete = record.goalReached;
                    await ref.read(waterTrackerProvider.notifier).addGlass();

                    // Som especial se completou a meta
                    if (!wasComplete &&
                        ref.read(waterTrackerProvider).record?.goalReached ==
                            true) {
                      SoundService().playSuccess();
                    } else {
                      SoundService().playTap();
                    }
                  },
                  glassSizeMl: record.glassSizeMl,
                ),
              ),
            ],
          ),

          // Status/Mensagem
          if (isComplete) ...[
            const SizedBox(height: 12),
            _CompletionBadge(totalMl: record.totalMl),
          ] else if (record.glassesCount > 0) ...[
            const SizedBox(height: 12),
            _RemainingInfo(
              remainingGlasses: record.remainingGlasses,
              remainingMl: record.remainingMl,
            ),
          ],
        ],
      ),
    );
  }
}

/// Contador central de copos
class _WaterCounter extends StatelessWidget {
  final int glassesCount;
  final int goalGlasses;
  final int glassSizeMl;
  final bool isComplete;

  const _WaterCounter({
    required this.glassesCount,
    required this.goalGlasses,
    required this.glassSizeMl,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalMl = glassesCount * glassSizeMl;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WaterTrackerWidget._waterColor.withValues(alpha: 0.08),
            WaterTrackerWidget._waterColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WaterTrackerWidget._waterColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone com animação de ondas
          _AnimatedWaterDrop(isComplete: isComplete),
          const SizedBox(width: 16),

          // Números
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$glassesCount',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: isComplete
                          ? const Color(0xFF4CAF50)
                          : WaterTrackerWidget._waterColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    ' / $goalGlasses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ' ${l10n.waterGlasses}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${totalMl}ml / ${goalGlasses * glassSizeMl}ml',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gota animada
class _AnimatedWaterDrop extends StatefulWidget {
  final bool isComplete;

  const _AnimatedWaterDrop({required this.isComplete});

  @override
  State<_AnimatedWaterDrop> createState() => _AnimatedWaterDropState();
}

class _AnimatedWaterDropState extends State<_AnimatedWaterDrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isComplete) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedWaterDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isComplete && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isComplete && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isComplete ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isComplete
                      ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                      : [
                          WaterTrackerWidget._waterColor,
                          WaterTrackerWidget._waterColorDark,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.isComplete
                    ? Icons.check_circle_rounded
                    : Icons.water_drop_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Barra de progresso com efeito de água
class _WaterProgressBar extends StatelessWidget {
  final double progress;
  final bool isComplete;

  const _WaterProgressBar({required this.progress, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Barra de progresso animada
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isComplete
                            ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                            : [
                                WaterTrackerWidget._waterColorDark,
                                WaterTrackerWidget._waterColor,
                              ],
                      ),
                    ),
                  ),
                ),
                // Efeito de brilho
                if (progress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isComplete
                ? const Color(0xFF4CAF50)
                : WaterTrackerWidget._waterColor,
          ),
        ),
      ],
    );
  }
}

/// Botão de ação (+ ou -)
class _WaterActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _WaterActionButton({
    required this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? color.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: isEnabled ? color : Colors.grey, size: 24),
      ),
    );
  }
}

/// Botão principal de adicionar água
class _AddWaterButton extends StatefulWidget {
  final VoidCallback onTap;
  final int glassSizeMl;

  const _AddWaterButton({required this.onTap, required this.glassSizeMl});

  @override
  State<_AddWaterButton> createState() => _AddWaterButtonState();
}

class _AddWaterButtonState extends State<_AddWaterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      WaterTrackerWidget._waterColor,
                      WaterTrackerWidget._waterColorDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.waterAddGlass} (${widget.glassSizeMl}ml)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Badge de conclusão
class _CompletionBadge extends StatelessWidget {
  final int totalMl;

  const _CompletionBadge({required this.totalMl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFF4CAF50),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${l10n.waterGoalReached} 🎉 (${totalMl}ml)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info de copos restantes
class _RemainingInfo extends StatelessWidget {
  final int remainingGlasses;
  final int remainingMl;

  const _RemainingInfo({
    required this.remainingGlasses,
    required this.remainingMl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.waterRemaining(remainingGlasses, remainingMl),
      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
    );
  }
}

/// Botão de configurações do water tracker
class _WaterSettingsButton extends ConsumerWidget {
  final dynamic record;

  const _WaterSettingsButton({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSettingsDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: WaterTrackerWidget._waterColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: WaterTrackerWidget._waterColor,
          size: 18,
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    int goalGlasses = record.goalGlasses;
    int glassSizeMl = record.glassSizeMl;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.settings_rounded,
                        color: WaterTrackerWidget._waterColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.waterSettings,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meta de copos
                  Text(
                    l10n.waterGoalLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: goalGlasses > 1
                            ? () => setState(() => goalGlasses--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: WaterTrackerWidget._waterColor,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: WaterTrackerWidget._waterColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$goalGlasses ${l10n.waterGlasses}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: goalGlasses < 20
                            ? () => setState(() => goalGlasses++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: WaterTrackerWidget._waterColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tamanho do copo
                  Text(
                    l10n.waterGlassSizeLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [150, 200, 250, 300, 350, 500].map((size) {
                      final isSelected = glassSizeMl == size;
                      return GestureDetector(
                        onTap: () => setState(() => glassSizeMl = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? WaterTrackerWidget._waterColor
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${size}ml',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.waterTotalGoal(goalGlasses * glassSizeMl),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(waterTrackerProvider.notifier)
                                .resetToday();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          child: Text(l10n.waterReset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(waterTrackerProvider.notifier)
                                .updateGoal(goalGlasses);
                            ref
                                .read(waterTrackerProvider.notifier)
                                .updateGlassSize(glassSizeMl);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WaterTrackerWidget._waterColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Mini gráfico semanal de consumo de água
class _MiniWeekChart extends ConsumerWidget {
  const _MiniWeekChart();

  static const Color _waterColor = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final repository = ref.watch(waterTrackerRepositoryProvider);

    return FutureBuilder<List<WaterRecord>>(
      future: repository.getWeekRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final records = snapshot.data!;
        final maxGlasses = records
            .map((r) => r.goalGlasses)
            .reduce((a, b) => a > b ? a : b);
        final today = DateTime.now();
        final weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

        // Criar mapa de registros por data
        final recordMap = <String, WaterRecord>{};
        for (final record in records) {
          recordMap[record.id] = record;
        }

        // Gerar os últimos 7 dias
        final days = List.generate(7, (i) {
          return today.subtract(Duration(days: 6 - i));
        });

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Últimos 7 dias',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.asMap().entries.map((entry) {
                    final i = entry.key;
                    final day = entry.value;
                    final dateId =
                        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final record = recordMap[dateId];
                    final glasses = record?.glassesCount ?? 0;
                    final isToday =
                        day.day == today.day &&
                        day.month == today.month &&
                        day.year == today.year;
                    final goalReached = record?.goalReached ?? false;
                    final progress = maxGlasses > 0
                        ? (glasses / maxGlasses).clamp(0.0, 1.0)
                        : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 3,
                          right: i == 6 ? 0 : 3,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Barra
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height:
                                  28 * progress + 4, // Reduzido de 30 para 28
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: goalReached
                                      ? [
                                          const Color(0xFF4CAF50),
                                          const Color(0xFF81C784),
                                        ]
                                      : [_waterColor, const Color(0xFF64B5F6)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isToday
                                    ? [
                                        BoxShadow(
                                          color: _waterColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 3), // Reduzido de 4 para 3
                            // Dia
                            Text(
                              weekDays[day.weekday - 1],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? _waterColor
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

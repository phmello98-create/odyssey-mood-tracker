import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'modern_home_card.dart';

class StreakWidget extends ConsumerStatefulWidget {
  const StreakWidget({super.key});

  @override
  ConsumerState<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends ConsumerState<StreakWidget>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _flameController;
  late AnimationController _pulseController;
  int _currentStreak = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final box = await Hive.openBox('gamification');
      final repo = GamificationRepository(box);
      final stats = repo.getStats();
      setState(() {
        _currentStreak = stats.currentStreak;
        _longestStreak = stats.longestStreak;
      });
      _countController.forward();
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _flameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Cores do gradiente de fogo
    const fireOrange = Color(0xFFFF9500);
    const fireRed = Color(0xFFFF3B30);
    const fireYellow = Color(0xFFFFCC00);

    return ModernHomeCard(
      accentColor: fireOrange,
      enableGlow: _currentStreak > 0,
      gradientColors: [
        fireOrange.withValues(alpha: 0.08),
        fireRed.withValues(alpha: 0.04),
      ],
      onTap: () => HapticFeedback.lightImpact(),
      child: Row(
        children: [
          // Ícone de fogo animado
          AnimatedBuilder(
            animation: Listenable.merge([_flameController, _pulseController]),
            builder: (context, child) {
              final flameScale = 1.0 + (_flameController.value * 0.1);
              final pulseOpacity = 0.15 + (_pulseController.value * 0.1);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow pulsante atrás
                  if (_currentStreak > 0)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            fireOrange.withValues(alpha: pulseOpacity),
                            fireOrange.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  // Container do ícone
                  Transform.scale(
                    scale: _currentStreak > 0 ? flameScale : 1.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [fireOrange, fireRed],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: fireOrange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Partículas de fogo simuladas
                          if (_currentStreak > 0)
                            ...List.generate(3, (i) {
                              return Positioned(
                                top: 8 + (i * 4.0),
                                child: Transform.translate(
                                  offset: Offset(
                                    math.sin(_flameController.value * math.pi +
                                            i) *
                                        2,
                                    -_flameController.value * 4,
                                  ),
                                  child: Opacity(
                                    opacity:
                                        (1 - _flameController.value) * 0.5,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: fireYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),

          // Informações do streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // Número animado
                    AnimatedBuilder(
                      animation: _countController,
                      builder: (context, child) {
                        final progress = Curves.elasticOut
                            .transform(_countController.value.clamp(0.0, 1.0));
                        return Text(
                          '${(_currentStreak * progress).round()}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: fireOrange,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.days,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Recorde com ícone
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: fireYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 12,
                        color: fireYellow.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.recordStreak(_longestStreak),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Indicadores dos últimos dias
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDayIndicator(l10n.todayShort, true, fireOrange, 0),
              const SizedBox(height: 6),
              _buildDayIndicator(
                  l10n.yesterdayShort, _currentStreak > 0, fireOrange, 1),
              const SizedBox(height: 6),
              _buildDayIndicator(
                  l10n.dayBeforeShort, _currentStreak > 1, fireOrange, 2),
              const SizedBox(height: 6),
              _buildDayIndicator(
                  l10n.threeDaysAgoShort, _currentStreak > 2, fireOrange, 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(
      String label, bool isActive, Color color, int index) {
    final colors = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive
                  ? null
                  : colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3 * value),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

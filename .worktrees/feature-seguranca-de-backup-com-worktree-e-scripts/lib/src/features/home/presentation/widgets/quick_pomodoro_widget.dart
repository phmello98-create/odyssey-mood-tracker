import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/providers/timer_provider.dart';

class QuickPomodoroWidget extends ConsumerStatefulWidget {
  const QuickPomodoroWidget({super.key});

  @override
  ConsumerState<QuickPomodoroWidget> createState() => _QuickPomodoroWidgetState();
}

class _QuickPomodoroWidgetState extends ConsumerState<QuickPomodoroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const pomodoroColor = Color(0xFFFF6B6B);
    const accentColor = Color(0xFFFF8E53);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pomodoroColor.withOpacity(0.15 + _pulseAnimation.value * 0.03),
                accentColor.withOpacity(0.08),
                Colors.black.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: pomodoroColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: pomodoroColor.withOpacity(0.15 + _pulseAnimation.value * 0.1),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com timer animado
              Row(
                children: [
                  // Ícone com glow pulsante
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [pomodoroColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: pomodoroColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.timer_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'FOCUS MODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: pomodoroColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'PRONTO',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.pomodoro,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Emoji de tomate animado
                  Transform.scale(
                    scale: 0.9 + (_pulseAnimation.value * 0.1),
                    child: const Text('🍅', style: TextStyle(fontSize: 28)),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Timer options com design premium
              Row(
                children: [
                  _buildTimerOption(context, 15, pomodoroColor, accentColor),
                  const SizedBox(width: 10),
                  _buildTimerOption(context, 25, pomodoroColor, accentColor),
                  const SizedBox(width: 10),
                  _buildTimerOption(context, 45, pomodoroColor, accentColor),
                  const SizedBox(width: 10),
                  _buildTimerOption(context, 60, pomodoroColor, accentColor),
                ],
              ),
              
              const SizedBox(height: 14),
              
              // Hint text com ícone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.tapToStartFocusTimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, int minutes, Color primary, Color accent) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedMinutes == minutes;
    final isRecommended = minutes == 25;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _selectedMinutes = minutes);
          
          // Start timer after a brief visual feedback
          Future.delayed(const Duration(milliseconds: 150), () {
            ref.read(timerProvider.notifier).updatePomodoroSettings(
              focusDuration: Duration(minutes: minutes),
              openPomodoroScreen: true,
            );
            ref.read(navigationProvider.notifier).goToTimer();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            top: isRecommended && !isSelected ? 16 : 14,
            bottom: 14,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [primary, accent])
                : null,
            color: isSelected ? null : colors.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent 
                  : primary.withOpacity(isRecommended ? 0.5 : 0.2),
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Badge de recomendado (dentro do container agora)
              if (isRecommended && !isSelected)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primary, accent]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '★ TOP',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.min,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? Colors.white.withOpacity(0.8) 
                      : colors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

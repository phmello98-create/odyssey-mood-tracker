import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/constants/app_theme.dart';

class QuickPomodoroWidget extends ConsumerStatefulWidget {
  const QuickPomodoroWidget({super.key});

  @override
  ConsumerState<QuickPomodoroWidget> createState() =>
      _QuickPomodoroWidgetState();
}

class _QuickPomodoroWidgetState extends ConsumerState<QuickPomodoroWidget> {
  int? _selectedMinutes;

  void _startPomodoro(int minutes) {
    ref
        .read(timerProvider.notifier)
        .updatePomodoroSettings(
          focusDuration: Duration(minutes: minutes),
          openPomodoroScreen: true,
        );
    ref.read(navigationProvider.notifier).goToTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timerState = ref.watch(timerProvider);
    final isRunning = timerState.isPomodoroMode && timerState.isRunning;
    const pomodoroColor = Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: pomodoroColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pomodoro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      isRunning ? 'Sessão em andamento' : 'Foco intenso',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator or emoji
              if (isRunning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: WellnessColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: WellnessColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: WellnessColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: WellnessColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text('🍅', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),

          // Timer options
          Row(
            children: [
              _buildTimeOption(15, colors),
              const SizedBox(width: 8),
              _buildTimeOption(25, colors, isRecommended: true),
              const SizedBox(width: 8),
              _buildTimeOption(45, colors),
              const SizedBox(width: 8),
              _buildTimeOption(60, colors),
            ],
          ),

          // Start button (when time is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _selectedMinutes != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _startPomodoro(_selectedMinutes!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pomodoroColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Iniciar $_selectedMinutes min',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: colors.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Toque para selecionar, duplo para iniciar',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(
    int minutes,
    ColorScheme colors, {
    bool isRecommended = false,
  }) {
    final isSelected = _selectedMinutes == minutes;
    const pomodoroColor = Color(0xFFFF6B6B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedMinutes = minutes);
        },
        onDoubleTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _selectedMinutes = minutes);
          Future.delayed(const Duration(milliseconds: 50), () {
            _startPomodoro(minutes);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? pomodoroColor.withOpacity(0.15)
                : colors.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? pomodoroColor.withOpacity(0.5)
                  : (isRecommended
                        ? pomodoroColor.withOpacity(0.3)
                        : Colors.transparent),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecommended && !isSelected)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pomodoroColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TOP',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? pomodoroColor : colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'min',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? pomodoroColor.withOpacity(0.8)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

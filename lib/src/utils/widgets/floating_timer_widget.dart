import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';

/// Widget flutuante que mostra o timer ativo quando o usuário sai da tela do timer
class FloatingTimerWidget extends ConsumerStatefulWidget {
  const FloatingTimerWidget({super.key});

  @override
  ConsumerState<FloatingTimerWidget> createState() =>
      _FloatingTimerWidgetState();
}

class _FloatingTimerWidgetState extends ConsumerState<FloatingTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isExpanded = false;
  bool _isDragging = false;
  Offset _position = const Offset(16, 100);

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final currentNav = ref.watch(navigationProvider);

    // Só mostra se timer ativo E não está na tela do timer (index 3)
    final shouldShow =
        (timerState.isRunning || timerState.isPaused) && currentNav != 3;

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final isPomodoro = timerState.isPomodoroMode;
    final isPaused = timerState.isPaused;
    final isBreak = timerState.isPomodoroBreak;

    // Cores
    final pomodoroColor = isBreak
        ? const Color(0xFF667EEA)
        : const Color(0xFFFF6B6B);
    const freeTimerColor = Color(0xFF07E092);
    final mainColor = isPomodoro ? pomodoroColor : freeTimerColor;

    // Tempo
    final timeDisplay = isPomodoro
        ? _formatDuration(timerState.pomodoroTimeLeft)
        : _formatDuration(timerState.elapsed);

    // Task name
    final taskName = timerState.taskName ?? (isPomodoro ? 'Pomodoro' : 'Timer');

    return Positioned(
      right: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx - details.delta.dx,
              _position.dy + details.delta.dy,
            );
            // Limitar posição
            final size = MediaQuery.of(context).size;
            _position = Offset(
              _position.dx.clamp(0, size.width - 80),
              _position.dy.clamp(50, size.height - 150),
            );
          });
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        onDoubleTap: () {
          HapticFeedback.mediumImpact();
          ref.read(navigationProvider.notifier).goToTimer();
        },
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging
                  ? 1.1
                  : (isPaused ? 1.0 : _bounceAnimation.value),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(maxWidth: _isExpanded ? 200 : 150),
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 14 : 10,
                vertical: _isExpanded ? 10 : 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainColor, mainColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(_isExpanded ? 16 : 24),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isExpanded
                  ? _buildExpandedContent(
                      timeDisplay,
                      taskName,
                      isPomodoro,
                      isPaused,
                      isBreak,
                    )
                  : _buildCollapsedContent(
                      timeDisplay,
                      isPomodoro,
                      isPaused,
                      isBreak,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(
    String timeDisplay,
    bool isPomodoro,
    bool isPaused,
    bool isBreak,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isPomodoro ? (isBreak ? '☕' : '🍅') : '⏱️',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 6),
        Text(
          timeDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (isPaused) ...[
          const SizedBox(width: 4),
          const Icon(Icons.pause, color: Colors.white70, size: 12),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(
    String timeDisplay,
    String taskName,
    bool isPomodoro,
    bool isPaused,
    bool isBreak,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPomodoro ? (isBreak ? '☕' : '🍅') : '⏱️',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    taskName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isPaused) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PAUSADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Botões
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                final notifier = ref.read(timerProvider.notifier);
                if (isPaused) {
                  isPomodoro
                      ? notifier.resumePomodoro()
                      : notifier.resumeTimer();
                } else {
                  isPomodoro ? notifier.pausePomodoro() : notifier.pauseTimer();
                }
              },
            ),
            const SizedBox(width: 6),
            _buildControlButton(
              icon: Icons.stop_rounded,
              onTap: () {
                HapticFeedback.mediumImpact();
                final notifier = ref.read(timerProvider.notifier);
                isPomodoro ? notifier.resetPomodoro() : notifier.resetTimer();
              },
              isDestructive: true,
            ),
            const SizedBox(width: 6),
            _buildControlButton(
              icon: Icons.open_in_full_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(navigationProvider.notifier).goToTimer();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

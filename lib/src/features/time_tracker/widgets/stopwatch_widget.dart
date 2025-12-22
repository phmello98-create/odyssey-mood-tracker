import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Estado do Cronômetro (independente do Timer principal)
class StopwatchState {
  final bool isRunning;
  final bool isPaused;
  final DateTime? startTime;
  final Duration elapsed;
  final Duration pausedElapsed;
  final List<Duration> laps;

  // Countdown Timer
  final bool isCountdownMode;
  final Duration countdownTotal;
  final Duration countdownTimeLeft;
  final bool countdownComplete;

  const StopwatchState({
    this.isRunning = false,
    this.isPaused = false,
    this.startTime,
    this.elapsed = Duration.zero,
    this.pausedElapsed = Duration.zero,
    this.laps = const [],
    this.isCountdownMode = false,
    this.countdownTotal = Duration.zero,
    this.countdownTimeLeft = Duration.zero,
    this.countdownComplete = false,
  });

  StopwatchState copyWith({
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
    Duration? elapsed,
    Duration? pausedElapsed,
    List<Duration>? laps,
    bool? isCountdownMode,
    Duration? countdownTotal,
    Duration? countdownTimeLeft,
    bool? countdownComplete,
  }) {
    return StopwatchState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      pausedElapsed: pausedElapsed ?? this.pausedElapsed,
      laps: laps ?? this.laps,
      isCountdownMode: isCountdownMode ?? this.isCountdownMode,
      countdownTotal: countdownTotal ?? this.countdownTotal,
      countdownTimeLeft: countdownTimeLeft ?? this.countdownTimeLeft,
      countdownComplete: countdownComplete ?? this.countdownComplete,
    );
  }
}

/// Notifier para o Cronômetro
class StopwatchNotifier extends StateNotifier<StopwatchState> {
  Timer? _timer;

  StopwatchNotifier() : super(const StopwatchState());

  /// Inicia o cronômetro (modo progressivo)
  void start() {
    if (state.isRunning) return;

    _timer?.cancel();

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isCountdownMode: false,
      startTime: DateTime.now(),
      countdownComplete: false,
    );

    _startTicker();
  }

  /// Inicia o countdown (modo regressivo)
  void startCountdown(Duration duration) {
    if (state.isRunning) return;

    _timer?.cancel();

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isCountdownMode: true,
      countdownTotal: duration,
      countdownTimeLeft: duration,
      startTime: DateTime.now(),
      countdownComplete: false,
    );

    _startCountdownTicker();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.isRunning && !state.isPaused && state.startTime != null) {
        final newElapsed =
            state.pausedElapsed + DateTime.now().difference(state.startTime!);
        state = state.copyWith(elapsed: newElapsed);
      }
    });
  }

  void _startCountdownTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && !state.isPaused && state.isCountdownMode) {
        final newTimeLeft =
            state.countdownTimeLeft - const Duration(seconds: 1);

        if (newTimeLeft.inSeconds <= 0) {
          _timer?.cancel();
          state = state.copyWith(
            isRunning: false,
            isPaused: false,
            countdownTimeLeft: Duration.zero,
            countdownComplete: true,
          );
          _onCountdownComplete();
        } else {
          state = state.copyWith(countdownTimeLeft: newTimeLeft);
        }
      }
    });
  }

  void _onCountdownComplete() {
    HapticFeedback.heavyImpact();
    soundService.playSuccess();

    // Mostrar notificação
    NotificationService.instance.showTimerComplete(
      'Cronômetro',
      state.countdownTotal,
    );
  }

  /// Pausa o cronômetro
  void pause() {
    if (!state.isRunning || state.isPaused) return;

    _timer?.cancel();

    final currentElapsed = state.startTime != null
        ? state.pausedElapsed + DateTime.now().difference(state.startTime!)
        : state.elapsed;

    state = state.copyWith(
      isRunning: false,
      isPaused: true,
      elapsed: currentElapsed,
      pausedElapsed: currentElapsed,
    );
  }

  /// Retoma o cronômetro
  void resume() {
    if (!state.isPaused) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: DateTime.now(),
    );

    if (state.isCountdownMode) {
      _startCountdownTicker();
    } else {
      _startTicker();
    }
  }

  /// Para e reseta o cronômetro
  void stop() {
    _timer?.cancel();
    state = const StopwatchState();
  }

  /// Adiciona uma volta
  void addLap() {
    if (!state.isRunning && !state.isPaused) return;
    if (state.isCountdownMode) return; // Sem voltas no countdown

    final currentElapsed = state.startTime != null
        ? state.pausedElapsed + DateTime.now().difference(state.startTime!)
        : state.elapsed;

    state = state.copyWith(laps: [currentElapsed, ...state.laps]);
  }

  /// Limpa as voltas
  void clearLaps() {
    state = state.copyWith(laps: []);
  }

  /// Define o tempo do countdown (sem iniciar)
  void setCountdownTime(Duration duration) {
    state = state.copyWith(
      countdownTotal: duration,
      countdownTimeLeft: duration,
      isCountdownMode: true,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider do Cronômetro
final stopwatchProvider =
    StateNotifierProvider<StopwatchNotifier, StopwatchState>((ref) {
      return StopwatchNotifier();
    });

/// Widget do Cronômetro atualizado
class StopwatchWidget extends ConsumerStatefulWidget {
  const StopwatchWidget({super.key});

  @override
  ConsumerState<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends ConsumerState<StopwatchWidget> {
  // 0 = Cronômetro (progressivo), 1 = Timer (countdown)
  int _selectedMode = 0;

  // Para o picker de tempo
  int _selectedMinutes = 5;
  int _selectedSeconds = 0;

  @override
  Widget build(BuildContext context) {
    final stopwatchState = ref.watch(stopwatchProvider);
    final stopwatchNotifier = ref.read(stopwatchProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isRunning = stopwatchState.isRunning;
    final isPaused = stopwatchState.isPaused;
    final isCountdownMode = stopwatchState.isCountdownMode;

    // Tempo a exibir
    final displayTime = isCountdownMode
        ? stopwatchState.countdownTimeLeft
        : stopwatchState.elapsed;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Mode Selector
          _buildModeSelector(colorScheme, isRunning, isPaused),

          const SizedBox(height: 20),

          // Timer Display
          _buildTimerDisplay(
            context,
            displayTime,
            isRunning,
            isCountdownMode,
            colorScheme,
          ),

          const SizedBox(height: 24),

          // Countdown Time Picker (apenas quando não está rodando e está em modo countdown)
          if (_selectedMode == 1 && !isRunning && !isPaused)
            _buildTimePicker(colorScheme),

          // Countdown complete message
          if (stopwatchState.countdownComplete)
            _buildCompleteMessage(colorScheme, l10n),

          const SizedBox(height: 24),

          // Controls
          _buildControls(
            context,
            isRunning,
            isPaused,
            isCountdownMode,
            stopwatchNotifier,
            colorScheme,
            l10n,
          ),

          const SizedBox(height: 24),

          // Laps List (apenas no modo cronômetro)
          if (_selectedMode == 0)
            _buildLapsList(context, stopwatchState.laps, colorScheme, l10n),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildModeSelector(
    ColorScheme colorScheme,
    bool isRunning,
    bool isPaused,
  ) {
    final isDisabled = isRunning || isPaused;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => setState(() => _selectedMode = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedMode == 0
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: _selectedMode == 0
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant.withOpacity(
                                isDisabled ? 0.4 : 1,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.stopwatch,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedMode == 0
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant.withOpacity(
                                  isDisabled ? 0.4 : 1,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => setState(() => _selectedMode = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedMode == 1
                        ? colorScheme.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: _selectedMode == 1
                            ? colorScheme.onSecondary
                            : colorScheme.onSurfaceVariant.withOpacity(
                                isDisabled ? 0.4 : 1,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Timer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedMode == 1
                              ? colorScheme.onSecondary
                              : colorScheme.onSurfaceVariant.withOpacity(
                                  isDisabled ? 0.4 : 1,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'Definir tempo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes
              _buildTimePickerColumn(
                value: _selectedMinutes,
                label: 'min',
                maxValue: 99,
                onChanged: (v) => setState(() => _selectedMinutes = v),
                colorScheme: colorScheme,
              ),

              Text(
                ':',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),

              // Seconds
              _buildTimePickerColumn(
                value: _selectedSeconds,
                label: 'seg',
                maxValue: 59,
                onChanged: (v) => setState(() => _selectedSeconds = v),
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick presets
          Wrap(
            spacing: 8,
            children: [
              _buildPresetChip(
                '1 min',
                const Duration(minutes: 1),
                colorScheme,
              ),
              _buildPresetChip(
                '5 min',
                const Duration(minutes: 5),
                colorScheme,
              ),
              _buildPresetChip(
                '10 min',
                const Duration(minutes: 10),
                colorScheme,
              ),
              _buildPresetChip(
                '15 min',
                const Duration(minutes: 15),
                colorScheme,
              ),
              _buildPresetChip(
                '30 min',
                const Duration(minutes: 30),
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerColumn({
    required int value,
    required String label,
    required int maxValue,
    required ValueChanged<int> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => onChanged((value - 1).clamp(0, maxValue)),
              icon: Icon(
                Icons.remove_circle_outline,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged((value + 1).clamp(0, maxValue)),
              icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    String label,
    Duration duration,
    ColorScheme colorScheme,
  ) {
    final isSelected =
        _selectedMinutes == duration.inMinutes && _selectedSeconds == 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMinutes = duration.inMinutes;
          _selectedSeconds = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteMessage(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Text(
            'Timer concluído! 🎉',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(
    BuildContext context,
    Duration elapsed,
    bool isRunning,
    bool isCountdownMode,
    ColorScheme colorScheme,
  ) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final milliseconds = (elapsed.inMilliseconds.remainder(1000) / 10).floor();

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final accentColor = isCountdownMode
        ? colorScheme.secondary
        : colorScheme.primary;

    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isRunning ? 0.2 : 0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(isRunning ? 0.5 : 0.1),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress
          if (!isCountdownMode)
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: (seconds + (milliseconds / 100)) / 60,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(accentColor),
                backgroundColor: colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
              ),
            )
          else
            SizedBox(
              width: 240,
              height: 240,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 1.0,
                  end: ref.read(stopwatchProvider).countdownTotal.inSeconds > 0
                      ? elapsed.inSeconds /
                            ref.read(stopwatchProvider).countdownTotal.inSeconds
                      : 0.0,
                ),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation(accentColor),
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                  );
                },
              ),
            ),

          // Time Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hours > 0)
                Text(
                  twoDigits(hours),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${twoDigits(minutes)}:${twoDigits(seconds)}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!isCountdownMode) ...[
                    const SizedBox(width: 4),
                    Text(
                      twoDigits(milliseconds),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                isCountdownMode
                    ? 'Timer'
                    : AppLocalizations.of(context)!.stopwatch,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    bool isRunning,
    bool isPaused,
    bool isCountdownMode,
    StopwatchNotifier notifier,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final accentColor = _selectedMode == 1
        ? colorScheme.secondary
        : colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botão Reset/Lap
        _buildRoundButton(
          icon: (isRunning && _selectedMode == 0)
              ? Icons.flag_rounded
              : Icons.refresh_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            if (isRunning && _selectedMode == 0) {
              notifier.addLap();
            } else {
              notifier.stop();
            }
          },
          label: (isRunning && _selectedMode == 0) ? l10n.lap : l10n.reset,
          color: colorScheme.surfaceContainerHighest,
          iconColor: colorScheme.onSurfaceVariant,
        ),

        // Botão Play/Pause
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (isRunning) {
              notifier.pause();
            } else if (isPaused) {
              notifier.resume();
            } else {
              if (_selectedMode == 1) {
                // Countdown mode
                final duration = Duration(
                  minutes: _selectedMinutes,
                  seconds: _selectedSeconds,
                );
                if (duration.inSeconds > 0) {
                  notifier.startCountdown(duration);
                }
              } else {
                // Stopwatch mode
                notifier.start();
              }
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? colorScheme.errorContainer : accentColor,
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? colorScheme.error : accentColor)
                      .withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: isRunning
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimary,
            ),
          ),
        ),

        // Botão Stop
        _buildRoundButton(
          icon: Icons.stop_rounded,
          onTap: () {
            HapticFeedback.mediumImpact();
            notifier.stop();
          },
          label: l10n.stop,
          color: colorScheme.surfaceContainerHighest,
          iconColor: colorScheme.onSurfaceVariant,
          isEnabled: isRunning || isPaused,
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    required Color color,
    required Color iconColor,
    bool isEnabled = true,
  }) {
    return Column(
      children: [
        Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: GestureDetector(
            onTap: isEnabled ? onTap : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(icon, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: iconColor.withOpacity(isEnabled ? 0.7 : 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildLapsList(
    BuildContext context,
    List<Duration> laps,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    if (laps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.noLaps,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.laps,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...laps.asMap().entries.map((entry) {
          final index = entry.key;
          final lapTime = entry.value;
          final lapNumber = laps.length - index;

          Duration? diff;
          if (index < laps.length - 1) {
            diff = lapTime - laps[index + 1];
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '#$lapNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDuration(lapTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (diff != null)
                      Text(
                        '+${_formatDuration(diff)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = twoDigits(
      (duration.inMilliseconds.remainder(1000) / 10).floor(),
    );

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds.$milliseconds';
    }
    return '$minutes:$seconds.$milliseconds';
  }
}

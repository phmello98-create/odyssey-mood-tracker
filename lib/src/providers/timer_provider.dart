import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/services/foreground_service.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado global do timer que persiste entre mudanças de tela
class TimerState {
  final bool isRunning;
  final bool isPaused;
  final DateTime? startTime;
  final Duration elapsed;
  final Duration pausedElapsed; // Tempo acumulado antes da pausa
  final String? taskName;
  final String? category;
  final String? project;
  final int? iconCode;
  final int? colorValue;

  // Pomodoro
  final bool isPomodoroMode;
  final bool isPomodoroBreak;
  final Duration pomodoroTimeLeft;
  final int pomodoroSessions;
  final Duration pomodoroDuration;

  // Flag para abrir a tela do Pomodoro automaticamente
  final bool shouldOpenPomodoroScreen;

  const TimerState({
    this.isRunning = false,
    this.isPaused = false,
    this.startTime,
    this.elapsed = Duration.zero,
    this.pausedElapsed = Duration.zero,
    this.taskName,
    this.category,
    this.project,
    this.iconCode,
    this.colorValue,
    this.isPomodoroMode = false,
    this.isPomodoroBreak = false,
    this.pomodoroTimeLeft = const Duration(minutes: 25),
    this.pomodoroSessions = 0,
    this.pomodoroDuration = const Duration(minutes: 25),
    this.shouldOpenPomodoroScreen = false,
  });

  TimerState copyWith({
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
    Duration? elapsed,
    Duration? pausedElapsed,
    String? taskName,
    String? category,
    String? project,
    int? iconCode,
    int? colorValue,
    bool? isPomodoroMode,
    bool? isPomodoroBreak,
    Duration? pomodoroTimeLeft,
    int? pomodoroSessions,
    Duration? pomodoroDuration,
    bool? shouldOpenPomodoroScreen,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      pausedElapsed: pausedElapsed ?? this.pausedElapsed,
      taskName: taskName ?? this.taskName,
      category: category ?? this.category,
      project: project ?? this.project,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
      isPomodoroBreak: isPomodoroBreak ?? this.isPomodoroBreak,
      pomodoroTimeLeft: pomodoroTimeLeft ?? this.pomodoroTimeLeft,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shouldOpenPomodoroScreen:
          shouldOpenPomodoroScreen ?? this.shouldOpenPomodoroScreen,
    );
  }

  TimerState reset() {
    return const TimerState();
  }

  /// Serializa para persistência
  Map<String, dynamic> toJson() => {
    'isRunning': isRunning,
    'isPaused': isPaused,
    'startTime': startTime?.toIso8601String(),
    'elapsed': elapsed.inSeconds,
    'pausedElapsed': pausedElapsed.inSeconds,
    'taskName': taskName,
    'category': category,
    'project': project,
    'iconCode': iconCode,
    'colorValue': colorValue,
    'isPomodoroMode': isPomodoroMode,
    'isPomodoroBreak': isPomodoroBreak,
    'pomodoroTimeLeft': pomodoroTimeLeft.inSeconds,
    'pomodoroSessions': pomodoroSessions,
    'pomodoroDuration': pomodoroDuration.inSeconds,
  };

  /// Deserializa da persistência
  factory TimerState.fromJson(Map<String, dynamic> json) {
    return TimerState(
      isRunning: json['isRunning'] ?? false,
      isPaused: json['isPaused'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'])
          : null,
      elapsed: Duration(seconds: json['elapsed'] ?? 0),
      pausedElapsed: Duration(seconds: json['pausedElapsed'] ?? 0),
      taskName: json['taskName'],
      category: json['category'],
      project: json['project'],
      iconCode: json['iconCode'],
      colorValue: json['colorValue'],
      isPomodoroMode: json['isPomodoroMode'] ?? false,
      isPomodoroBreak: json['isPomodoroBreak'] ?? false,
      pomodoroTimeLeft: Duration(seconds: json['pomodoroTimeLeft'] ?? 1500),
      pomodoroSessions: json['pomodoroSessions'] ?? 0,
      pomodoroDuration: Duration(seconds: json['pomodoroDuration'] ?? 1500),
    );
  }
}

/// Notifier que gerencia o estado do timer globalmente
class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  SharedPreferences? _prefs;

  // Configurações do Pomodoro
  Duration pomodoroDuration = const Duration(minutes: 25);
  Duration shortBreakDuration = const Duration(minutes: 5);
  Duration longBreakDuration = const Duration(minutes: 15);
  int pomodoroTotalSessions = 4;

  // Constantes para persistência
  static const String _timerStateKey = 'timer_state_v2';

  TimerNotifier() : super(const TimerState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    // Restaurar estado se o app foi fechado com timer rodando
    await _restoreState();

    // Configurar callbacks de notificação
    _setupNotificationCallbacks();

    // Verificar se há ação pendente de notificação
    await NotificationService.checkPendingAction();
  }

  /// Configura os callbacks para ações de notificação
  void _setupNotificationCallbacks() {
    debugPrint('[TimerNotifier] Setting up notification callbacks');

    NotificationService.onStopTimer = () {
      debugPrint('[TimerNotifier] onStopTimer callback triggered');
      if (state.isPomodoroMode) {
        resetPomodoro();
      } else {
        stopTimer();
      }
    };

    NotificationService.onPauseTimer = () {
      debugPrint('[TimerNotifier] onPauseTimer callback triggered');
      if (state.isPomodoroMode) {
        pausePomodoro();
      } else {
        pauseTimer();
      }
    };

    NotificationService.onResumeTimer = () {
      debugPrint('[TimerNotifier] onResumeTimer callback triggered');
      if (state.isPomodoroMode) {
        resumePomodoro();
      } else {
        resumeTimer();
      }
    };
  }

  /// Reconecta os callbacks - chamado externamente após restauração do app
  void reconnectCallbacks() {
    _setupNotificationCallbacks();
  }

  /// Restaura estado salvo
  Future<void> _restoreState() async {
    final savedState = _prefs?.getString(_timerStateKey);
    if (savedState == null) return;

    try {
      // Parse simples - em produção usar json_encode/decode
      // Por simplicidade, apenas verificamos se havia timer rodando
      // e recalculamos o tempo decorrido

      final wasRunning = _prefs?.getBool('timer_was_running') ?? false;
      final wasPaused = _prefs?.getBool('timer_was_paused') ?? false;
      final startTimeStr = _prefs?.getString('timer_start_time');
      final taskName = _prefs?.getString('timer_task_name');
      final isPomodoroMode = _prefs?.getBool('timer_is_pomodoro') ?? false;
      final pomodoroSecondsLeft = _prefs?.getInt('timer_pomodoro_left') ?? 0;
      final pausedSeconds = _prefs?.getInt('timer_paused_seconds') ?? 0;

      if (wasRunning && startTimeStr != null && taskName != null) {
        final startTime = DateTime.tryParse(startTimeStr);
        if (startTime != null) {
          if (isPomodoroMode) {
            // Calcular tempo restante do pomodoro
            if (!wasPaused) {
              final elapsedSinceStart = DateTime.now().difference(startTime);
              final newTimeLeft =
                  Duration(seconds: pomodoroSecondsLeft) - elapsedSinceStart;

              if (newTimeLeft.inSeconds > 0) {
                state = state.copyWith(
                  isRunning: true,
                  isPaused: false,
                  startTime: startTime,
                  taskName: taskName,
                  isPomodoroMode: true,
                  pomodoroTimeLeft: newTimeLeft,
                  pomodoroDuration: Duration(
                    seconds: _prefs?.getInt('timer_pomodoro_duration') ?? 1500,
                  ),
                );
                _startPomodoroTicker();
                _updateNotification();
              }
            } else {
              // Estava pausado
              state = state.copyWith(
                isRunning: false,
                isPaused: true,
                taskName: taskName,
                isPomodoroMode: true,
                pomodoroTimeLeft: Duration(seconds: pomodoroSecondsLeft),
              );
              _updateNotification();
            }
          } else {
            // Timer livre
            if (!wasPaused) {
              final elapsed =
                  DateTime.now().difference(startTime) +
                  Duration(seconds: pausedSeconds);
              state = state.copyWith(
                isRunning: true,
                isPaused: false,
                startTime: startTime,
                elapsed: elapsed,
                pausedElapsed: Duration(seconds: pausedSeconds),
                taskName: taskName,
              );
              _startTimerTicker();
              _updateNotification();
            } else {
              state = state.copyWith(
                isRunning: false,
                isPaused: true,
                elapsed: Duration(seconds: pausedSeconds),
                pausedElapsed: Duration(seconds: pausedSeconds),
                taskName: taskName,
              );
              _updateNotification();
            }
          }
        }
      }
    } catch (e) {
      // Ignorar erros de restauração
    }
  }

  /// Persiste dados importantes do timer
  Future<void> _persistTimerData() async {
    await _prefs?.setBool('timer_was_running', state.isRunning);
    await _prefs?.setBool('timer_was_paused', state.isPaused);
    await _prefs?.setString(
      'timer_start_time',
      state.startTime?.toIso8601String() ?? '',
    );
    await _prefs?.setString('timer_task_name', state.taskName ?? '');
    await _prefs?.setBool('timer_is_pomodoro', state.isPomodoroMode);
    await _prefs?.setInt(
      'timer_pomodoro_left',
      state.pomodoroTimeLeft.inSeconds,
    );
    await _prefs?.setInt(
      'timer_pomodoro_duration',
      state.pomodoroDuration.inSeconds,
    );
    await _prefs?.setInt('timer_paused_seconds', state.pausedElapsed.inSeconds);
  }

  /// Limpa dados persistidos
  Future<void> _clearPersistedData() async {
    await _prefs?.remove('timer_was_running');
    await _prefs?.remove('timer_was_paused');
    await _prefs?.remove('timer_start_time');
    await _prefs?.remove('timer_task_name');
    await _prefs?.remove('timer_is_pomodoro');
    await _prefs?.remove('timer_pomodoro_left');
    await _prefs?.remove('timer_pomodoro_duration');
    await _prefs?.remove('timer_paused_seconds');
  }

  /// Inicia o timer livre
  void startTimer({
    required String taskName,
    String? category,
    String? project,
    int? iconCode,
    int? colorValue,
  }) {
    _timer?.cancel();

    final now = DateTime.now();
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: now,
      elapsed: Duration.zero,
      pausedElapsed: Duration.zero,
      taskName: taskName,
      category: category,
      project: project,
      iconCode: iconCode,
      colorValue: colorValue,
      isPomodoroMode: false,
    );

    _persistTimerData();
    _showTimerNotification();
    _startTimerTicker();
  }

  /// Inicia o ticker do timer
  void _startTimerTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && !state.isPaused && state.startTime != null) {
        final newElapsed =
            state.pausedElapsed + DateTime.now().difference(state.startTime!);
        state = state.copyWith(elapsed: newElapsed);

        // Atualizar notificação a cada segundo para tempo real
        _updateNotification();

        // Persistir a cada 10 segundos
        if (newElapsed.inSeconds % 10 == 0) {
          _persistTimerData();
        }
      }
    });
  }

  /// Pausa o timer livre
  void pauseTimer() {
    if (!state.isRunning || state.isPaused) return;

    _timer?.cancel();

    // Calcular tempo decorrido até agora
    final currentElapsed = state.startTime != null
        ? state.pausedElapsed + DateTime.now().difference(state.startTime!)
        : state.elapsed;

    state = state.copyWith(
      isRunning: false,
      isPaused: true,
      elapsed: currentElapsed,
      pausedElapsed: currentElapsed,
    );

    _persistTimerData();
    _updateNotification();
  }

  /// Retoma o timer livre
  void resumeTimer() {
    if (!state.isPaused) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: DateTime.now(),
    );

    _persistTimerData();
    _updateNotification();
    _startTimerTicker();
  }

  /// Para o timer e retorna os dados do registro
  TimerState stopTimer() {
    debugPrint('[TimerNotifier] stopTimer called');
    _timer?.cancel();
    _timer = null;

    final finalState = state;

    // Cancelar notificacao persistente (Android: ForegroundService, iOS: Awesome)
    _cancelTimerNotification();

    // Mostrar notificacao de conclusao
    if (finalState.elapsed.inSeconds > 0 || finalState.isPomodoroMode) {
      final minutes = finalState.isPomodoroMode
          ? finalState.pomodoroDuration.inMinutes -
                finalState.pomodoroTimeLeft.inMinutes
          : finalState.elapsed.inMinutes;

      if (finalState.isPomodoroMode) {
        NotificationService.instance.showPomodoroComplete(
          finalState.taskName ?? 'Pomodoro',
          minutes > 0 ? minutes : 1,
        );
      } else {
        NotificationService.instance.showTimerComplete(
          finalState.taskName ?? 'Timer',
          finalState.elapsed,
        );
      }
    }

    _clearPersistedData();

    state = state.copyWith(isRunning: false, isPaused: false);

    return finalState;
  }

  /// Cancela o timer sem salvar
  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    _cancelTimerNotification();
    _clearPersistedData();
    state = const TimerState();
  }

  /// Inicia sessão Pomodoro
  void startPomodoro({String? taskName, String? category, String? project}) {
    _timer?.cancel();

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isPomodoroMode: true,
      isPomodoroBreak: false,
      pomodoroTimeLeft: pomodoroDuration,
      pomodoroDuration: pomodoroDuration,
      taskName: taskName ?? state.taskName,
      category: category ?? state.category,
      project: project ?? state.project,
      startTime: DateTime.now(),
    );

    _persistTimerData();
    _showTimerNotification();

    // Agendar notificação de conclusão
    NotificationService.instance.schedulePomodoroTimer(
      pomodoroDuration,
      taskName ?? state.taskName ?? 'Pomodoro',
    );

    _startPomodoroTicker();
  }

  /// Inicia o ticker do pomodoro
  void _startPomodoroTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && !state.isPaused && state.isPomodoroMode) {
        final newTimeLeft = state.pomodoroTimeLeft - const Duration(seconds: 1);

        if (newTimeLeft.inSeconds <= 0) {
          _timer?.cancel();
          _onPomodoroComplete();
        } else {
          state = state.copyWith(pomodoroTimeLeft: newTimeLeft);
          _updateNotification();

          // Persistir a cada 10 segundos
          if (newTimeLeft.inSeconds % 10 == 0) {
            _persistTimerData();
          }
        }
      }
    });
  }

  /// Chamado quando pomodoro termina
  void _onPomodoroComplete() {
    _cancelTimerNotification();

    if (!state.isPomodoroBreak) {
      // Sessão de foco concluída
      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        pomodoroSessions: state.pomodoroSessions + 1,
        pomodoroTimeLeft: Duration.zero,
      );

      // Mostrar notificação de conclusão (legado)
      NotificationService.instance.showPomodoroComplete(
        state.taskName ?? 'Pomodoro',
        state.pomodoroDuration.inMinutes,
      );

      // Enviar notificação moderna
      ModernNotificationService.instance.sendPomodoroComplete(
        sessionNumber: state.pomodoroSessions,
        totalMinutes: state.pomodoroDuration.inMinutes,
      );

      HapticFeedback.heavyImpact();
    } else {
      // Pausa concluída, reiniciar sessão
      HapticFeedback.mediumImpact();

      // Notificação de pausa completa
      ModernNotificationService.instance.sendPomodoroBreakComplete();

      startPomodoro(
        taskName: state.taskName,
        category: state.category,
        project: state.project,
      );
    }

    _clearPersistedData();
  }

  /// Pausa o Pomodoro
  void pausePomodoro() {
    if (!state.isRunning || state.isPaused) return;

    _timer?.cancel();
    NotificationService.instance.cancelPomodoroTimer();

    state = state.copyWith(isRunning: false, isPaused: true);

    _persistTimerData();
    _updateNotification();
  }

  /// Retoma o Pomodoro
  void resumePomodoro() {
    if (!state.isPaused || !state.isPomodoroMode) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: DateTime.now(),
    );

    // Re-agendar notificação de conclusão
    NotificationService.instance.schedulePomodoroTimer(
      state.pomodoroTimeLeft,
      state.taskName ?? 'Pomodoro',
    );

    _persistTimerData();
    _updateNotification();
    _startPomodoroTicker();
  }

  /// Inicia pausa do Pomodoro
  void startBreak() {
    _timer?.cancel();

    final isLongBreak = state.pomodoroSessions >= pomodoroTotalSessions;
    final breakDuration = isLongBreak ? longBreakDuration : shortBreakDuration;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isPomodoroBreak: true,
      pomodoroTimeLeft: breakDuration,
      pomodoroSessions: isLongBreak ? 0 : state.pomodoroSessions,
      startTime: DateTime.now(),
    );

    _persistTimerData();
    NotificationService.instance.scheduleBreakTimer(breakDuration);
    _showTimerNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRunning && !state.isPaused && state.isPomodoroBreak) {
        final newTimeLeft = state.pomodoroTimeLeft - const Duration(seconds: 1);

        if (newTimeLeft.inSeconds <= 0) {
          _timer?.cancel();
          _onPomodoroComplete();
        } else {
          state = state.copyWith(pomodoroTimeLeft: newTimeLeft);
          _updateNotification();
        }
      }
    });
  }

  /// Reseta o Pomodoro
  void resetPomodoro() {
    _timer?.cancel();
    _timer = null;
    NotificationService.instance.cancelPomodoroTimer();
    _cancelTimerNotification();
    _clearPersistedData();
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      isPomodoroMode: false,
      isPomodoroBreak: false,
      pomodoroTimeLeft: pomodoroDuration,
      taskName: null,
    );
  }

  /// Atualiza o tempo restante do Pomodoro (chamado pela UI)
  void updatePomodoroTime(Duration timeLeft) {
    state = state.copyWith(pomodoroTimeLeft: timeLeft);
    _persistTimerData();
  }

  /// Atualiza o nome da tarefa (para trocar tarefa com timer rodando)
  void updateTaskName(String? taskName) {
    state = state.copyWith(taskName: taskName);
    _persistTimerData();
    _updateNotification();
  }

  /// Pula para próxima sessão/pausa
  void skipPomodoro() {
    _timer?.cancel();
    NotificationService.instance.cancelPomodoroTimer();
    NotificationService.instance.cancelTimerNotification();

    if (!state.isPomodoroBreak) {
      state = state.copyWith(
        pomodoroSessions: state.pomodoroSessions + 1,
        isRunning: false,
        isPaused: false,
      );
    } else {
      state = state.copyWith(
        isPomodoroBreak: false,
        pomodoroTimeLeft: pomodoroDuration,
        isRunning: false,
        isPaused: false,
      );
    }
    _clearPersistedData();
  }

  /// Mostra notificação do timer
  /// Android: usa ForegroundService nativo com botões PendingIntent
  /// iOS: usa NotificationService (Awesome Notifications)
  void _showTimerNotification() {
    if (Platform.isAndroid) {
      // Android: Usar ForegroundService nativo para botões funcionais
      ForegroundService.instance.startTimer(
        taskName:
            state.taskName ?? (state.isPomodoroMode ? 'Pomodoro' : 'Timer'),
        durationSeconds: state.isPomodoroMode
            ? state.pomodoroDuration.inSeconds
            : null,
        isPomodoro: state.isPomodoroMode,
      );
    } else {
      // iOS: Usar Awesome Notifications
      if (state.isPomodoroMode) {
        NotificationService.instance.showTimerRunningNotification(
          taskName: state.taskName ?? 'Pomodoro',
          elapsed: state.pomodoroDuration - state.pomodoroTimeLeft,
          isPomodoro: true,
          pomodoroTimeLeft: state.pomodoroTimeLeft,
          isPaused: state.isPaused,
        );
      } else {
        NotificationService.instance.showTimerRunningNotification(
          taskName: state.taskName ?? 'Timer',
          elapsed: state.elapsed,
          isPaused: state.isPaused,
        );
      }
    }
  }

  /// Atualiza notificação existente
  void _updateNotification() {
    if (Platform.isAndroid) {
      // Android: O ForegroundService nativo atualiza automaticamente
      // Apenas atualizar se necessário via MethodChannel
      ForegroundService.instance.updateNotification(
        taskName:
            state.taskName ?? (state.isPomodoroMode ? 'Pomodoro' : 'Timer'),
        elapsed: state.isPomodoroMode
            ? state.pomodoroDuration - state.pomodoroTimeLeft
            : state.elapsed,
        remaining: state.isPomodoroMode ? state.pomodoroTimeLeft : null,
        isPaused: state.isPaused,
      );
    } else {
      // iOS: Usar Awesome Notifications
      if (state.isPomodoroMode) {
        NotificationService.instance.updateTimerNotification(
          taskName: state.taskName ?? 'Pomodoro',
          elapsed: state.pomodoroDuration - state.pomodoroTimeLeft,
          isPomodoro: true,
          pomodoroTimeLeft: state.pomodoroTimeLeft,
          isPaused: state.isPaused,
        );
      } else {
        NotificationService.instance.updateTimerNotification(
          taskName: state.taskName ?? 'Timer',
          elapsed: state.elapsed,
          isPaused: state.isPaused,
        );
      }
    }
  }

  /// Cancela a notificação do timer
  void _cancelTimerNotification() {
    if (Platform.isAndroid) {
      ForegroundService.instance.stopTimer();
    } else {
      NotificationService.instance.cancelTimerNotification();
    }
  }

  /// Atualiza configurações do Pomodoro
  void updatePomodoroSettings({
    Duration? focusDuration,
    Duration? shortBreak,
    Duration? longBreak,
    int? totalSessions,
    bool openPomodoroScreen = false,
  }) {
    if (focusDuration != null) pomodoroDuration = focusDuration;
    if (shortBreak != null) shortBreakDuration = shortBreak;
    if (longBreak != null) longBreakDuration = longBreak;
    if (totalSessions != null) pomodoroTotalSessions = totalSessions;

    if (!state.isRunning && !state.isPomodoroBreak) {
      state = state.copyWith(
        pomodoroTimeLeft: pomodoroDuration,
        pomodoroDuration: pomodoroDuration,
        shouldOpenPomodoroScreen: openPomodoroScreen,
      );
    } else if (openPomodoroScreen) {
      state = state.copyWith(shouldOpenPomodoroScreen: true);
    }
  }

  /// Reseta a flag de abrir tela do Pomodoro
  void clearPomodoroScreenFlag() {
    state = state.copyWith(shouldOpenPomodoroScreen: false);
  }

  /// Restaura o estado do timer livre (chamado pelo AppLifecycleService)
  void restoreTimerState({
    required DateTime startTime,
    required Duration elapsed,
    String? taskName,
    String? category,
    String? project,
    int? iconCode,
    int? colorValue,
  }) {
    _timer?.cancel();

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: startTime,
      elapsed: elapsed,
      pausedElapsed: elapsed,
      taskName: taskName,
      category: category,
      project: project,
      iconCode: iconCode,
      colorValue: colorValue,
      isPomodoroMode: false,
    );

    _persistTimerData();
    _showTimerNotification();
    _startTimerTicker();

    debugPrint('✅ Timer restaurado: ${elapsed.inMinutes}min');
  }

  /// Restaura o estado do Pomodoro (chamado pelo AppLifecycleService)
  void restorePomodoroState({
    required Duration timeLeft,
    required int sessions,
    required bool isBreak,
    String? taskName,
  }) {
    _timer?.cancel();

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      isPomodoroMode: true,
      isPomodoroBreak: isBreak,
      pomodoroTimeLeft: timeLeft,
      pomodoroSessions: sessions,
      taskName: taskName,
      startTime: DateTime.now(),
    );

    _persistTimerData();
    _showTimerNotification();
    _startPomodoroTicker();

    debugPrint('✅ Pomodoro restaurado: ${timeLeft.inMinutes}min restantes');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider global do timer
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/providers/timer_provider.dart';

/// Serviço que monitora o ciclo de vida do app e salva automaticamente o estado
class AppLifecycleService with WidgetsBindingObserver {
  final Ref ref;
  Box? _stateBox;
  DateTime? _lastSaveTime;
  
  static const String _kStateBoxName = 'app_state';
  static const String _kLastScreenKey = 'last_screen';
  static const String _kTimerStateKey = 'timer_state';
  static const String _kUnsavedNoteKey = 'unsaved_note';
  static const String _kReadingSessionKey = 'reading_session';
  
  AppLifecycleService(this.ref) {
    _init();
  }

  Future<void> _init() async {
    try {
      _stateBox = await Hive.openBox(_kStateBoxName);
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('⚠️ Erro ao inicializar AppLifecycleService: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 App lifecycle changed to: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App indo para background ou sendo fechado - salvar tudo
        _saveAllState();
        break;
      case AppLifecycleState.resumed:
        // App voltando - restaurar estado se necessário
        _restoreStateIfNeeded();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Salva todo o estado importante do app
  Future<void> _saveAllState() async {
    if (_stateBox == null) return;
    
    final now = DateTime.now();
    // Evita salvar múltiplas vezes em menos de 1 segundo
    if (_lastSaveTime != null && now.difference(_lastSaveTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSaveTime = now;

    debugPrint('💾 Salvando estado do app...');
    
    try {
      // 1. Salvar estado do timer
      final timerState = ref.read(timerProvider);
      if (timerState.isRunning || timerState.isPaused) {
        await _stateBox!.put(_kTimerStateKey, {
          'isRunning': timerState.isRunning,
          'isPaused': timerState.isPaused,
          'isPomodoroMode': timerState.isPomodoroMode,
          'startTime': timerState.startTime?.toIso8601String(),
          'elapsed': timerState.elapsed.inSeconds,
          'taskName': timerState.taskName,
          'category': timerState.category,
          'project': timerState.project,
          'iconCode': timerState.iconCode,
          'colorValue': timerState.colorValue,
          // Pomodoro specific
          'pomodoroTimeLeft': timerState.pomodoroTimeLeft.inSeconds,
          'pomodoroSessions': timerState.pomodoroSessions,
          'isPomodoroBreak': timerState.isPomodoroBreak,
          'savedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Timer state saved');
      }
      
      // 2. Salvar tela atual (será implementado pelo navigation provider)
      // await _saveCurrentScreen();
      
    } catch (e) {
      debugPrint('❌ Erro ao salvar estado: $e');
    }
  }

  /// Restaura o estado se o app foi fechado inesperadamente
  Future<void> _restoreStateIfNeeded() async {
    if (_stateBox == null) return;
    
    try {
      // Verifica se há timer ativo salvo
      final timerState = _stateBox!.get(_kTimerStateKey);
      if (timerState != null && timerState is Map) {
        final savedAt = DateTime.parse(timerState['savedAt'] as String);
        final now = DateTime.now();
        
        // Se foi salvo há menos de 30 minutos, restaura
        if (now.difference(savedAt) < const Duration(minutes: 30)) {
          debugPrint('🔄 Restaurando timer...');
          await _restoreTimerState(timerState);
        } else {
          // Timer muito antigo, limpa
          await _stateBox!.delete(_kTimerStateKey);
          debugPrint('🗑️ Timer state muito antigo, descartado');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao restaurar estado: $e');
    }
  }

  /// Restaura o estado do timer
  Future<void> _restoreTimerState(Map timerState) async {
    try {
      final notifier = ref.read(timerProvider.notifier);
      
      final startTime = timerState['startTime'] != null 
          ? DateTime.parse(timerState['startTime'] as String)
          : null;
      final elapsedSeconds = timerState['elapsed'] as int;
      final isPomodoroMode = timerState['isPomodoroMode'] as bool? ?? false;
      
      if (isPomodoroMode) {
        // Restaurar Pomodoro
        final pomodoroTimeLeftSeconds = timerState['pomodoroTimeLeft'] as int;
        final sessions = timerState['pomodoroSessions'] as int? ?? 0;
        final isBreak = timerState['isPomodoroBreak'] as bool? ?? false;
        
        // Calcular tempo decorrido desde o save
        final savedAt = DateTime.parse(timerState['savedAt'] as String);
        final timeSinceSave = DateTime.now().difference(savedAt);
        
        // Ajustar tempo do pomodoro
        final adjustedTimeLeft = Duration(seconds: pomodoroTimeLeftSeconds) - timeSinceSave;
        
        if (adjustedTimeLeft.inSeconds > 0) {
          notifier.restorePomodoroState(
            timeLeft: adjustedTimeLeft,
            sessions: sessions,
            isBreak: isBreak,
            taskName: timerState['taskName'] as String?,
          );
          debugPrint('✅ Pomodoro restaurado: ${adjustedTimeLeft.inMinutes}min restantes');
        } else {
          // Pomodoro já terminou
          await _stateBox!.delete(_kTimerStateKey);
          debugPrint('⏰ Pomodoro já terminou durante background');
        }
      } else {
        // Restaurar timer livre
        final now = DateTime.now();
        final totalElapsed = Duration(seconds: elapsedSeconds) + 
            (startTime != null ? now.difference(startTime) : Duration.zero);
        
        notifier.restoreTimerState(
          startTime: startTime ?? now.subtract(totalElapsed),
          elapsed: totalElapsed,
          taskName: timerState['taskName'] as String?,
          category: timerState['category'] as String?,
          project: timerState['project'] as String?,
          iconCode: timerState['iconCode'] as int?,
          colorValue: timerState['colorValue'] as int?,
        );
        debugPrint('✅ Timer livre restaurado: ${totalElapsed.inMinutes}min');
      }
    } catch (e) {
      debugPrint('❌ Erro ao restaurar timer: $e');
      // Se der erro, limpa o estado salvo
      await _stateBox!.delete(_kTimerStateKey);
    }
  }

  /// Salva o estado de uma nota sendo editada
  Future<void> saveUnsavedNote({
    required String noteId,
    required String title,
    required String content,
    required String jsonContent,
  }) async {
    if (_stateBox == null) return;
    
    await _stateBox!.put(_kUnsavedNoteKey, {
      'noteId': noteId,
      'title': title,
      'content': content,
      'jsonContent': jsonContent,
      'savedAt': DateTime.now().toIso8601String(),
    });
    debugPrint('💾 Nota não salva armazenada para recuperação');
  }

  /// Recupera nota não salva
  Map<String, dynamic>? getUnsavedNote() {
    if (_stateBox == null) return null;
    
    final data = _stateBox!.get(_kUnsavedNoteKey);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Limpa nota não salva (após salvar com sucesso)
  Future<void> clearUnsavedNote() async {
    if (_stateBox == null) return;
    await _stateBox!.delete(_kUnsavedNoteKey);
  }

  /// Salva sessão de leitura ativa
  Future<void> saveReadingSession({
    required String bookId,
    required int currentPage,
    required DateTime startTime,
  }) async {
    if (_stateBox == null) return;
    
    await _stateBox!.put(_kReadingSessionKey, {
      'bookId': bookId,
      'currentPage': currentPage,
      'startTime': startTime.toIso8601String(),
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Recupera sessão de leitura
  Map<String, dynamic>? getReadingSession() {
    if (_stateBox == null) return null;
    
    final data = _stateBox!.get(_kReadingSessionKey);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Limpa sessão de leitura
  Future<void> clearReadingSession() async {
    if (_stateBox == null) return;
    await _stateBox!.delete(_kReadingSessionKey);
  }

  /// Limpa todo o estado salvo
  Future<void> clearAllState() async {
    if (_stateBox == null) return;
    await _stateBox!.clear();
    debugPrint('🗑️ Todo o estado salvo foi limpo');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Provider para o serviço de lifecycle
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

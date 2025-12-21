import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter wrapper for Native Foreground Service (Timer)
/// Communicates with:
/// - Android: ForegroundTimerService.kt via MethodChannel
/// - iOS: AppDelegate.swift / TimerStateManager.swift via MethodChannel
class ForegroundService {
  static final ForegroundService _instance = ForegroundService._();
  static ForegroundService get instance => _instance;

  ForegroundService._();

  static const MethodChannel _channel = MethodChannel(
    'io.odyssey.moodtracker/foreground_service',
  );

  bool _isRunning = false;
  String? _currentTaskName;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _isPomodoro = false;
  int? _durationSeconds;
  bool _initialized = false;

  // Stream controller for timer updates from native
  final StreamController<TimerUpdate> _updateController =
      StreamController<TimerUpdate>.broadcast();
  Stream<TimerUpdate> get onTimerUpdate => _updateController.stream;

  // Callbacks from native side
  VoidCallback? onTimerStopped;
  VoidCallback? onTimerPaused;
  VoidCallback? onTimerResumed;
  void Function(Duration elapsed)? onTimerTick;
  void Function(String action)? onTimerAction; // For iOS actions

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  String? get currentTaskName => _currentTaskName;
  Duration get elapsed => _elapsed;
  bool get isPomodoro => _isPomodoro;
  int? get durationSeconds => _durationSeconds;

  /// Initialize method channel handlers and restore state
  Future<void> initialize() async {
    if (_initialized) return;

    _channel.setMethodCallHandler(_handleMethodCall);

    // Restore state from native side (important after app restart)
    await _restoreState();

    _initialized = true;
    debugPrint(
      '[ForegroundService] Initialized on ${Platform.operatingSystem}',
    );
  }

  /// Restore timer state from native storage
  Future<void> _restoreState() async {
    try {
      final state = await getTimerState();
      if (state != null && state['isRunning'] == true) {
        _isRunning = true;
        _isPaused = state['isPaused'] ?? false;
        _currentTaskName = state['taskName'] ?? '';
        _elapsed = Duration(seconds: state['elapsedSeconds'] ?? 0);
        _isPomodoro = state['isPomodoro'] ?? false;
        final durSecs = state['durationSeconds'] ?? -1;
        _durationSeconds = durSecs > 0 ? durSecs : null;

        debugPrint(
          '[ForegroundService] State restored: $_currentTaskName, elapsed=${_elapsed.inSeconds}s',
        );

        // Notify listeners
        _updateController.add(
          TimerUpdate(
            elapsed: _elapsed,
            taskName: _currentTaskName ?? '',
            isPaused: _isPaused,
            remaining: _durationSeconds != null
                ? Duration(seconds: _durationSeconds! - _elapsed.inSeconds)
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ForegroundService] Error restoring state: $e');
    }
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTimerTick':
        final elapsedSeconds = call.arguments['elapsedSeconds'] as int;
        _elapsed = Duration(seconds: elapsedSeconds);
        _updateController.add(
          TimerUpdate(
            elapsed: _elapsed,
            taskName: _currentTaskName ?? '',
            isPaused: _isPaused,
          ),
        );
        onTimerTick?.call(_elapsed);
        break;

      case 'onTimerStopped':
        _isRunning = false;
        _isPaused = false;
        _elapsed = Duration.zero;
        onTimerStopped?.call();
        break;

      case 'onTimerPaused':
        _isPaused = true;
        onTimerPaused?.call();
        break;

      case 'onTimerResumed':
        _isPaused = false;
        onTimerResumed?.call();
        break;

      case 'onTimerCompleted':
        final elapsedSeconds = call.arguments['elapsedSeconds'] as int;
        _elapsed = Duration(seconds: elapsedSeconds);
        _isRunning = false;
        debugPrint(
          '[ForegroundService] Timer completed: ${_elapsed.inSeconds}s',
        );
        break;

      case 'onTimerAction':
        // iOS notification action callback
        final action = call.arguments['action'] as String?;
        if (action != null) {
          debugPrint('[ForegroundService] Timer action received: $action');
          onTimerAction?.call(action);
        }
        break;

      default:
        debugPrint('[ForegroundService] Unknown method: ${call.method}');
    }
  }

  /// Start foreground timer service
  Future<bool> startTimer({
    required String taskName,
    int? durationSeconds, // For Pomodoro countdown
    bool isPomodoro = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startTimer', {
        'taskName': taskName,
        'durationSeconds': durationSeconds,
        'isPomodoro': isPomodoro,
      });

      if (result == true) {
        _isRunning = true;
        _isPaused = false;
        _currentTaskName = taskName;
        _elapsed = Duration.zero;
        debugPrint('[ForegroundService] Timer started: $taskName');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error starting timer: ${e.message}');
      return false;
    }
  }

  /// Pause the timer
  Future<bool> pauseTimer() async {
    try {
      final result = await _channel.invokeMethod<bool>('pauseTimer');
      if (result == true) {
        _isPaused = true;
        debugPrint('[ForegroundService] Timer paused');
      }
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error pausing timer: ${e.message}');
      return false;
    }
  }

  /// Resume the timer
  Future<bool> resumeTimer() async {
    try {
      final result = await _channel.invokeMethod<bool>('resumeTimer');
      if (result == true) {
        _isPaused = false;
        debugPrint('[ForegroundService] Timer resumed');
      }
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error resuming timer: ${e.message}');
      return false;
    }
  }

  /// Stop the timer
  Future<bool> stopTimer() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopTimer');
      if (result == true) {
        _isRunning = false;
        _isPaused = false;
        _currentTaskName = null;
        _elapsed = Duration.zero;
        debugPrint('[ForegroundService] Timer stopped');
      }
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error stopping timer: ${e.message}');
      return false;
    }
  }

  /// Update notification with new time (called from Flutter timer)
  Future<void> updateNotification({
    required String taskName,
    required Duration elapsed,
    Duration? remaining,
    bool isPaused = false,
  }) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'taskName': taskName,
        'elapsedSeconds': elapsed.inSeconds,
        'remainingSeconds': remaining?.inSeconds,
        'isPaused': isPaused,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[ForegroundService] Error updating notification: ${e.message}',
      );
    }
  }

  /// Check if service is running
  Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error checking service: ${e.message}');
      return false;
    }
  }

  /// Get current timer state (for app restore after kill)
  Future<Map<String, dynamic>?> getTimerState() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getTimerState',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('[ForegroundService] Error getting timer state: ${e.message}');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
  }
}

/// Timer update data class
class TimerUpdate {
  final Duration elapsed;
  final String taskName;
  final bool isPaused;
  final Duration? remaining;

  TimerUpdate({
    required this.elapsed,
    required this.taskName,
    required this.isPaused,
    this.remaining,
  });
}

/// Singleton accessor
final foregroundService = ForegroundService.instance;

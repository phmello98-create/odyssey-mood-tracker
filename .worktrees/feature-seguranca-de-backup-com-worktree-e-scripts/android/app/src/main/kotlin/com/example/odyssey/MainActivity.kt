package com.example.odyssey

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.odyssey/foreground_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ForegroundTimerService.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimer" -> {
                    val taskName = call.argument<String>("taskName") ?: "Timer"
                    val durationSeconds = call.argument<Int>("durationSeconds")
                    val isPomodoro = call.argument<Boolean>("isPomodoro") ?: false

                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        action = ForegroundTimerService.ACTION_START
                        putExtra(ForegroundTimerService.EXTRA_TASK_NAME, taskName)
                        durationSeconds?.let { putExtra(ForegroundTimerService.EXTRA_DURATION_SECONDS, it) }
                        putExtra(ForegroundTimerService.EXTRA_IS_POMODORO, isPomodoro)
                    }

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_ERROR", e.message, null)
                    }
                }

                "pauseTimer" -> {
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        action = ForegroundTimerService.ACTION_PAUSE
                    }
                    startService(intent)
                    result.success(true)
                }

                "resumeTimer" -> {
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        action = ForegroundTimerService.ACTION_RESUME
                    }
                    startService(intent)
                    result.success(true)
                }

                "stopTimer" -> {
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        action = ForegroundTimerService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }

                "updateNotification" -> {
                    // Notification is updated automatically by the service
                    // This is just for manual updates from Flutter if needed
                    result.success(true)
                }

                "isServiceRunning" -> {
                    result.success(ForegroundTimerService.isServiceRunning)
                }

                "getTimerState" -> {
                    val prefs = getSharedPreferences(ForegroundTimerService.PREFS_NAME, MODE_PRIVATE)
                    val state = mapOf(
                        "isRunning" to prefs.getBoolean(ForegroundTimerService.KEY_IS_RUNNING, false),
                        "isPaused" to prefs.getBoolean(ForegroundTimerService.KEY_IS_PAUSED, false),
                        "taskName" to (prefs.getString(ForegroundTimerService.KEY_TASK_NAME, "") ?: ""),
                        "elapsedSeconds" to prefs.getInt(ForegroundTimerService.KEY_ELAPSED_SECONDS, 0),
                        "durationSeconds" to prefs.getInt(ForegroundTimerService.KEY_DURATION_SECONDS, -1),
                        "isPomodoro" to prefs.getBoolean(ForegroundTimerService.KEY_IS_POMODORO, false)
                    )
                    result.success(state)
                }

                else -> result.notImplemented()
            }
        }
    }
}

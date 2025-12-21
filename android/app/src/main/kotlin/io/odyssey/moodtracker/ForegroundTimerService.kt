package io.odyssey.moodtracker

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Foreground Service for Timer persistence
 * Keeps timer running even when app is in background or killed
 * 
 * Features:
 * - Persistent notification with pause/resume/stop actions
 * - State persistence in SharedPreferences
 * - Boot recovery via BootReceiver
 * - Support for both free timer and Pomodoro countdown
 */
class ForegroundTimerService : Service() {

    companion object {
        private const val TAG = "ForegroundTimerService"
        const val CHANNEL_ID = "odyssey_timer_channel"
        const val NOTIFICATION_ID = 1001
        const val PREFS_NAME = "timer_prefs"

        const val ACTION_START = "ACTION_START"
        const val ACTION_PAUSE = "ACTION_PAUSE"
        const val ACTION_RESUME = "ACTION_RESUME"
        const val ACTION_STOP = "ACTION_STOP"

        const val EXTRA_TASK_NAME = "task_name"
        const val EXTRA_DURATION_SECONDS = "duration_seconds"
        const val EXTRA_IS_POMODORO = "is_pomodoro"

        // SharedPreferences keys
        const val KEY_IS_RUNNING = "is_running"
        const val KEY_IS_PAUSED = "is_paused"
        const val KEY_TASK_NAME = "task_name"
        const val KEY_ELAPSED_SECONDS = "elapsed_seconds"
        const val KEY_START_TIME = "start_time"
        const val KEY_DURATION_SECONDS = "duration_seconds"
        const val KEY_IS_POMODORO = "is_pomodoro"

        var methodChannel: MethodChannel? = null
        var isServiceRunning = false
    }

    private val binder = LocalBinder()
    private var handler: Handler? = null
    private var timerRunnable: Runnable? = null

    private var isRunning = false
    private var isPaused = false
    private var taskName = ""
    private var elapsedSeconds = 0
    private var durationSeconds: Int? = null
    private var isPomodoro = false
    private var startTimeMillis: Long = 0

    private lateinit var prefs: SharedPreferences

    inner class LocalBinder : Binder() {
        fun getService(): ForegroundTimerService = this@ForegroundTimerService
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        handler = Handler(Looper.getMainLooper())
        createNotificationChannel()
        restoreState()
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                taskName = intent.getStringExtra(EXTRA_TASK_NAME) ?: "Timer"
                durationSeconds = intent.getIntExtra(EXTRA_DURATION_SECONDS, -1).takeIf { it > 0 }
                isPomodoro = intent.getBooleanExtra(EXTRA_IS_POMODORO, false)
                startTimer()
            }
            ACTION_PAUSE -> pauseTimer()
            ACTION_RESUME -> resumeTimer()
            ACTION_STOP -> stopTimer()
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer em Execução",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notificação persistente do timer"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun startTimer() {
        if (isRunning) {
            Log.d(TAG, "startTimer called but timer already running")
            return
        }

        Log.i(TAG, "Starting timer: task='$taskName', duration=${durationSeconds ?: "unlimited"}, pomodoro=$isPomodoro")
        
        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        startTimeMillis = System.currentTimeMillis()
        isServiceRunning = true

        saveState()

        try {
            val notification = buildNotification()
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Foreground service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service: ${e.message}", e)
            // Fallback: continue without foreground (may be killed by system)
        }

        startTimerLoop()
    }

    private fun pauseTimer() {
        if (!isRunning || isPaused) {
            Log.d(TAG, "pauseTimer called but invalid state: running=$isRunning, paused=$isPaused")
            return
        }

        Log.i(TAG, "Pausing timer at ${elapsedSeconds}s")
        isPaused = true
        timerRunnable?.let { handler?.removeCallbacks(it) }
        saveState()

        updateNotification()
        notifyFlutter("onTimerPaused", null)
    }

    private fun resumeTimer() {
        if (!isRunning || !isPaused) {
            Log.d(TAG, "resumeTimer called but invalid state: running=$isRunning, paused=$isPaused")
            return
        }

        Log.i(TAG, "Resuming timer from ${elapsedSeconds}s")
        isPaused = false
        startTimeMillis = System.currentTimeMillis() - (elapsedSeconds * 1000L)
        saveState()

        startTimerLoop()
        notifyFlutter("onTimerResumed", null)
    }

    private fun stopTimer() {
        Log.i(TAG, "Stopping timer. Final elapsed: ${elapsedSeconds}s, task='$taskName'")
        
        isRunning = false
        isPaused = false
        isServiceRunning = false
        timerRunnable?.let { handler?.removeCallbacks(it) }

        clearState()
        notifyFlutter("onTimerStopped", null)

        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping foreground service: ${e.message}", e)
        }
    }

    private fun startTimerLoop() {
        timerRunnable = object : Runnable {
            override fun run() {
                if (!isRunning || isPaused) return

                elapsedSeconds = ((System.currentTimeMillis() - startTimeMillis) / 1000).toInt()

                // Check if Pomodoro timer completed
                if (isPomodoro && durationSeconds != null && elapsedSeconds >= durationSeconds!!) {
                    notifyFlutter("onTimerCompleted", mapOf("elapsedSeconds" to elapsedSeconds))
                    stopTimer()
                    return
                }

                updateNotification()
                notifyFlutter("onTimerTick", mapOf("elapsedSeconds" to elapsedSeconds))
                saveState()

                handler?.postDelayed(this, 1000)
            }
        }
        handler?.post(timerRunnable!!)
    }

    private fun buildNotification(): Notification {
        val timeStr = formatTime(elapsedSeconds)
        
        // Titulo e corpo mais informativos
        val title: String
        val body: String
        val subText: String
        
        if (isPomodoro && durationSeconds != null) {
            val remaining = (durationSeconds!! - elapsedSeconds).coerceAtLeast(0)
            val remainingStr = formatTime(remaining)
            if (isPaused) {
                title = "⏸️ Pomodoro Pausado"
                body = taskName
                subText = "Restam $remainingStr"
            } else {
                title = "🍅 Pomodoro"
                body = taskName
                subText = "Restam $remainingStr"
            }
        } else {
            if (isPaused) {
                title = "⏸️ Timer Pausado"
                body = taskName
                subText = timeStr
            } else {
                title = "⏱️ Timer Ativo"
                body = taskName
                subText = timeStr
            }
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        // Intent to open app
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = PendingIntent.getActivity(this, 0, openIntent, pendingIntentFlags)

        // Action intents
        val pauseIntent = Intent(this, ForegroundTimerService::class.java).apply {
            action = if (isPaused) ACTION_RESUME else ACTION_PAUSE
        }
        val pausePendingIntent = PendingIntent.getService(this, 1, pauseIntent, pendingIntentFlags)

        val stopIntent = Intent(this, ForegroundTimerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(this, 2, stopIntent, pendingIntentFlags)

        // Cor baseada no tipo
        val accentColor = if (isPomodoro) 0xFFEF4444.toInt() else 0xFF7C4DFF.toInt()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSubText(subText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setColor(accentColor)
            .setColorized(true)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .addAction(
                if (isPaused) R.drawable.ic_play else R.drawable.ic_pause,
                if (isPaused) "▶️ Continuar" else "⏸️ Pausar",
                pausePendingIntent
            )
            .addAction(
                R.drawable.ic_stop,
                "⏹️ Parar",
                stopPendingIntent
            )
            .build()
    }

    private fun updateNotification() {
        val notification = buildNotification()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun formatTime(seconds: Int): String {
        val hrs = seconds / 3600
        val mins = (seconds % 3600) / 60
        val secs = seconds % 60
        return if (hrs > 0) {
            String.format("%d:%02d:%02d", hrs, mins, secs)
        } else {
            String.format("%02d:%02d", mins, secs)
        }
    }

    private fun saveState() {
        prefs.edit().apply {
            putBoolean(KEY_IS_RUNNING, isRunning)
            putBoolean(KEY_IS_PAUSED, isPaused)
            putString(KEY_TASK_NAME, taskName)
            putInt(KEY_ELAPSED_SECONDS, elapsedSeconds)
            putLong(KEY_START_TIME, startTimeMillis)
            putInt(KEY_DURATION_SECONDS, durationSeconds ?: -1)
            putBoolean(KEY_IS_POMODORO, isPomodoro)
            apply()
        }
    }

    private fun restoreState() {
        isRunning = prefs.getBoolean(KEY_IS_RUNNING, false)
        isPaused = prefs.getBoolean(KEY_IS_PAUSED, false)
        taskName = prefs.getString(KEY_TASK_NAME, "") ?: ""
        elapsedSeconds = prefs.getInt(KEY_ELAPSED_SECONDS, 0)
        startTimeMillis = prefs.getLong(KEY_START_TIME, 0)
        val durSecs = prefs.getInt(KEY_DURATION_SECONDS, -1)
        durationSeconds = if (durSecs > 0) durSecs else null
        isPomodoro = prefs.getBoolean(KEY_IS_POMODORO, false)

        if (isRunning && !isPaused) {
            // Recalculate elapsed time since last save
            val now = System.currentTimeMillis()
            elapsedSeconds = ((now - startTimeMillis) / 1000).toInt()
        }
    }

    private fun clearState() {
        prefs.edit().clear().apply()
    }

    private fun notifyFlutter(method: String, arguments: Map<String, Any>?) {
        handler?.post {
            try {
                methodChannel?.invokeMethod(method, arguments)
            } catch (e: Exception) {
                // Flutter might not be attached
            }
        }
    }

    fun getState(): Map<String, Any> {
        return mapOf(
            "isRunning" to isRunning,
            "isPaused" to isPaused,
            "taskName" to taskName,
            "elapsedSeconds" to elapsedSeconds,
            "durationSeconds" to (durationSeconds ?: -1),
            "isPomodoro" to isPomodoro
        )
    }

    override fun onDestroy() {
        timerRunnable?.let { handler?.removeCallbacks(it) }
        super.onDestroy()
    }
}

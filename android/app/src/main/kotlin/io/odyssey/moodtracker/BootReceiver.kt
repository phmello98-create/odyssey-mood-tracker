package io.odyssey.moodtracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Boot Receiver to restart foreground timer service after device reboot
 * Also handles QUICKBOOT_POWERON for some device manufacturers
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            Log.d(TAG, "Boot completed, checking for timer to restore")

            // Check if there was a timer running before reboot
            val prefs = context.getSharedPreferences(
                ForegroundTimerService.PREFS_NAME,
                Context.MODE_PRIVATE
            )

            val wasRunning = prefs.getBoolean(ForegroundTimerService.KEY_IS_RUNNING, false)
            val wasPaused = prefs.getBoolean(ForegroundTimerService.KEY_IS_PAUSED, false)

            if (wasRunning) {
                Log.d(TAG, "Timer was running before reboot, restoring...")

                val taskName = prefs.getString(ForegroundTimerService.KEY_TASK_NAME, "Timer") ?: "Timer"
                val durationSeconds = prefs.getInt(ForegroundTimerService.KEY_DURATION_SECONDS, -1)
                val isPomodoro = prefs.getBoolean(ForegroundTimerService.KEY_IS_POMODORO, false)

                // Start service to restore timer
                val serviceIntent = Intent(context, ForegroundTimerService::class.java).apply {
                    action = ForegroundTimerService.ACTION_START
                    putExtra(ForegroundTimerService.EXTRA_TASK_NAME, taskName)
                    if (durationSeconds > 0) {
                        putExtra(ForegroundTimerService.EXTRA_DURATION_SECONDS, durationSeconds)
                    }
                    putExtra(ForegroundTimerService.EXTRA_IS_POMODORO, isPomodoro)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }

                    // If it was paused, pause it again after starting
                    if (wasPaused) {
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            val pauseIntent = Intent(context, ForegroundTimerService::class.java).apply {
                                action = ForegroundTimerService.ACTION_PAUSE
                            }
                            context.startService(pauseIntent)
                        }, 500)
                    }

                    Log.d(TAG, "Timer service restored successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to restore timer service: ${e.message}")
                }
            } else {
                Log.d(TAG, "No timer was running before reboot")
            }
        }
    }
}

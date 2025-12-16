import Foundation
import UserNotifications

/// Manages timer state persistence and notifications for iOS
/// Since iOS suspends background execution, we:
/// 1. Save state to UserDefaults when app enters background
/// 2. Schedule local notification for timer completion
/// 3. Restore state when app returns to foreground
class TimerStateManager {
    static let shared = TimerStateManager()
    
    // UserDefaults keys
    private let keyIsRunning = "timer_is_running"
    private let keyIsPaused = "timer_is_paused"
    private let keyTaskName = "timer_task_name"
    private let keyStartTime = "timer_start_time"
    private let keyElapsedSeconds = "timer_elapsed_seconds"
    private let keyDurationSeconds = "timer_duration_seconds"
    private let keyIsPomodoro = "timer_is_pomodoro"
    private let keyPauseTime = "timer_pause_time"
    
    // Notification identifiers
    private let timerCompletionNotificationId = "timer_completion"
    private let timerPomodoroNotificationCategory = "POMODORO_COMPLETE"
    private let timerBreakNotificationCategory = "BREAK_COMPLETE"
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Notification Setup
    
    private func setupNotificationCategories() {
        let startBreakAction = UNNotificationAction(
            identifier: "START_BREAK",
            title: "Iniciar Pausa",
            options: [.foreground]
        )
        
        let startFocusAction = UNNotificationAction(
            identifier: "START_FOCUS",
            title: "Iniciar Foco",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Fechar",
            options: []
        )
        
        let pomodoroCategory = UNNotificationCategory(
            identifier: timerPomodoroNotificationCategory,
            actions: [startBreakAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let breakCategory = UNNotificationCategory(
            identifier: timerBreakNotificationCategory,
            actions: [startFocusAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            pomodoroCategory,
            breakCategory
        ])
    }
    
    // MARK: - State Management
    
    /// Save current timer state to UserDefaults
    func saveState(
        isRunning: Bool,
        isPaused: Bool,
        taskName: String,
        elapsedSeconds: Int,
        durationSeconds: Int?,
        isPomodoro: Bool
    ) {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: keyIsRunning)
        defaults.set(isPaused, forKey: keyIsPaused)
        defaults.set(taskName, forKey: keyTaskName)
        defaults.set(elapsedSeconds, forKey: keyElapsedSeconds)
        defaults.set(durationSeconds ?? -1, forKey: keyDurationSeconds)
        defaults.set(isPomodoro, forKey: keyIsPomodoro)
        
        if isRunning && !isPaused {
            defaults.set(Date().timeIntervalSince1970, forKey: keyStartTime)
        }
        
        if isPaused {
            defaults.set(Date().timeIntervalSince1970, forKey: keyPauseTime)
        }
        
        defaults.synchronize()
        
        print("[TimerStateManager] State saved: running=\(isRunning), paused=\(isPaused), task=\(taskName)")
    }
    
    /// Load timer state from UserDefaults
    func loadState() -> TimerState? {
        let defaults = UserDefaults.standard
        
        guard defaults.bool(forKey: keyIsRunning) else {
            return nil
        }
        
        let isPaused = defaults.bool(forKey: keyIsPaused)
        let taskName = defaults.string(forKey: keyTaskName) ?? "Timer"
        var elapsedSeconds = defaults.integer(forKey: keyElapsedSeconds)
        let durationSeconds = defaults.integer(forKey: keyDurationSeconds)
        let isPomodoro = defaults.bool(forKey: keyIsPomodoro)
        
        // Calculate elapsed time since last save if timer was running
        if !isPaused {
            let startTime = defaults.double(forKey: keyStartTime)
            if startTime > 0 {
                let now = Date().timeIntervalSince1970
                let additionalSeconds = Int(now - startTime)
                elapsedSeconds += additionalSeconds
            }
        }
        
        return TimerState(
            isRunning: true,
            isPaused: isPaused,
            taskName: taskName,
            elapsedSeconds: elapsedSeconds,
            durationSeconds: durationSeconds > 0 ? durationSeconds : nil,
            isPomodoro: isPomodoro
        )
    }
    
    /// Clear timer state
    func clearState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: keyIsRunning)
        defaults.removeObject(forKey: keyIsPaused)
        defaults.removeObject(forKey: keyTaskName)
        defaults.removeObject(forKey: keyStartTime)
        defaults.removeObject(forKey: keyElapsedSeconds)
        defaults.removeObject(forKey: keyDurationSeconds)
        defaults.removeObject(forKey: keyIsPomodoro)
        defaults.removeObject(forKey: keyPauseTime)
        defaults.synchronize()
        
        print("[TimerStateManager] State cleared")
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule completion notification when app enters background
    func scheduleCompletionNotification(
        taskName: String,
        remainingSeconds: Int,
        isPomodoro: Bool
    ) {
        guard remainingSeconds > 0 else { return }
        
        // Cancel any existing notification
        cancelCompletionNotification()
        
        let content = UNMutableNotificationContent()
        
        if isPomodoro {
            content.title = "🍅 Pomodoro Concluído!"
            content.body = "Sessão de foco em \"\(taskName)\" finalizada."
            content.categoryIdentifier = timerPomodoroNotificationCategory
        } else {
            content.title = "⏱️ Timer Concluído!"
            content.body = "O timer para \"\(taskName)\" terminou."
            content.categoryIdentifier = timerPomodoroNotificationCategory
        }
        
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(remainingSeconds),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: timerCompletionNotificationId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[TimerStateManager] Error scheduling notification: \(error)")
            } else {
                print("[TimerStateManager] Notification scheduled for \(remainingSeconds) seconds")
            }
        }
    }
    
    /// Cancel scheduled completion notification
    func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [timerCompletionNotificationId]
        )
        print("[TimerStateManager] Completion notification cancelled")
    }
    
    // MARK: - App Lifecycle
    
    /// Called when app enters background
    func handleAppDidEnterBackground() {
        guard let state = loadState(), state.isRunning, !state.isPaused else {
            return
        }
        
        // Schedule notification for timer completion
        if let duration = state.durationSeconds {
            let remaining = duration - state.elapsedSeconds
            if remaining > 0 {
                scheduleCompletionNotification(
                    taskName: state.taskName,
                    remainingSeconds: remaining,
                    isPomodoro: state.isPomodoro
                )
            }
        }
    }
    
    /// Called when app returns to foreground
    func handleAppWillEnterForeground() {
        // Cancel any pending notification since app is now active
        cancelCompletionNotification()
        
        // State will be loaded by Flutter side
        print("[TimerStateManager] App returning to foreground, notification cancelled")
    }
}

// MARK: - Timer State Model

struct TimerState {
    let isRunning: Bool
    let isPaused: Bool
    let taskName: String
    let elapsedSeconds: Int
    let durationSeconds: Int?
    let isPomodoro: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "isRunning": isRunning,
            "isPaused": isPaused,
            "taskName": taskName,
            "elapsedSeconds": elapsedSeconds,
            "durationSeconds": durationSeconds ?? -1,
            "isPomodoro": isPomodoro
        ]
    }
}

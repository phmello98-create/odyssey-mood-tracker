import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Setup method channel for timer service
        if let controller = window?.rootViewController as? FlutterViewController {
            methodChannel = FlutterMethodChannel(
                name: "com.example.odyssey/foreground_service",
                binaryMessenger: controller.binaryMessenger
            )
            
            methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                self?.handleMethodCall(call: call, result: result)
            }
        }
        
        // Setup notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Method Channel Handler
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startTimer":
            handleStartTimer(call: call, result: result)
        case "pauseTimer":
            handlePauseTimer(result: result)
        case "resumeTimer":
            handleResumeTimer(result: result)
        case "stopTimer":
            handleStopTimer(result: result)
        case "getTimerState":
            handleGetTimerState(result: result)
        case "isServiceRunning":
            handleIsServiceRunning(result: result)
        case "updateNotification":
            // iOS doesn't have persistent notifications like Android
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleStartTimer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments required", details: nil))
            return
        }
        
        let taskName = args["taskName"] as? String ?? "Timer"
        let durationSeconds = args["durationSeconds"] as? Int
        let isPomodoro = args["isPomodoro"] as? Bool ?? false
        
        TimerStateManager.shared.saveState(
            isRunning: true,
            isPaused: false,
            taskName: taskName,
            elapsedSeconds: 0,
            durationSeconds: durationSeconds,
            isPomodoro: isPomodoro
        )
        
        // Schedule completion notification if duration is set
        if let duration = durationSeconds, duration > 0 {
            TimerStateManager.shared.scheduleCompletionNotification(
                taskName: taskName,
                remainingSeconds: duration,
                isPomodoro: isPomodoro
            )
        }
        
        result(true)
    }
    
    private func handlePauseTimer(result: @escaping FlutterResult) {
        if let state = TimerStateManager.shared.loadState() {
            TimerStateManager.shared.saveState(
                isRunning: true,
                isPaused: true,
                taskName: state.taskName,
                elapsedSeconds: state.elapsedSeconds,
                durationSeconds: state.durationSeconds,
                isPomodoro: state.isPomodoro
            )
            TimerStateManager.shared.cancelCompletionNotification()
        }
        result(true)
    }
    
    private func handleResumeTimer(result: @escaping FlutterResult) {
        if let state = TimerStateManager.shared.loadState() {
            TimerStateManager.shared.saveState(
                isRunning: true,
                isPaused: false,
                taskName: state.taskName,
                elapsedSeconds: state.elapsedSeconds,
                durationSeconds: state.durationSeconds,
                isPomodoro: state.isPomodoro
            )
            
            // Reschedule notification with remaining time
            if let duration = state.durationSeconds {
                let remaining = duration - state.elapsedSeconds
                if remaining > 0 {
                    TimerStateManager.shared.scheduleCompletionNotification(
                        taskName: state.taskName,
                        remainingSeconds: remaining,
                        isPomodoro: state.isPomodoro
                    )
                }
            }
        }
        result(true)
    }
    
    private func handleStopTimer(result: @escaping FlutterResult) {
        TimerStateManager.shared.clearState()
        TimerStateManager.shared.cancelCompletionNotification()
        result(true)
    }
    
    private func handleGetTimerState(result: @escaping FlutterResult) {
        if let state = TimerStateManager.shared.loadState() {
            result(state.toDictionary())
        } else {
            result([
                "isRunning": false,
                "isPaused": false,
                "taskName": "",
                "elapsedSeconds": 0,
                "durationSeconds": -1,
                "isPomodoro": false
            ])
        }
    }
    
    private func handleIsServiceRunning(result: @escaping FlutterResult) {
        let state = TimerStateManager.shared.loadState()
        result(state?.isRunning ?? false)
    }
    
    // MARK: - App Lifecycle
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        TimerStateManager.shared.handleAppDidEnterBackground()
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        TimerStateManager.shared.handleAppWillEnterForeground()
    }
    
    // MARK: - Notification Delegate
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "START_BREAK":
            print("[AppDelegate] User requested to start break")
            methodChannel?.invokeMethod("onTimerAction", arguments: ["action": "start_break"])
        case "START_FOCUS":
            print("[AppDelegate] User requested to start focus")
            methodChannel?.invokeMethod("onTimerAction", arguments: ["action": "start_focus"])
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification
            print("[AppDelegate] User tapped notification")
        default:
            break
        }
        
        completionHandler()
    }
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

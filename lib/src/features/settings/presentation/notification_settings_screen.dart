import 'dart:io';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/notification_manager.dart';
import 'package:odyssey/src/utils/services/notification_scheduler.dart';
import 'package:odyssey/src/utils/helpers/permission_helper.dart';
import 'package:odyssey/src/features/settings/presentation/widgets/permission_rationale_dialog.dart';
import 'package:odyssey/src/features/settings/presentation/widgets/battery_optimization_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Provider para estado das configurações de notificação
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsState {
  final bool isLoading;
  final bool notificationsEnabled;
  final bool moodRemindersEnabled;
  final int moodReminderHour;
  final int moodReminderMinute;
  final bool streakAlertsEnabled;
  final bool pomodoroNotificationsEnabled;
  final bool gamificationEnabled;
  final NotificationPermissionStatus permissionStatus;
  // Novas opções do scheduler
  final bool moodMorningEnabled;
  final int moodMorningHour;
  final bool moodEveningEnabled;
  final int moodEveningHour;
  final bool habitReminderEnabled;
  final int habitReminderInterval;
  final bool taskReminderEnabled;
  final int taskReminderInterval;
  final bool motivationEnabled;
  final int motivationPerDay;

  NotificationSettingsState({
    this.isLoading = true,
    this.notificationsEnabled = true,
    this.moodRemindersEnabled = true,
    this.moodReminderHour = 20,
    this.moodReminderMinute = 0,
    this.streakAlertsEnabled = true,
    this.pomodoroNotificationsEnabled = true,
    this.gamificationEnabled = true,
    this.permissionStatus = NotificationPermissionStatus.granted,
    // Defaults do scheduler
    this.moodMorningEnabled = true,
    this.moodMorningHour = 8,
    this.moodEveningEnabled = true,
    this.moodEveningHour = 20,
    this.habitReminderEnabled = true,
    this.habitReminderInterval = 30,
    this.taskReminderEnabled = true,
    this.taskReminderInterval = 30,
    this.motivationEnabled = true,
    this.motivationPerDay = 3,
  });

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? notificationsEnabled,
    bool? moodRemindersEnabled,
    int? moodReminderHour,
    int? moodReminderMinute,
    bool? streakAlertsEnabled,
    bool? pomodoroNotificationsEnabled,
    bool? gamificationEnabled,
    NotificationPermissionStatus? permissionStatus,
    bool? moodMorningEnabled,
    int? moodMorningHour,
    bool? moodEveningEnabled,
    int? moodEveningHour,
    bool? habitReminderEnabled,
    int? habitReminderInterval,
    bool? taskReminderEnabled,
    int? taskReminderInterval,
    bool? motivationEnabled,
    int? motivationPerDay,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      moodRemindersEnabled: moodRemindersEnabled ?? this.moodRemindersEnabled,
      moodReminderHour: moodReminderHour ?? this.moodReminderHour,
      moodReminderMinute: moodReminderMinute ?? this.moodReminderMinute,
      streakAlertsEnabled: streakAlertsEnabled ?? this.streakAlertsEnabled,
      pomodoroNotificationsEnabled: pomodoroNotificationsEnabled ?? this.pomodoroNotificationsEnabled,
      gamificationEnabled: gamificationEnabled ?? this.gamificationEnabled,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      moodMorningEnabled: moodMorningEnabled ?? this.moodMorningEnabled,
      moodMorningHour: moodMorningHour ?? this.moodMorningHour,
      moodEveningEnabled: moodEveningEnabled ?? this.moodEveningEnabled,
      moodEveningHour: moodEveningHour ?? this.moodEveningHour,
      habitReminderEnabled: habitReminderEnabled ?? this.habitReminderEnabled,
      habitReminderInterval: habitReminderInterval ?? this.habitReminderInterval,
      taskReminderEnabled: taskReminderEnabled ?? this.taskReminderEnabled,
      taskReminderInterval: taskReminderInterval ?? this.taskReminderInterval,
      motivationEnabled: motivationEnabled ?? this.motivationEnabled,
      motivationPerDay: motivationPerDay ?? this.motivationPerDay,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(NotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionStatus = await PermissionHelper.instance.checkPermissionsStatus();
    final schedulerSettings = NotificationScheduler.instance.getSettings();
    
    state = state.copyWith(
      isLoading: false,
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
      moodRemindersEnabled: prefs.getBool('mood_reminders_enabled') ?? true,
      moodReminderHour: prefs.getInt('mood_reminder_hour') ?? 20,
      moodReminderMinute: prefs.getInt('mood_reminder_minute') ?? 0,
      streakAlertsEnabled: prefs.getBool('streak_alerts_enabled') ?? true,
      pomodoroNotificationsEnabled: prefs.getBool('pomodoro_notifications_enabled') ?? true,
      gamificationEnabled: prefs.getBool('gamification_notifications_enabled') ?? true,
      permissionStatus: permissionStatus,
      // Scheduler settings
      moodMorningEnabled: schedulerSettings['moodMorningEnabled'] ?? true,
      moodMorningHour: schedulerSettings['moodMorningHour'] ?? 8,
      moodEveningEnabled: schedulerSettings['moodEveningEnabled'] ?? true,
      moodEveningHour: schedulerSettings['moodEveningHour'] ?? 20,
      habitReminderEnabled: schedulerSettings['habitReminderEnabled'] ?? true,
      habitReminderInterval: schedulerSettings['habitReminderInterval'] ?? 30,
      taskReminderEnabled: schedulerSettings['taskReminderEnabled'] ?? true,
      taskReminderInterval: schedulerSettings['taskReminderInterval'] ?? 30,
      motivationEnabled: schedulerSettings['motivationEnabled'] ?? true,
      motivationPerDay: schedulerSettings['motivationPerDay'] ?? 3,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    await NotificationManager.instance.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setMoodRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mood_reminders_enabled', enabled);
    await NotificationManager.instance.setMoodRemindersEnabled(enabled);
    state = state.copyWith(moodRemindersEnabled: enabled);
  }

  Future<void> setMoodReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mood_reminder_hour', hour);
    await prefs.setInt('mood_reminder_minute', minute);
    
    // Reagendar o lembrete
    if (state.moodRemindersEnabled) {
      await NotificationService.instance.cancelMoodReminder();
      await NotificationService.instance.scheduleDailyMoodReminder(hour: hour, minute: minute);
    }
    
    state = state.copyWith(moodReminderHour: hour, moodReminderMinute: minute);
  }

  Future<void> setStreakAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_alerts_enabled', enabled);
    await NotificationManager.instance.setStreakAlertsEnabled(enabled);
    state = state.copyWith(streakAlertsEnabled: enabled);
  }

  // ============================================
  // SCHEDULER SETTINGS
  // ============================================

  Future<void> setMoodMorningSettings({bool? enabled, int? hour}) async {
    await NotificationScheduler.instance.updateMoodReminderSettings(
      morningEnabled: enabled,
      morningHour: hour,
    );
    state = state.copyWith(
      moodMorningEnabled: enabled ?? state.moodMorningEnabled,
      moodMorningHour: hour ?? state.moodMorningHour,
    );
  }

  Future<void> setMoodEveningSettings({bool? enabled, int? hour}) async {
    await NotificationScheduler.instance.updateMoodReminderSettings(
      eveningEnabled: enabled,
      eveningHour: hour,
    );
    state = state.copyWith(
      moodEveningEnabled: enabled ?? state.moodEveningEnabled,
      moodEveningHour: hour ?? state.moodEveningHour,
    );
  }

  Future<void> setHabitReminderSettings({bool? enabled, int? intervalMinutes}) async {
    await NotificationScheduler.instance.updateHabitReminderSettings(
      enabled: enabled,
      intervalMinutes: intervalMinutes,
    );
    state = state.copyWith(
      habitReminderEnabled: enabled ?? state.habitReminderEnabled,
      habitReminderInterval: intervalMinutes ?? state.habitReminderInterval,
    );
  }

  Future<void> setTaskReminderSettings({bool? enabled, int? intervalMinutes}) async {
    await NotificationScheduler.instance.updateTaskReminderSettings(
      enabled: enabled,
      intervalMinutes: intervalMinutes,
    );
    state = state.copyWith(
      taskReminderEnabled: enabled ?? state.taskReminderEnabled,
      taskReminderInterval: intervalMinutes ?? state.taskReminderInterval,
    );
  }

  Future<void> setMotivationSettings({bool? enabled, int? timesPerDay}) async {
    await NotificationScheduler.instance.updateMotivationSettings(
      enabled: enabled,
      timesPerDay: timesPerDay,
    );
    state = state.copyWith(
      motivationEnabled: enabled ?? state.motivationEnabled,
      motivationPerDay: timesPerDay ?? state.motivationPerDay,
    );
  }

  Future<void> setPomodoroNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pomodoro_notifications_enabled', enabled);
    state = state.copyWith(pomodoroNotificationsEnabled: enabled);
  }

  Future<void> setGamificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gamification_notifications_enabled', enabled);
    await NotificationManager.instance.setGamificationEnabled(enabled);
    state = state.copyWith(gamificationEnabled: enabled);
  }

  Future<void> refreshPermissionStatus() async {
    final status = await PermissionHelper.instance.checkPermissionsStatus();
    state = state.copyWith(permissionStatus: status);
  }
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimePermission();
  }

  Future<void> _checkFirstTimePermission() async {
    final shouldShow = await PermissionHelper.instance.shouldShowRationaleDialog();
    if (shouldShow && mounted) {
      final result = await PermissionRationaleDialog.show(context);
      if (result == true) {
        await PermissionHelper.instance.requestNotificationPermission();
        ref.read(notificationSettingsProvider.notifier).refreshPermissionStatus();
      }
    }
  }

  Future<void> _showTestNotification() async {
    await NotificationService.instance.showDailyInsight(
      '🔔 Notificação de Teste',
      'As notificações estão funcionando corretamente!',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notificacaoEnviada),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showTimePicker() async {
    final settings = ref.read(notificationSettingsProvider);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.moodReminderHour, minute: settings.moodReminderMinute),
    );
    if (time != null) {
      await ref.read(notificationSettingsProvider.notifier).setMoodReminderTime(time.hour, time.minute);
    }
  }

  Future<void> _showBatteryDialog() async {
    final oem = PermissionHelper.instance.getDeviceOEM();
    if (oem != DeviceOEM.other) {
      final result = await BatteryOptimizationDialog.show(context, oem);
      if (result == true) {
        // Abrir configurações do app
        await AwesomeNotifications().showNotificationConfigPage();
      }
      await PermissionHelper.instance.markBatteryDialogShown();
      ref.read(notificationSettingsProvider.notifier).refreshPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(notificationSettingsProvider);

    if (settings.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: colorScheme.onSurface),
                    ),
                  ),
                  const Spacer(),
                  Text(AppLocalizations.of(context)!.notifications,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),
          ),

          // Permission Warning
          if (settings.permissionStatus != NotificationPermissionStatus.granted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildPermissionWarning(settings.permissionStatus),
              ),
            ),

          // Battery Optimization Warning (Android only)
          if (Platform.isAndroid && settings.permissionStatus == NotificationPermissionStatus.needsBatteryWhitelist)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildBatteryWarning(),
              ),
            ),

          // Main Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _buildMainToggle(settings),
            ),
          ),

          // Settings Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lembretes'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.mood_outlined,
                      title: 'Lembrete de Humor',
                      subtitle: 'Lembre-se de registrar seu humor diariamente',
                      value: settings.moodRemindersEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setMoodRemindersEnabled(v),
                    ),
                    if (settings.moodRemindersEnabled && settings.notificationsEnabled)
                      _buildTimeTile(
                        title: 'Horário do Lembrete',
                        time: '${settings.moodReminderHour.toString().padLeft(2, '0')}:${settings.moodReminderMinute.toString().padLeft(2, '0')}',
                        onTap: _showTimePicker,
                      ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Alertas de Streak',
                      subtitle: 'Aviso quando seu streak está em risco',
                      value: settings.streakAlertsEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setStreakAlertsEnabled(v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Timer & Pomodoro'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.timer_outlined,
                      title: 'Notificações de Timer',
                      subtitle: 'Alertas quando sessões terminam',
                      value: settings.pomodoroNotificationsEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setPomodoroNotificationsEnabled(v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Gamificação'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Conquistas e Level Up',
                      subtitle: 'Celebre seus progressos',
                      value: settings.gamificationEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setGamificationEnabled(v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Lembretes de Humor'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Lembrete Manhã',
                      subtitle: 'Registrar humor às ${settings.moodMorningHour}h',
                      value: settings.moodMorningEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setMoodMorningSettings(enabled: v),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.nights_stay_outlined,
                      title: 'Lembrete Noite',
                      subtitle: 'Registrar humor às ${settings.moodEveningHour}h',
                      value: settings.moodEveningEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setMoodEveningSettings(enabled: v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Lembretes de Hábitos'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.repeat_outlined,
                      title: 'Lembrar Hábitos Pendentes',
                      subtitle: 'A cada ${settings.habitReminderInterval} min',
                      value: settings.habitReminderEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setHabitReminderSettings(enabled: v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Lembretes de Tarefas'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.task_alt_outlined,
                      title: 'Lembrar Tarefas Pendentes',
                      subtitle: 'A cada ${settings.taskReminderInterval} min',
                      value: settings.taskReminderEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setTaskReminderSettings(enabled: v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Motivação'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'Frases Motivacionais',
                      subtitle: AppLocalizations.of(context)!.timesPerDayRandom(settings.motivationPerDay),
                      value: settings.motivationEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setMotivationSettings(enabled: v),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Teste'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.send_outlined,
                      title: 'Testar Notificação',
                      subtitle: 'Enviar notificação de teste',
                      enabled: settings.notificationsEnabled,
                      onTap: _showTestNotification,
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(NotificationPermissionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    
    String message;
    String buttonText;
    VoidCallback onPressed;
    
    switch (status) {
      case NotificationPermissionStatus.denied:
        message = 'Permissão de notificação não concedida';
        buttonText = 'Permitir';
        onPressed = () async {
          await PermissionHelper.instance.requestNotificationPermission();
          ref.read(notificationSettingsProvider.notifier).refreshPermissionStatus();
        };
        break;
      case NotificationPermissionStatus.permanentlyDenied:
        message = 'Notificações bloqueadas. Abra as configurações do app para permitir.';
        buttonText = 'Abrir Configurações';
        onPressed = () async {
          await AwesomeNotifications().showNotificationConfigPage();
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryWarning() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.battery_alert_outlined, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure a otimização de bateria para timers confiáveis',
              style: TextStyle(color: colorScheme.onTertiaryContainer, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _showBatteryDialog,
            child: Text(AppLocalizations.of(context)!.configurar),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle(NotificationSettingsState settings) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: settings.notificationsEnabled
              ? [colorScheme.primaryContainer, colorScheme.primaryContainer.withValues(alpha: 0.5)]
              : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: settings.notificationsEnabled ? colorScheme.primary : colorScheme.outline,
              shape: BoxShape.circle,
            ),
            child: Icon(
              settings.notificationsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
              color: settings.notificationsEnabled ? colorScheme.onPrimary : colorScheme.surface,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.notifications,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  settings.notificationsEnabled ? 'Ativadas' : 'Desativadas',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.notificationsEnabled,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              ref.read(notificationSettingsProvider.notifier).setNotificationsEnabled(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? colorScheme.onPrimaryContainer : colorScheme.outline,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? colorScheme.onSurface : colorScheme.outline,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
        ),
      ),
      trailing: Switch(
        value: value && enabled,
        onChanged: enabled ? (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        } : null,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? colorScheme.onPrimaryContainer : colorScheme.outline,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? colorScheme.onSurface : colorScheme.outline,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
      ),
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
        onTap();
      } : null,
    );
  }
}

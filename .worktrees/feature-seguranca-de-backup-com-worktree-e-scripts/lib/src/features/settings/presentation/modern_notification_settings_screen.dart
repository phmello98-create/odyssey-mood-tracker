import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/utils/services/modern_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Tela de configurações de notificações modernas
class ModernNotificationSettingsScreen extends ConsumerStatefulWidget {
  const ModernNotificationSettingsScreen({super.key});

  @override
  ConsumerState<ModernNotificationSettingsScreen> createState() => _ModernNotificationSettingsScreenState();
}

class _ModernNotificationSettingsScreenState extends ConsumerState<ModernNotificationSettingsScreen> {
  bool _moodRemindersEnabled = true;
  TimeOfDay _moodReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _taskRemindersEnabled = true;
  bool _habitRemindersEnabled = true;
  bool _motivationEnabled = true;
  int _motivationFrequency = 2;
  bool _pomodoroNotificationsEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _isLoading = true;
  bool _notificationsAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduler = ModernNotificationScheduler.instance;
    
    // Verificar permissões
    _notificationsAllowed = await ModernNotificationService.instance.isNotificationAllowed();
    
    // Carregar configurações
    final timeStr = prefs.getString('modern_notif_mood_time') ?? '20:00';
    final timeParts = timeStr.split(':');
    
    setState(() {
      _moodRemindersEnabled = prefs.getBool('modern_notif_mood_enabled') ?? true;
      _moodReminderTime = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 20,
        minute: int.tryParse(timeParts[1]) ?? 0,
      );
      _taskRemindersEnabled = prefs.getBool('modern_notif_task_enabled') ?? true;
      _habitRemindersEnabled = prefs.getBool('modern_notif_habit_enabled') ?? true;
      _motivationEnabled = prefs.getBool('modern_notif_motivation_enabled') ?? true;
      _motivationFrequency = prefs.getInt('modern_notif_motivation_freq') ?? 2;
      _pomodoroNotificationsEnabled = prefs.getBool('modern_notif_pomodoro_enabled') ?? true;
      _achievementNotificationsEnabled = prefs.getBool('modern_notif_achievement_enabled') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveAndUpdate(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _requestPermissions() async {
    final allowed = await ModernNotificationService.instance.requestPermissions();
    setState(() {
      _notificationsAllowed = allowed;
    });
  }

  Future<void> _selectMoodTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _moodReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _moodReminderTime = time;
      });
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await _saveAndUpdate('modern_notif_mood_time', timeStr);
      await ModernNotificationScheduler.instance.setMoodReminderTime(time.hour, time.minute);
    }
  }

  void _showFrequencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequência de Motivação',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) {
                final freq = index + 1;
                return ListTile(
                  leading: Radio<int>(
                    value: freq,
                    groupValue: _motivationFrequency,
                    onChanged: (value) async {
                      setState(() {
                        _motivationFrequency = value!;
                      });
                      await _saveAndUpdate('modern_notif_motivation_freq', value!);
                      await ModernNotificationScheduler.instance.setMotivationFrequency(value);
                      Navigator.pop(context);
                    },
                  ),
                  title: Text('$freq vez${freq > 1 ? 'es' : ''} por dia'),
                  onTap: () async {
                    setState(() {
                      _motivationFrequency = freq;
                    });
                    await _saveAndUpdate('modern_notif_motivation_freq', freq);
                    await ModernNotificationScheduler.instance.setMotivationFrequency(freq);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _testNotification(String type) async {
    switch (type) {
      case 'mood':
        await ModernNotificationService.instance.sendMoodReminder(
          title: '💭 Teste de Notificação',
          body: 'Notificação de humor funcionando!',
        );
        break;
      case 'task':
        await ModernNotificationService.instance.sendTaskReminder(
          taskId: 999,
          taskTitle: 'Tarefa de Teste',
          taskDescription: 'Esta é uma notificação de teste',
        );
        break;
      case 'habit':
        await ModernNotificationService.instance.sendHabitReminder(
          habitId: 999,
          habitName: 'Hábito de Teste',
          habitDescription: 'Notificação de teste',
          streak: 7,
        );
        break;
      case 'pomodoro':
        await ModernNotificationService.instance.sendPomodoroComplete(
          sessionNumber: 1,
          totalMinutes: 25,
        );
        break;
      case 'achievement':
        await ModernNotificationService.instance.sendAchievementUnlocked(
          achievementName: 'Teste de Conquista',
          achievementDescription: 'Você testou as notificações!',
          xpReward: 50,
        );
        break;
      case 'motivation':
        await ModernNotificationService.instance.sendMotivationalNotification(
          title: '💪 Teste Motivacional',
          body: 'Você está indo muito bem! Continue assim!',
        );
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notificacaoDeTesteEnviada),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.notificacoes)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificacoes),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Testar notificações',
            onPressed: () {
              _showTestMenu();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Status de Permissões
          if (!_notificationsAllowed) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações Desativadas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ative as notificações para receber lembretes.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    child: Text(AppLocalizations.of(context)!.ativar),
                  ),
                ],
              ),
            ),
          ],

          // Seção: Lembretes de Humor
          _buildSectionHeader('Humor', Icons.mood, const Color(0xFF7C3AED)),
          _buildSwitchTile(
            title: 'Lembrete de Humor',
            subtitle: 'Lembrete diário para registrar seu humor',
            value: _moodRemindersEnabled,
            onChanged: (value) async {
              setState(() => _moodRemindersEnabled = value);
              await _saveAndUpdate('modern_notif_mood_enabled', value);
              await ModernNotificationScheduler.instance.setMoodReminderEnabled(value);
            },
          ),
          if (_moodRemindersEnabled)
            _buildTimeTile(
              title: 'Horário do Lembrete',
              time: _moodReminderTime,
              onTap: _selectMoodTime,
            ),

          const Divider(height: 32),

          // Seção: Tarefas
          _buildSectionHeader('Tarefas', Icons.task_alt, const Color(0xFF2196F3)),
          _buildSwitchTile(
            title: 'Lembretes de Tarefas',
            subtitle: 'Notificações de tarefas pendentes e atrasadas',
            value: _taskRemindersEnabled,
            onChanged: (value) async {
              setState(() => _taskRemindersEnabled = value);
              await _saveAndUpdate('modern_notif_task_enabled', value);
              await ModernNotificationScheduler.instance.setTaskReminderEnabled(value);
            },
          ),

          const Divider(height: 32),

          // Seção: Hábitos
          _buildSectionHeader('Hábitos', Icons.repeat, const Color(0xFF4CAF50)),
          _buildSwitchTile(
            title: 'Lembretes de Hábitos',
            subtitle: 'Notificações de hábitos pendentes do dia',
            value: _habitRemindersEnabled,
            onChanged: (value) async {
              setState(() => _habitRemindersEnabled = value);
              await _saveAndUpdate('modern_notif_habit_enabled', value);
              await ModernNotificationScheduler.instance.setHabitReminderEnabled(value);
            },
          ),

          const Divider(height: 32),

          // Seção: Timer Pomodoro
          _buildSectionHeader('Timer Pomodoro', Icons.timer, const Color(0xFFFF5722)),
          _buildSwitchTile(
            title: 'Notificações do Timer',
            subtitle: 'Aviso quando completar sessão ou pausa',
            value: _pomodoroNotificationsEnabled,
            onChanged: (value) async {
              setState(() => _pomodoroNotificationsEnabled = value);
              await _saveAndUpdate('modern_notif_pomodoro_enabled', value);
            },
          ),

          const Divider(height: 32),

          // Seção: Conquistas
          _buildSectionHeader('Conquistas', Icons.emoji_events, const Color(0xFFFFB300)),
          _buildSwitchTile(
            title: 'Notificações de Conquistas',
            subtitle: 'Aviso ao desbloquear conquistas e subir de nível',
            value: _achievementNotificationsEnabled,
            onChanged: (value) async {
              setState(() => _achievementNotificationsEnabled = value);
              await _saveAndUpdate('modern_notif_achievement_enabled', value);
            },
          ),

          const Divider(height: 32),

          // Seção: Motivação
          _buildSectionHeader('Motivação', Icons.auto_awesome, const Color(0xFFE91E63)),
          _buildSwitchTile(
            title: 'Mensagens Motivacionais',
            subtitle: 'Frases inspiradoras ao longo do dia',
            value: _motivationEnabled,
            onChanged: (value) async {
              setState(() => _motivationEnabled = value);
              await _saveAndUpdate('modern_notif_motivation_enabled', value);
              await ModernNotificationScheduler.instance.setMotivationEnabled(value);
            },
          ),
          if (_motivationEnabled)
            _buildFrequencyTile(
              title: 'Frequência',
              frequency: _motivationFrequency,
              onTap: _showFrequencyPicker,
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showTestMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Testar Notificações',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha o tipo de notificação para testar:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTestChip('💭 Humor', 'mood', const Color(0xFF7C3AED)),
                  _buildTestChip('✅ Tarefa', 'task', const Color(0xFF2196F3)),
                  _buildTestChip('💪 Hábito', 'habit', const Color(0xFF4CAF50)),
                  _buildTestChip('⏰ Pomodoro', 'pomodoro', const Color(0xFFFF5722)),
                  _buildTestChip('🏆 Conquista', 'achievement', const Color(0xFFFFB300)),
                  _buildTestChip('✨ Motivação', 'motivation', const Color(0xFFE91E63)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestChip(String label, String type, Color color) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(Icons.send, size: 14, color: color),
      ),
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _testNotification(type);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _notificationsAllowed ? onChanged : null,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const SizedBox(width: 24),
      title: Text(title),
      subtitle: Text(time.format(context)),
      trailing: const Icon(Icons.access_time),
      onTap: _notificationsAllowed ? onTap : null,
    );
  }

  Widget _buildFrequencyTile({
    required String title,
    required int frequency,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const SizedBox(width: 24),
      title: Text(title),
      subtitle: Text('$frequency vez${frequency > 1 ? 'es' : ''} por dia'),
      trailing: const Icon(Icons.tune),
      onTap: _notificationsAllowed ? onTap : null,
    );
  }
}

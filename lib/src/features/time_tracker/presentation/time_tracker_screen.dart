import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class TimeTrackerScreen extends ConsumerStatefulWidget {
  const TimeTrackerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends ConsumerState<TimeTrackerScreen>
    with TickerProviderStateMixin {
  // Showcase keys
  final GlobalKey _showcaseTasks = GlobalKey();
  // Showcase keys
  final GlobalKey _showcasePlay = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseTimer = GlobalKey();
  // Timer state
  Activity? _selectedActivity;
  String? _customTaskName;
  String? _selectedCategory;
  String? _selectedProject;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();

  // Pomodoro state
  bool _isPomodoroMode = false; // Começa no modo livre (Task view)
  bool _isPomodoroRunning = false;
  bool _isPomodoroBreak = false;
  int _pomodoroSessions = 0;
  int _pomodoroTotalSessions = 4; // Meta de sessões
  Timer? _pomodoroTimer;
  Duration _pomodoroTimeLeft = const Duration(minutes: 25);
  Duration _pomodoroDuration = const Duration(minutes: 25);
  Duration _shortBreakDuration = const Duration(minutes: 5);
  Duration _longBreakDuration = const Duration(minutes: 15);
  bool _showPomodoroScreen = false; // Nova tela de Pomodoro
  
  // View state
  bool _showProductivity = false;
  bool _showWeekStats = false;
  bool _showFullscreenTimer = false; // Nova variável para controlar tela cheia
  
  // Tab state - 0 = Tempo Livre, 1 = Pomodoro
  int _selectedTab = 0;
  late TabController _tabController;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late AnimationController _appleController;
  late Animation<double> _appleAnimation;

  // Predefined activities with colors (editáveis)
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Desenvolvimento App', 'icon': Icons.phone_android, 'color': const Color(0xFF9B51E0), 'category': 'Trabalho', 'project': 'Odyssey'},
    {'name': 'Reunião de equipe', 'icon': Icons.groups, 'color': const Color(0xFFFFA556), 'category': 'Trabalho', 'project': 'Odyssey'},
    {'name': 'Estudar Flutter', 'icon': Icons.code, 'color': const Color(0xFFFD5B71), 'category': 'Estudo', 'project': 'Aprendizado'},
    {'name': 'Leitura', 'icon': Icons.menu_book, 'color': const Color(0xFF07E092), 'category': 'Pessoal', 'project': 'Leitura'},
    {'name': 'Exercícios', 'icon': Icons.fitness_center, 'color': const Color(0xFFFF6B6B), 'category': 'Saúde', 'project': 'Fitness'},
    {'name': 'Meditação', 'icon': Icons.self_improvement, 'color': UltravioletColors.accentPink, 'category': 'Pessoal', 'project': null},
  ];
  
  // Categorias disponíveis (editáveis)
  final List<String> _categories = ['Trabalho', 'Pessoal', 'Estudo', 'Saúde', 'Outros'];

  @override
  void initState() {
    super.initState();
    _initShowcase();
    
    // Tab controller para as abas
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _appleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _appleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appleController, curve: Curves.easeInOut),
    );
    
    // Sincronizar com o provider global na inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithGlobalTimer();
      _addSampleData();
    });
  }
  
  void _addSampleData() async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final records = repo.fetchAllTimeTrackingRecords();
    
    // Se já tem dados suficientes (>20), não adiciona mais
    if (records.length > 20) return;
    
    // Limpar dados antigos para recrear com dados novos
    for (final r in records) {
      await repo.deleteTimeTrackingRecord(r.id);
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Criar dados para toda a semana
    final sampleRecords = <TimeTrackingRecord>[];
    int idCounter = 1;
    
    // Dados para cada dia da semana (últimos 7 dias)
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final day = today.subtract(Duration(days: dayOffset));
      
      // Variar quantidade de tarefas por dia
      final numTasks = dayOffset == 0 ? 4 : (dayOffset % 3) + 2; // Mais tarefas hoje
      
      for (int taskIndex = 0; taskIndex < numTasks; taskIndex++) {
        final taskVariants = [
          {'name': 'Desenvolvimento App', 'icon': Icons.phone_android, 'color': const Color(0xFF9B51E0), 'cat': 'Trabalho', 'proj': 'Odyssey'},
          {'name': 'Reunião de equipe', 'icon': Icons.groups, 'color': const Color(0xFFFFA556), 'cat': 'Trabalho', 'proj': 'Odyssey'},
          {'name': 'Estudar Flutter', 'icon': Icons.code, 'color': const Color(0xFFFD5B71), 'cat': 'Estudo', 'proj': 'Aprendizado'},
          {'name': 'Leitura', 'icon': Icons.menu_book, 'color': const Color(0xFF07E092), 'cat': 'Pessoal', 'proj': 'Leitura'},
          {'name': 'Exercícios', 'icon': Icons.fitness_center, 'color': const Color(0xFFFF6B6B), 'cat': 'Saúde', 'proj': 'Fitness'},
          {'name': 'Meditação', 'icon': Icons.self_improvement, 'color': const Color(0xFF9B51E0), 'cat': 'Saúde', 'proj': null},
          {'name': 'Design UI', 'icon': Icons.design_services, 'color': const Color(0xFF00B4D8), 'cat': 'Trabalho', 'proj': 'Odyssey'},
        ];
        
        final task = taskVariants[(dayOffset + taskIndex) % taskVariants.length];
        final durationMinutes = 30 + (taskIndex * 20) + (dayOffset * 10) % 90; // 30-120 min variável
        final startHour = 8 + (taskIndex * 2);
        
        sampleRecords.add(TimeTrackingRecord(
          id: '${idCounter++}',
          activityName: task['name'] as String,
          iconCode: (task['icon'] as IconData).codePoint,
          startTime: day.add(Duration(hours: startHour)),
          endTime: day.add(Duration(hours: startHour, minutes: durationMinutes)),
          duration: Duration(minutes: durationMinutes),
          category: task['cat'] as String,
          project: task['proj'] as String?,
          isCompleted: dayOffset > 0 || taskIndex < 2, // Hoje: só 2 primeiras concluídas
          colorValue: (task['color'] as Color).value,
        ));
      }
    }
    
    for (final record in sampleRecords) {
      await repo.addTimeTrackingRecord(record);
    }
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.timeTracker);
    // NÃO cancelar o timer aqui - ele deve continuar rodando no provider global
    _notesController.dispose();
    _taskNameController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _appleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Sincroniza o estado local com o provider global do timer
  void _syncWithGlobalTimer() {
    final timerState = ref.read(timerProvider);
    if (timerState.isRunning) {
      setState(() {
        _isRunning = true;
        _startTime = timerState.startTime;
        _elapsedTime = timerState.elapsed;
        _customTaskName = timerState.taskName;
        _selectedCategory = timerState.category;
        _selectedProject = timerState.project;
        _isPomodoroMode = timerState.isPomodoroMode;
        _isPomodoroRunning = timerState.isPomodoroMode && timerState.isRunning;
        _isPomodoroBreak = timerState.isPomodoroBreak;
        _pomodoroTimeLeft = timerState.pomodoroTimeLeft;
        _pomodoroSessions = timerState.pomodoroSessions;
      });
      
      // Reiniciar animação de pulso
      _pulseController.repeat(reverse: true);
    }
  }

  void _startTimer({Activity? activity, String? customTask}) {
    final taskName = customTask ?? _taskNameController.text;
    
    // Pegar cor e ícone da atividade
    final activityData = _activities.firstWhere(
      (a) => a['name'] == taskName,
      orElse: () => {'icon': Icons.timer, 'color': UltravioletColors.primary},
    );
    final color = activityData['color'] as Color;
    final icon = activityData['icon'] as IconData;
    
    // Usar o provider global para iniciar o timer
    ref.read(timerProvider.notifier).startTimer(
      taskName: taskName,
      category: _selectedCategory,
      project: _selectedProject,
      iconCode: activity?.iconCode ?? icon.codePoint,
      colorValue: color.value,
    );
    
    // Atualizar estado local para UI
    setState(() {
      _selectedActivity = activity;
      _customTaskName = taskName;
      _startTime = DateTime.now();
      _isRunning = true;
      _elapsedTime = Duration.zero;
    });

    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopTimer() async {
    // Obter estado final do provider global
    final timerState = ref.read(timerProvider.notifier).stopTimer();
    
    if (timerState.isRunning || _isRunning) {
      final activityName = timerState.taskName ?? _customTaskName ?? 'Timer';
      final elapsed = timerState.elapsed.inSeconds > 0 ? timerState.elapsed : _elapsedTime;
      final startTime = timerState.startTime ?? _startTime ?? DateTime.now().subtract(elapsed);
      final endTime = DateTime.now();
      
      // Pegar cor da atividade selecionada
      final activityData = _activities.firstWhere(
        (a) => a['name'] == activityName,
        orElse: () => {'icon': Icons.timer, 'color': UltravioletColors.primary},
      );
      final color = timerState.colorValue != null 
          ? Color(timerState.colorValue!) 
          : activityData['color'] as Color;
      
      final record = TimeTrackingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityName: activityName,
        iconCode: timerState.iconCode ?? _selectedActivity?.iconCode ?? (activityData['icon'] as IconData).codePoint,
        startTime: startTime,
        endTime: endTime,
        duration: elapsed,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        category: timerState.category ?? _selectedCategory,
        project: timerState.project ?? _selectedProject,
        isCompleted: false,
        colorValue: color.value,
      );

      final repository = ref.read(timeTrackingRepositoryProvider);
      repository.addTimeTrackingRecord(record);

      _pulseController.stop();
      _pulseController.reset();

      HapticFeedback.heavyImpact();

      // XP baseado no tempo e gamificação
      final minutes = elapsed.inMinutes;
      final xp = (minutes / 5).floor() * 5;
      
      // Feedback melhorado com nome da tarefa
      FeedbackService.showFocusSessionComplete(context, activityName, minutes, xp: xp > 0 ? xp : null);
      
      try {
        final gamificationRepo = ref.read(gamificationRepositoryProvider);
        final gamResult = await gamificationRepo.trackTime(minutes);
        final newBadges = gamResult.newBadges;
        
        // Mostra badge se desbloqueou
        if (newBadges.isNotEmpty && mounted) {
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) {
              FeedbackService.showAchievement(
                context, 
                '${newBadges.first.icon} ${newBadges.first.name}',
                newBadges.first.description,
              );
            }
          });
        }
        
        // Notificação de sessão completa
        if (minutes >= 15) {
          NotificationService.instance.showPomodoroComplete(activityName, minutes);
        }
      } catch (e) {
        // Gamificação falhou mas o registro foi salvo
        debugPrint('Error updating gamification: $e');
      }

      setState(() {
        _isRunning = false;
        _selectedActivity = null;
        _customTaskName = null;
        _selectedCategory = null;
        _selectedProject = null;
        _elapsedTime = Duration.zero;
        _startTime = null;
      });
      _notesController.clear();
      _taskNameController.clear();
      
      // Parar sons do timer
      soundService.stopTimerSounds();
      
      // Cancelar notificação do timer já foi feito no provider
    }
  }

  void _resetTimer() {
    // Usar o provider global para resetar
    ref.read(timerProvider.notifier).resetTimer();
    
    // Parar sons do timer
    soundService.stopTimerSounds();
    
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      _isRunning = false;
      _selectedActivity = null;
      _customTaskName = null;
      _startTime = null;
      _elapsedTime = Duration.zero;
    });
  }

  // Pomodoro methods
  void _startPomodoro() {
    soundService.playTimerStart(); // Som de início
    final taskName = _customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa';
    
    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = _pomodoroDuration;
    });

    // Agendar notificação de conclusão
    NotificationService.instance.schedulePomodoroTimer(
      _pomodoroDuration, 
      taskName
    );
    
    // Mostrar notificação persistente do Pomodoro
    NotificationService.instance.showTimerRunningNotification(
      taskName: taskName,
      elapsed: Duration.zero,
      isPomodoro: true,
      pomodoroTimeLeft: _pomodoroDuration,
    );

    _pulseController.repeat(reverse: true);

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isPomodoroRunning) {
        setState(() {
          _pomodoroTimeLeft = _pomodoroTimeLeft - const Duration(seconds: 1);

          // Atualizar notificação a cada 30 segundos
          if (_pomodoroTimeLeft.inSeconds % 30 == 0) {
            NotificationService.instance.updateTimerNotification(
              taskName: taskName,
              elapsed: _pomodoroDuration - _pomodoroTimeLeft,
              isPomodoro: true,
              pomodoroTimeLeft: _pomodoroTimeLeft,
            );
          }

          if (_pomodoroTimeLeft.inSeconds <= 0) {
            _pomodoroTimer?.cancel();
            _pulseController.stop();
            NotificationService.instance.cancelTimerNotification();
            
            if (!_isPomodoroBreak) {
              _pomodoroSessions++;
              _showPomodoroComplete();
            } else {
              _startPomodoro();
            }
          }
        });
      }
    });
  }

  void _pausePomodoro() {
    setState(() {
      _isPomodoroRunning = false;
    });
    _pomodoroTimer?.cancel();
    _pulseController.stop();
    NotificationService.instance.cancelPomodoroTimer();
    NotificationService.instance.cancelTimerNotification();
    // Parar sons do timer
    soundService.stopTimerSounds();
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    NotificationService.instance.cancelPomodoroTimer();
    NotificationService.instance.cancelTimerNotification();
    // Parar sons do timer
    soundService.stopTimerSounds();
    setState(() {
      _isPomodoroRunning = false;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = _pomodoroDuration;
    });
  }

  void _startBreak() {
    // Verificar se é pausa longa (após completar todas as sessões)
    final isLongBreak = _pomodoroSessions >= _pomodoroTotalSessions;
    final breakDuration = isLongBreak ? _longBreakDuration : _shortBreakDuration;
    
    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = true;
      _pomodoroTimeLeft = breakDuration;
      // Se completou todas as sessões, resetar contador
      if (isLongBreak) {
        _pomodoroSessions = 0;
      }
    });

    // Agendar notificação de fim da pausa
    NotificationService.instance.scheduleBreakTimer(breakDuration);

    _pulseController.repeat(reverse: true);

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPomodoroRunning) {
        setState(() {
          _pomodoroTimeLeft = _pomodoroTimeLeft - const Duration(seconds: 1);
          if (_pomodoroTimeLeft.inSeconds <= 0) {
            _pomodoroTimer?.cancel();
            _pulseController.stop();
            HapticFeedback.mediumImpact();
            // Notificar que a pausa acabou
            FeedbackService.showSuccess(context, '☕ Pausa finalizada! Hora de focar 🍅');
            _startPomodoro();
          }
        });
      }
    });
  }

  void _showPomodoroComplete() {
    HapticFeedback.heavyImpact();
    soundService.playTimerEnd(); // Som do timer terminando
    
    // Verificar se é hora de pausa longa
    final isLongBreak = _pomodoroSessions >= _pomodoroTotalSessions;
    final breakDuration = isLongBreak ? _longBreakDuration : _shortBreakDuration;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animação de celebração
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Text('🍅', style: TextStyle(fontSize: 64)),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              isLongBreak ? 'Parabéns! Meta atingida! 🎉' : 'Pomodoro Concluído!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: UltravioletColors.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+25 XP',
                style: TextStyle(
                  color: UltravioletColors.accentGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Maçãs indicando progresso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pomodoroTotalSessions, (index) {
                final isCompleted = index < _pomodoroSessions;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '🍅',
                    style: TextStyle(
                      fontSize: 20,
                      color: isCompleted ? null : Colors.white.withOpacity(0.2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$_pomodoroSessions de $_pomodoroTotalSessions sessões',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: UltravioletColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPomodoroRunning = false;
                _pomodoroTimeLeft = _pomodoroDuration;
              });
            },
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startBreak();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
            ),
            child: Text(
              isLongBreak 
                  ? 'Pausa Longa (${_longBreakDuration.inMinutes}min)' 
                  : 'Pausa (${_shortBreakDuration.inMinutes}min)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    // Gamificação
    try {
      final gamificationRepo = ref.read(gamificationRepositoryProvider);
      gamificationRepo.completeTask();
    } catch (e) {
      // Ignore
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours.remainder(24));
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDurationShort(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getActivityColor(String? activityName) {
    if (activityName == null) return UltravioletColors.primary;
    final activity = _activities.firstWhere(
      (a) => a['name'] == activityName,
      orElse: () => {'color': UltravioletColors.primary},
    );
    return activity['color'] as Color;
  }
  void _initShowcase() {
    final keys = [_showcaseTimer, _showcasePlay, _showcaseTasks];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.timeTracker,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.timeTracker, keys);
  }
  
  void _startTour() {
    final keys = [_showcaseTimer, _showcasePlay, _showcaseTasks];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.timeTracker, keys);
  }


  @override
  Widget build(BuildContext context) {
    // Escutar o provider global do timer para atualizar a UI
    final timerState = ref.watch(timerProvider);

    // Verificar se deve abrir a tela do Pomodoro (vindo do QuickPomodoroWidget)
    if (timerState.shouldOpenPomodoroScreen && !_showPomodoroScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Sincronizar o tempo do pomodoro local com o provider
          final notifier = ref.read(timerProvider.notifier);
          setState(() {
            _showPomodoroScreen = true;
            _selectedTab = 1; // Ir para aba Pomodoro
            _tabController.animateTo(1);
            _pomodoroDuration = notifier.pomodoroDuration;
            _pomodoroTimeLeft = notifier.pomodoroDuration;
          });
          // Limpar a flag para não reabrir novamente
          notifier.clearPomodoroScreenFlag();
        }
      });
    }

    // Sincronizar estado local com o provider global
    if (timerState.isRunning && !_isRunning) {
      // Timer foi iniciado em outro lugar ou restaurado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isRunning = true;
            _startTime = timerState.startTime;
            _elapsedTime = timerState.elapsed;
            _customTaskName = timerState.taskName;
            _selectedCategory = timerState.category;
            _selectedProject = timerState.project;
          });
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        }
      });
    } else if (!timerState.isRunning && _isRunning) {
      // Timer foi parado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isRunning = false;
          });
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    } else if (timerState.isRunning) {
      // Atualizar tempo do provider
      _elapsedTime = timerState.elapsed;
    }
    
    // Se estiver no modo de timer ativo E quiser ver tela cheia
    if (_showFullscreenTimer && (_isRunning || _isPomodoroRunning)) {
      return _buildActiveTimerScreen();
    }
    
    // Se estiver na tela de produtividade
    if (_showProductivity) {
      return _buildProductivityScreen();
    }
    
    // Tela principal com abas modernas
    return _buildMainScreen();
  }

  // =====================================================
  // MAIN SCREEN - Tela principal com abas modernas
  // =====================================================
  Widget _buildMainScreen() {
    return SafeArea(
      child: Column(
        children: [
          // Header com título e Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Timer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: UltravioletColors.onSurface,
                  ),
                ),
                // Botão Stats
                GestureDetector(
                  onTap: () => setState(() => _showProductivity = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: UltravioletColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: UltravioletColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Stats',
                          style: TextStyle(
                            color: UltravioletColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar moderna com indicador elegante
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: UltravioletColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: _selectedTab == 0
                        ? [UltravioletColors.primary, UltravioletColors.secondary]
                        : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedTab == 0 
                          ? UltravioletColors.primary 
                          : const Color(0xFFFF6B6B)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: UltravioletColors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text('Tempo Livre'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🍅', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text('Pomodoro'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Aba 1: Tempo Livre
                _buildFreeTimeTab(),
                // Aba 2: Pomodoro
                _buildPomodoroTab(),
              ],
            ),
          ),

          // Bottom Navigation Bar
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  // =====================================================
  // FREE TIME TAB - Aba de Tempo Livre
  // =====================================================
  Widget _buildFreeTimeTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Timer Card atual
        _buildCurrentTimerCard(),
        const SizedBox(height: 16),
        // Lista de tarefas
        Expanded(
          child: _buildTodayTasksList(),
        ),
      ],
    );
  }

  // =====================================================
  // POMODORO TAB - Aba de Pomodoro com timer de tomate
  // =====================================================
  Widget _buildPomodoroTab() {
    final progress = 1 - (_pomodoroTimeLeft.inSeconds / _pomodoroDuration.inSeconds);
    final taskName = _customTaskName ?? _selectedActivity?.activityName;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Timer de Tomate com relógio de ponteiro
          _buildTomatoClockTimer(progress),
          
          const SizedBox(height: 24),
          
          // Controles do Pomodoro
          _buildModernPomodoroControls(),
          
          const SizedBox(height: 24),
          
          // Stats do Pomodoro
          _buildPomodoroQuickStats(),
          
          const SizedBox(height: 16),
          
          // Seletor de tarefa rápido
          _buildQuickTaskSelector(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Timer de Tomate estilo relógio de ponteiro
  Widget _buildTomatoClockTimer(double progress) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (_isPomodoroRunning) {
          _pausePomodoro();
        } else {
          _startPomodoro();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _isPomodoroRunning ? _pulseAnimation.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: 280,
          height: 320,
          child: CustomPaint(
            painter: _TomatoClockPainter(
              progress: progress,
              isBreak: _isPomodoroBreak,
              isRunning: _isPomodoroRunning,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_isPomodoroBreak 
                            ? const Color(0xFF3498DB) 
                            : const Color(0xFFE74C3C)).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isPomodoroBreak ? '☕ PAUSA' : '🔥 FOCO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isPomodoroBreak 
                              ? const Color(0xFF3498DB) 
                              : const Color(0xFFE74C3C),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tempo
                    Text(
                      _formatDurationShort(_pomodoroTimeLeft),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: UltravioletColors.onSurface,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'minutos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: UltravioletColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Controles modernos do Pomodoro
  Widget _buildModernPomodoroControls() {
    final color = _isPomodoroBreak ? const Color(0xFF3498DB) : const Color(0xFFE74C3C);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _buildPomodoroControlButton(
          icon: Icons.refresh_rounded,
          onTap: _resetPomodoro,
          isSmall: true,
        ),
        
        const SizedBox(width: 24),
        
        // Play/Pause principal
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_isPomodoroRunning) {
              _pausePomodoro();
            } else {
              _startPomodoro();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isPomodoroRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Skip/Settings
        _buildPomodoroControlButton(
          icon: Icons.skip_next_rounded,
          onTap: _skipPomodoroSession,
          isSmall: true,
        ),
      ],
    );
  }

  Widget _buildPomodoroControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: isSmall ? 56 : 72,
        height: isSmall ? 56 : 72,
        decoration: const BoxDecoration(
          color: UltravioletColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: UltravioletColors.onSurfaceVariant,
          size: isSmall ? 24 : 32,
        ),
      ),
    );
  }

  void _skipPomodoroSession() {
    if (_isPomodoroRunning || _pomodoroTimeLeft.inSeconds < _pomodoroDuration.inSeconds) {
      _pomodoroTimer?.cancel();
      _pulseController.stop();
      if (!_isPomodoroBreak) {
        setState(() {
          _pomodoroSessions++;
          _isPomodoroRunning = false;
        });
        _showPomodoroComplete();
      } else {
        setState(() {
          _isPomodoroBreak = false;
          _isPomodoroRunning = false;
          _pomodoroTimeLeft = _pomodoroDuration;
        });
      }
    }
  }

  // Stats rápidas do Pomodoro
  Widget _buildPomodoroQuickStats() {
    final focusMinutes = _pomodoroSessions * _pomodoroDuration.inMinutes;
    final hours = focusMinutes ~/ 60;
    final mins = focusMinutes % 60;
    
    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            emoji: '🍅',
            value: '$_pomodoroSessions',
            label: 'Sessões',
          ),
          Container(width: 1, height: 40, color: UltravioletColors.divider),
          _buildStatItem(
            emoji: '⏱️',
            value: hours > 0 ? '${hours}h${mins}m' : '${mins}m',
            label: 'Focado',
          ),
          Container(width: 1, height: 40, color: UltravioletColors.divider),
          _buildStatItem(
            emoji: '🎯',
            value: '$_pomodoroTotalSessions',
            label: 'Meta',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: UltravioletColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: UltravioletColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // Seletor de tarefa rápido
  Widget _buildQuickTaskSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tarefa atual',
              style: TextStyle(
                color: UltravioletColors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: _showPomodoroSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: UltravioletColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_outlined, size: 16, color: UltravioletColors.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text(
                      'Config',
                      style: TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Lista horizontal de tarefas rápidas
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final isSelected = _customTaskName == activity['name'];
              final color = activity['color'] as Color;
              
              return Padding(
                padding: EdgeInsets.only(right: index < _activities.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _customTaskName = activity['name'] as String;
                      _selectedCategory = activity['category'] as String?;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : UltravioletColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: color, width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activity['icon'] as IconData,
                          color: isSelected ? color : UltravioletColors.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (activity['name'] as String).length > 15 
                              ? '${(activity['name'] as String).substring(0, 12)}...'
                              : activity['name'] as String,
                          style: TextStyle(
                            color: isSelected ? color : UltravioletColors.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =====================================================
  // LEGACY - Task Screen (não usado mais, mantido para referência)
  // =====================================================
  Widget _buildTaskScreen() {
    return _buildMainScreen();
  }

  Widget _buildCurrentTimerCard() {
    final hasSelectedTask = _taskNameController.text.isNotEmpty;
    final taskName = _isRunning 
        ? (_customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa')
        : (_taskNameController.text.isEmpty ? 'Selecione uma tarefa' : _taskNameController.text);
    final taskColor = _isRunning 
        ? _getActivityColor(_customTaskName ?? _selectedActivity?.activityName)
        : (hasSelectedTask ? _getActivityColor(_taskNameController.text) : UltravioletColors.primary);
    
    // Calcular tempo total do dia
    final repo = ref.watch(timeTrackingRepositoryProvider);
    
    return ValueListenableBuilder(
      valueListenable: repo.box.listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final todayRecords = box.values
            .cast<TimeTrackingRecord>()
            .where((r) => _isSameDay(r.startTime, today))
            .toList();
        
        final totalSeconds = todayRecords.fold<int>(
          0, (sum, r) => sum + r.durationInSeconds,
        );
        final totalDuration = Duration(seconds: totalSeconds);
        
        // Se o timer está rodando, mostrar o tempo do timer atual
        final displayTime = _isRunning ? _elapsedTime : totalDuration;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OdysseyCard(
            onTap: _isRunning 
                ? () => setState(() => _showFullscreenTimer = true)
                : (hasSelectedTask ? () => _startTimer(customTask: _taskNameController.text) : null),
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.zero,
            gradientColors: _isRunning 
                ? [taskColor.withOpacity(0.15), taskColor.withOpacity(0.05)]
                : [const Color(0xFF0D0D15), const Color(0xFF151520)],
            borderColor: _isRunning ? taskColor.withOpacity(0.5) : (hasSelectedTask ? taskColor.withOpacity(0.3) : Colors.transparent),
            borderWidth: _isRunning ? 2 : 1,
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tempo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRunning) ...[
                            // Indicador de timer ativo
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: UltravioletColors.accentGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: UltravioletColors.accentGreen.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatDuration(displayTime),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _isRunning ? 40 : 36,
                                  fontWeight: _isRunning ? FontWeight.w400 : FontWeight.w300,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRunning) ...[
                      // Botões quando timer ativo
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botão expandir
                          GestureDetector(
                            onTap: () => setState(() => _showFullscreenTimer = true),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botão parar
                          GestureDetector(
                            onTap: _stopTimer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: UltravioletColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stop, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Parar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (hasSelectedTask) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: taskColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Iniciar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Tarefa selecionada
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_isRunning || hasSelectedTask) ? taskColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        taskName,
                        style: TextStyle(
                          color: (_isRunning || hasSelectedTask) ? Colors.white : Colors.white60,
                          fontSize: 15,
                          fontWeight: (_isRunning || hasSelectedTask) ? FontWeight.w500 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Projeto selecionado
                if (_selectedProject != null || _selectedCategory != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 20), // Alinhamento com o texto acima
                      if (_selectedCategory != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedCategory!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (_selectedProject != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: taskColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedProject!,
                            style: TextStyle(
                              color: taskColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksList() {
    final repo = ref.watch(timeTrackingRepositoryProvider);
    
    return ValueListenableBuilder(
      valueListenable: repo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        final allRecords = box.values.cast<TimeTrackingRecord>().toList();
        allRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
        
        final todayRecords = allRecords.where((r) => _isSameDay(r.startTime, now)).toList();
        final yesterdayRecords = allRecords.where((r) => _isSameDay(r.startTime, yesterday)).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hoje',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllTasksDialog(context, allRecords),
                    child: Text(
                      'Ver Tudo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Lista de tarefas
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Tarefas de hoje
                    if (todayRecords.isNotEmpty) ...[
                      ...todayRecords.map((r) => _buildRecordCard(r)),
                    ] else ...[
                      // Se não há registros hoje, mostra sugestões
                      ...(_activities.take(4).map((a) => _buildTaskCard(a, isPreset: true))),
                    ],
                    
                    // Tarefas de ontem
                    if (yesterdayRecords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Ontem',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...yesterdayRecords.take(3).map((r) => _buildRecordCard(r)),
                    ],
                    
                    // Sugestões de tarefas (se há pouco registro)
                    if (todayRecords.length < 2) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Sugestões',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_activities.skip(todayRecords.length).take(3).map((a) => _buildTaskCard(a, isPreset: true))),
                    ],
                    
                    const SizedBox(height: 100), // Padding para bottom nav
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllTasksDialog(BuildContext context, List<TimeTrackingRecord> allRecords) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UltravioletColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: UltravioletColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${allRecords.length} registros',
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Lista
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
              child: allRecords.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: UltravioletColors.onSurfaceVariant.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhum registro ainda',
                            style: TextStyle(color: UltravioletColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: allRecords.length > 15 ? 15 : allRecords.length, // Limita para abrir mais rápido
                      itemBuilder: (context, index) {
                        final record = allRecords[index];
                        final showDateHeader = index == 0 || 
                            !_isSameDay(record.startTime, allRecords[index - 1].startTime);
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDateHeader) ...[
                              if (index > 0) const SizedBox(height: 12),
                              Text(
                                _formatDateHeader(record.startTime),
                                style: const TextStyle(
                                  color: UltravioletColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            _buildRecordCard(record),
                          ],
                        );
                      },
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hoje';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Ontem';
    return DateFormat('EEEE, d MMM', 'pt_BR').format(date);
  }

  Widget _buildTaskCard(Map<String, dynamic> activity, {bool isPreset = false}) {
    final color = activity['color'] as Color;
    final name = activity['name'] as String;
    final icon = activity['icon'] as IconData;
    final category = activity['category'] as String?;
    final project = activity['project'] as String?;
    final isSelected = _taskNameController.text == name;

    return OdysseyCard(
      onTap: () {
        setState(() {
          if (isSelected) {
            // Deselect
            _taskNameController.text = '';
            _selectedCategory = null;
            _selectedProject = null;
          } else {
            // Select
            _taskNameController.text = name;
            _selectedCategory = category;
            _selectedProject = project;
          }
        });
      },
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: isSelected ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
      borderColor: isSelected ? color : Colors.transparent,
      borderWidth: 1.5,
      borderRadius: 12,
      child: Row(
        children: [
            // Checkbox circular
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _taskNameController.text = '';
                    _selectedCategory = null;
                    _selectedProject = null;
                  } else {
                    _taskNameController.text = name;
                    _selectedCategory = category;
                    _selectedProject = project;
                  }
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            
            // Ícone circular colorido
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            
            // Informações da tarefa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (category != null)
                        _buildTag(category, Colors.grey.shade800, Colors.grey.shade400),
                      if (project != null)
                        _buildTag(project, color.withOpacity(0.2), color),
                    ],
                  ),
                ],
              ),
            ),
            
            // Play/Pause button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Se o timer está rodando nesta tarefa, parar
                if (_isRunning && (_customTaskName == name || _selectedActivity?.activityName == name)) {
                  _stopTimer();
                } else {
                  // Se está rodando outra tarefa, parar e iniciar esta
                  if (_isRunning) {
                    _stopTimer();
                  }
                  setState(() {
                    _taskNameController.text = name;
                    _selectedCategory = category;
                    _selectedProject = project;
                  });
                  _startTimer(customTask: name);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (_isRunning && (_customTaskName == name || _selectedActivity?.activityName == name))
                      ? UltravioletColors.error.withOpacity(0.15)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (_isRunning && (_customTaskName == name || _selectedActivity?.activityName == name))
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: (_isRunning && (_customTaskName == name || _selectedActivity?.activityName == name))
                      ? UltravioletColors.error
                      : color,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildRecordCard(TimeTrackingRecord record) {
    // Usar cor do registro se disponível, senão buscar da lista
    final color = record.colorValue != null 
        ? Color(record.colorValue!) 
        : _getActivityColor(record.activityName);
    final duration = record.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final timeStr = hours > 0 
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Usar dados do registro se disponível
    final category = record.category ?? 'Pessoal';
    final project = record.project;
    final isCompleted = record.isCompleted;

    return OdysseyCard(
      onTap: () {
        // Nada por enquanto, pode expandir detalhes
      },
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: isCompleted 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.6)
          : Theme.of(context).colorScheme.surface,
      borderColor: isCompleted 
          ? UltravioletColors.accentGreen.withOpacity(0.3)
          : Colors.transparent,
      borderRadius: 14,
      child: Row(
        children: [
              // Checkbox de conclusão com animação
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final repo = ref.read(timeTrackingRepositoryProvider);
                    await repo.toggleCompleted(record.id);
                    if (!isCompleted && mounted) {
                      // Pega o nome da tarefa
                      final taskName = record.activityName;
                      
                      // Atualiza gamificação
                      try {
                        final gamificationRepo = ref.read(gamificationRepositoryProvider);
                        final gamResult = await gamificationRepo.completeTask();
        final newBadges = gamResult.newBadges;
                        
                        if (mounted) {
                          FeedbackService.showTaskCompleted(context, taskName, xp: 15);
                        }
                        
                        if (newBadges.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 2500), () {
                            if (mounted) {
                              FeedbackService.showAchievement(
                                context, 
                                '${newBadges.first.icon} ${newBadges.first.name}',
                                newBadges.first.description,
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          FeedbackService.showTaskCompleted(context, taskName);
                        }
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? UltravioletColors.accentGreen : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? UltravioletColors.accentGreen : UltravioletColors.outline,
                        width: 2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16, key: ValueKey('check'))
                          : const SizedBox(key: ValueKey('empty')),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Ícone circular colorido
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isCompleted ? 0.3 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(record.iconCode, fontFamily: 'MaterialIcons'),
                  color: isCompleted ? color.withOpacity(0.5) : color,
                  size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Informações da tarefa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.activityName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isCompleted 
                        ? UltravioletColors.onSurfaceVariant 
                        : UltravioletColors.onSurface,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildTag(category, Colors.grey.shade800, Colors.grey.shade400),
                    if (project != null && project.isNotEmpty)
                      _buildTag(project, color.withOpacity(0.2), color),
                  ],
                ),
              ],
            ),
          ),
          
          // Tempo e ações
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: isCompleted 
                      ? UltravioletColors.accentGreen 
                      : UltravioletColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Botão de play/pause tarefa
              if (!isCompleted)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Se o timer está rodando nesta tarefa, parar
                      if (_isRunning && (_customTaskName == record.activityName || _selectedActivity?.activityName == record.activityName)) {
                        _stopTimer();
                      } else {
                        // Se está rodando outra tarefa, parar e iniciar esta
                        if (_isRunning) {
                          _stopTimer();
                        }
                        setState(() {
                          _taskNameController.text = record.activityName;
                          _selectedCategory = category;
                          _selectedProject = project;
                        });
                        _startTimer(customTask: record.activityName);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (_isRunning && (_customTaskName == record.activityName || _selectedActivity?.activityName == record.activityName))
                            ? UltravioletColors.error.withOpacity(0.15)
                            : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        (_isRunning && (_customTaskName == record.activityName || _selectedActivity?.activityName == record.activityName))
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: (_isRunning && (_customTaskName == record.activityName || _selectedActivity?.activityName == record.activityName))
                            ? UltravioletColors.error
                            : color,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      decoration: BoxDecoration(
        color: UltravioletColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Projetos
          _buildNavItem(Icons.folder_outlined, false, 'Projetos', () => _showProjectsDialog()),
          
          // Botão central de adicionar (refinado)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showAddTaskDialog();
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: UltravioletColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: UltravioletColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
          
          // Histórico
          _buildNavItem(Icons.history, false, 'Histórico', () => _showAllTasksDialogFromNav()),
        ],
      ),
    );
  }
  
  void _showAllTasksDialogFromNav() {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final allRecords = repo.fetchAllTimeTrackingRecords();
    allRecords.sort((a, b) => b.startTime.compareTo(a.startTime));
    _showAllTasksDialog(context, allRecords);
  }

  Widget _buildNavItem(IconData icon, bool isSelected, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? UltravioletColors.primary : UltravioletColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? UltravioletColors.primary : UltravioletColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final repo = ref.read(timeTrackingRepositoryProvider);
        // Combinar projetos dos registros + projetos das atividades predefinidas
        final repoProjects = repo.getAllProjects();
        final activityProjects = _activities
            .where((a) => a['project'] != null && (a['project'] as String).isNotEmpty)
            .map((a) => a['project'] as String)
            .toSet();
        final allProjects = {...repoProjects, ...activityProjects}.toList()..sort();
        
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UltravioletColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                    'Meus Projetos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddProjectDialog();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UltravioletColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: UltravioletColors.primary, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Lista de projetos
              if (allProjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: UltravioletColors.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum projeto ainda',
                        style: TextStyle(color: UltravioletColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allProjects.length,
                    itemBuilder: (context, index) {
                      final project = allProjects[index];
                      final projectTasks = repo.box.values
                          .cast<TimeTrackingRecord>()
                          .where((r) => r.project == project)
                          .toList();
                      final completedCount = projectTasks.where((r) => r.isCompleted).length;
                      final progress = projectTasks.isEmpty ? 0.0 : completedCount / projectTasks.length;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Filtrar tarefas pelo projeto
                            Navigator.pop(context);
                            setState(() {
                              _selectedProject = project;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: UltravioletColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Ícone com progresso
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        backgroundColor: UltravioletColors.surfaceVariant,
                                        color: UltravioletColors.primary,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.folder,
                                      color: UltravioletColors.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        projectTasks.isEmpty 
                                            ? 'Nenhuma tarefa'
                                            : '${projectTasks.length} tarefas • $completedCount ✓',
                                        style: const TextStyle(
                                          color: UltravioletColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botões editar e apagar
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showEditProjectDialog(project);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: UltravioletColors.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDeleteProjectDialog(project, projectTasks.length);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: UltravioletColors.error,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Seção de Categorias
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categorias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddCategoryDialog();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: UltravioletColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: UltravioletColors.secondary, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showEditCategoryDialog(cat);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: UltravioletColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: const TextStyle(
                            color: UltravioletColors.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
            ),
          ),
        );
      },
    );
  }
  
  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome da categoria...',
            filled: true,
            fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && !_categories.contains(controller.text)) {
                setState(() {
                  _categories.add(controller.text);
                });
                Navigator.pop(context);
                FeedbackService.showSuccess(context, 'Categoria "${controller.text}" criada');
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
  
  void _showEditCategoryDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome da categoria...',
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteCategoryDialog(oldName);
            },
            child: const Text('Apagar', style: TextStyle(color: UltravioletColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                final index = _categories.indexOf(oldName);
                if (index != -1) {
                  setState(() {
                    _categories[index] = controller.text;
                  });
                }
                Navigator.pop(context);
                FeedbackService.showSuccess(context, 'Categoria renomeada');
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apagar Categoria?'),
        content: Text('Deseja apagar a categoria "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _categories.remove(categoryName);
              });
              Navigator.pop(context);
              FeedbackService.showSuccess(context, 'Categoria apagada');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UltravioletColors.error,
            ),
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome do projeto...',
            filled: true,
            fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                Navigator.pop(context);
                await _renameProject(oldName, controller.text);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameProject(String oldName, String newName) async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final records = repo.box.values
        .cast<TimeTrackingRecord>()
        .where((r) => r.project == oldName)
        .toList();
    
    for (final record in records) {
      final updated = record.copyWith(project: newName);
      await repo.updateTimeTrackingRecord(record.id, updated);
    }
    
    if (mounted) {
      setState(() {});
      FeedbackService.showSuccess(context, 'Projeto renomeado para "$newName"');
    }
  }

  void _showDeleteProjectDialog(String projectName, int taskCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apagar Projeto?'),
        content: Text(
          taskCount > 0
              ? 'O projeto "$projectName" tem $taskCount tarefa(s). As tarefas serão mantidas, mas ficarão sem projeto.'
              : 'Deseja apagar o projeto "$projectName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProject(projectName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UltravioletColors.error,
            ),
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(String projectName) async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final records = repo.box.values
        .cast<TimeTrackingRecord>()
        .where((r) => r.project == projectName)
        .toList();
    
    for (final record in records) {
      final updated = record.copyWith(project: null);
      await repo.updateTimeTrackingRecord(record.id, updated);
    }
    
    if (mounted) {
      setState(() {});
      FeedbackService.showSuccess(context, 'Projeto "$projectName" apagado');
    }
  }

  void _showAddProjectDialog() {
    final projectNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Novo Projeto'),
        content: TextField(
          controller: projectNameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome do projeto...',
            filled: true,
            fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (projectNameController.text.isNotEmpty) {
                Navigator.pop(context);
                // Abrir diálogo de nova tarefa com o projeto pré-selecionado
                _taskNameController.clear();
                setState(() {
                  _selectedProject = projectNameController.text;
                });
                _showAddTaskDialog();
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    String? selectedCategory = _selectedCategory ?? 'Pessoal';
    String? selectedProject = _selectedProject;
    final projectController = TextEditingController(text: _selectedProject ?? '');
    
    // Combinar projetos das atividades predefinidas com os do repositório
    final repo = ref.read(timeTrackingRepositoryProvider);
    final repoProjects = repo.getAllProjects();
    final activityProjects = _activities
        .where((a) => a['project'] != null)
        .map((a) => a['project'] as String)
        .toSet();
    final existingProjects = {...activityProjects, ...repoProjects}.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UltravioletColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nova Tarefa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Nome da tarefa
              TextField(
                controller: _taskNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nome da tarefa...',
                  filled: true,
                  fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.task_alt),
                ),
              ),
              const SizedBox(height: 16),
              
              // Categoria
              const Text(
                'Categoria',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: UltravioletColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? UltravioletColors.primary.withOpacity(0.2)
                            : UltravioletColors.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected 
                            ? Border.all(color: UltravioletColors.primary)
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected 
                              ? UltravioletColors.primary
                              : UltravioletColors.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Projeto
              const Text(
                'Projeto (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: UltravioletColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Projetos existentes
              if (existingProjects.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...existingProjects.map((proj) {
                      final isSelected = selectedProject == proj;
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedProject = isSelected ? null : proj;
                          projectController.text = isSelected ? '' : proj;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? UltravioletColors.secondary.withOpacity(0.2)
                                : UltravioletColors.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected 
                                ? Border.all(color: UltravioletColors.secondary)
                                : null,
                          ),
                          child: Text(
                            proj,
                            style: TextStyle(
                              color: isSelected 
                                  ? UltravioletColors.secondary
                                  : UltravioletColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Campo para novo projeto
              TextField(
                controller: projectController,
                decoration: InputDecoration(
                  hintText: 'Ou digite um novo projeto...',
                  filled: true,
                  fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                  isDense: true,
                ),
                onChanged: (value) => setModalState(() => selectedProject = value.isEmpty ? null : value),
              ),
              const SizedBox(height: 24),
              
              // Botão iniciar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_taskNameController.text.isNotEmpty) {
                      setState(() {
                        _selectedCategory = selectedCategory;
                        _selectedProject = selectedProject ?? projectController.text;
                        if (_selectedProject?.isEmpty ?? true) _selectedProject = null;
                      });
                      _startTimer(customTask: _taskNameController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UltravioletColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Iniciar Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ACTIVE TIMER SCREEN - Tela com cronômetro em execução
  // =====================================================
  Widget _buildActiveTimerScreen() {
    final taskName = _customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa';
    final color = _getActivityColor(taskName);
    final displayTime = _isPomodoroMode ? _pomodoroTimeLeft : _elapsedTime;
    
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.05),
              const Color(0xFF0A0A0F),
              const Color(0xFF111118),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Header compacto
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  // Botão minimizar
                  GestureDetector(
                    onTap: () => setState(() => _showFullscreenTimer = false),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                  const Spacer(),
                  // Botão de som ambiente
                  GestureDetector(
                    onTap: _showSoundSettings,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: soundService.isAmbientPlaying 
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: soundService.isAmbientPlaying 
                            ? Border.all(color: color.withOpacity(0.5))
                            : null,
                      ),
                      child: Icon(
                        soundService.isAmbientPlaying ? Icons.music_note : Icons.music_off,
                        color: soundService.isAmbientPlaying ? color : Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Título da tarefa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    taskName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedCategory != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _selectedCategory!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (_selectedProject != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            _selectedProject!,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Timer Circle grande e centralizado
            _buildTimePadTimerCircle(displayTime, color),

            const Spacer(flex: 3),

            // Control Buttons com mais espaço
            _buildTimePadControls(),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePadTimerCircle(Duration displayTime, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            
            // Progress ring
            SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _TimePadRingPainter(
                  progress: _isPomodoroMode
                      ? (_isPomodoroBreak
                          ? _pomodoroTimeLeft.inSeconds / 300
                          : _pomodoroTimeLeft.inSeconds / 1500)
                      : 1.0,
                  color: color,
                  backgroundColor: color.withOpacity(0.1),
                  strokeWidth: 12,
                ),
              ),
            ),
            
            // Inner circle with time
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A24),
              ),
              child: Center(
                child: Text(
                  _formatDurationShort(displayTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePadControls() {
    final color = _getActivityColor(_customTaskName ?? _selectedActivity?.activityName);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimizar (voltar para lista mantendo timer)
            GestureDetector(
              onTap: () => setState(() => _showFullscreenTimer = false),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: UltravioletColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Stop button (maior, destaque)
            GestureDetector(
              onTap: () {
                _stopTimer();
                setState(() => _showFullscreenTimer = false);
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: UltravioletColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: UltravioletColors.error.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Cancelar (descarta o tempo)
            GestureDetector(
              onTap: () {
                _resetTimer();
                setState(() => _showFullscreenTimer = false);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: UltravioletColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                'Minimizar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 72,
              child: Text(
                'Salvar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 56,
              child: Text(
                'Descartar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // POMODORO SCREEN - Redireciona para a aba Pomodoro
  // =====================================================
  Widget _buildPomodoroScreen() {
    // Redirecionar para a tela principal com a aba de Pomodoro selecionada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showPomodoroScreen = false;
          _selectedTab = 1;
          _tabController.animateTo(1);
        });
      }
    });
    
    // Retornar a tela principal enquanto redireciona
    return _buildMainScreen();
  }

  // =====================================================
  // POMODORO SCREEN LEGACY - Mantido para referência
  // =====================================================
  Widget _buildPomodoroScreenLegacy() {
    const pomodoroColor = Color(0xFFFF6B6B);
    const breakColor = Color(0xFF667EEA);
    final currentColor = _isPomodoroBreak ? breakColor : pomodoroColor;
    
    // Calcular total time para o tomato timer
    final totalDuration = _isPomodoroBreak 
        ? (_pomodoroSessions >= _pomodoroTotalSessions ? _longBreakDuration : _shortBreakDuration)
        : _pomodoroDuration;
    
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F1E),
              const Color(0xFF0A0A14),
              _isPomodoroBreak
                  ? const Color(0xFF080812)
                  : const Color(0xFF0A0508),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Header refinado
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      // Botão voltar
                      GestureDetector(
                        onTap: () {
                          if (_isPomodoroRunning) {
                            _showExitPomodoroDialog();
                          } else {
                            setState(() => _showPomodoroScreen = false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Título e tempo configurado
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPomodoroBreak ? 'Pausa' : 'Foco',
                              style: TextStyle(
                                color: currentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_pomodoroDuration.inMinutes} min por sessão',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botão de som
                      GestureDetector(
                        onTap: _showSoundSettings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: soundService.isAmbientPlaying
                                ? currentColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: soundService.isAmbientPlaying
                                  ? currentColor.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            soundService.isAmbientPlaying ? Icons.music_note : Icons.music_off_rounded,
                            color: soundService.isAmbientPlaying ? currentColor : Colors.white60,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão configurações
                      GestureDetector(
                        onTap: _showPomodoroSettings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white60, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Timer de Tomate estilo relógio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildTomatoClockTimer(1 - (_pomodoroTimeLeft.inSeconds / totalDuration.inSeconds)),
                      const SizedBox(height: 24),
                      _buildModernPomodoroControls(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Seleção de tarefa para o Pomodoro
                _buildPomodoroTaskSelector(),

                const SizedBox(height: 16),

                // Estatísticas do dia
                _buildPomodoroStats(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Seletor de tarefas para o Pomodoro
  Widget _buildPomodoroTaskSelector() {
    const pomodoroColor = Color(0xFFFF6B6B);
    final hasTask = _customTaskName != null || _taskNameController.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Row(
            children: [
              Text(
                '📋 Tarefa',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Botão para criar nova tarefa
              GestureDetector(
                onTap: _showCreateTaskDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pomodoroColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pomodoroColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: pomodoroColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Nova',
                        style: TextStyle(
                          color: pomodoroColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tarefa selecionada ou placeholder
          if (hasTask)
            _buildSelectedPomodoroTask()
          else
            _buildTaskPlaceholder(),
          
          const SizedBox(height: 12),
          
          // Lista horizontal de tarefas rápidas
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final name = activity['name'] as String;
                final color = activity['color'] as Color;
                final icon = activity['icon'] as IconData;
                final isSelected = _customTaskName == name || _taskNameController.text == name;
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _taskNameController.text = name;
                      _customTaskName = name;
                      _selectedCategory = activity['category'] as String?;
                      _selectedProject = activity['project'] as String?;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: isSelected ? color : Colors.white60, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          name.length > 15 ? '${name.substring(0, 15)}...' : name,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPomodoroTask() {
    final taskName = _customTaskName ?? _taskNameController.text;
    final color = _getActivityColor(taskName);
    final activityData = _activities.firstWhere(
      (a) => a['name'] == taskName,
      orElse: () => {'icon': Icons.timer, 'color': UltravioletColors.primary, 'category': null, 'project': null},
    );
    final icon = activityData['icon'] as IconData;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_selectedCategory != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedCategory!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    if (_selectedProject != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedProject!,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Botão limpar seleção
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _customTaskName = null;
                _taskNameController.clear();
                _selectedCategory = null;
                _selectedProject = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPlaceholder() {
    return GestureDetector(
      onTap: _showCreateTaskDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white.withOpacity(0.4), size: 22),
            const SizedBox(width: 10),
            Text(
              'Selecione ou crie uma tarefa',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog para criar nova tarefa
  void _showCreateTaskDialog() {
    final taskController = TextEditingController();
    String? selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    String? selectedProject;
    Color selectedColor = UltravioletColors.primary;
    IconData selectedIcon = Icons.timer;
    
    final colors = [
      const Color(0xFF9B51E0),
      const Color(0xFFFFA556),
      const Color(0xFFFD5B71),
      const Color(0xFF07E092),
      const Color(0xFFFF6B6B),
      const Color(0xFF667EEA),
      const Color(0xFF00B4D8),
      const Color(0xFFFFD93D),
    ];
    
    final icons = [
      Icons.timer,
      Icons.code,
      Icons.phone_android,
      Icons.groups,
      Icons.menu_book,
      Icons.fitness_center,
      Icons.self_improvement,
      Icons.design_services,
      Icons.work,
      Icons.school,
      Icons.brush,
      Icons.music_note,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: UltravioletColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: UltravioletColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Título
                  const Row(
                    children: [
                      Text('✨', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        'Nova Tarefa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Campo nome da tarefa
                  TextField(
                    controller: taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome da tarefa',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      hintText: 'Ex: Estudar Flutter',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: selectedColor),
                      ),
                      prefixIcon: Icon(selectedIcon, color: selectedColor),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Seletor de ícone
                  Text(
                    'Ícone',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: selectedColor, width: 2) : null,
                          ),
                          child: Icon(icon, color: isSelected ? selectedColor : Colors.white60, size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Seletor de cor
                  Text(
                    'Cor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ] : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoria
                  Text(
                    'Categoria',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? Border.all(color: selectedColor) : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? selectedColor : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botão criar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (taskController.text.trim().isEmpty) {
                          FeedbackService.showError(context, 'Digite um nome para a tarefa');
                          return;
                        }
                        
                        // Adicionar à lista de atividades
                        final newActivity = {
                          'name': taskController.text.trim(),
                          'icon': selectedIcon,
                          'color': selectedColor,
                          'category': selectedCategory,
                          'project': null,
                        };
                        
                        setState(() {
                          _activities.insert(0, newActivity);
                          _customTaskName = taskController.text.trim();
                          _taskNameController.text = taskController.text.trim();
                          _selectedCategory = selectedCategory;
                          _selectedProject = null;
                        });
                        
                        Navigator.pop(context);
                        HapticFeedback.mediumImpact();
                        FeedbackService.showSuccess(context, '✅ Tarefa "${taskController.text.trim()}" criada!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Criar Tarefa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroSessionIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'Sessão ${_pomodoroSessions + 1} de $_pomodoroTotalSessions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Maçãs indicando sessões
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pomodoroTotalSessions, (index) {
              final isCompleted = index < _pomodoroSessions;
              final isCurrent = index == _pomodoroSessions;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '🍅',
                  style: TextStyle(
                    fontSize: isCurrent ? 28 : 22,
                    color: isCompleted 
                        ? null 
                        : (isCurrent ? null : Colors.white.withOpacity(0.2)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroTimerCircle(double progress, Color color) {
    final minutes = _pomodoroTimeLeft.inMinutes;
    final seconds = _pomodoroTimeLeft.inSeconds.remainder(60);
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _isPomodoroRunning ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_isPomodoroRunning ? 0.3 : 0.1),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            
            // Background ring
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 14,
                backgroundColor: Colors.transparent,
                color: color.withOpacity(0.1),
              ),
            ),
            
            // Progress ring
            SizedBox(
              width: 280,
              height: 280,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: progress, end: progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _PomodoroRingPainter(
                      progress: value,
                      color: color,
                      strokeWidth: 14,
                    ),
                  );
                },
              ),
            ),
            
            // Inner circle with tomato
            Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF1A1A24),
                    Color(0xFF12121A),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji maçã/tomate animado
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Text(
                          _isPomodoroBreak ? '☕' : '🍅',
                          style: const TextStyle(fontSize: 48),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Tempo
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroControls(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        GestureDetector(
          onTap: _resetPomodoro,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 26,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Play/Pause principal
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_isPomodoroRunning) {
              _pausePomodoro();
            } else {
              _startPomodoro();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isPomodoroRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Skip
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (_isPomodoroRunning || _pomodoroTimeLeft.inSeconds < (_pomodoroDuration.inSeconds)) {
              // Pular para próxima sessão
              _pomodoroTimer?.cancel();
              _pulseController.stop();
              if (!_isPomodoroBreak) {
                setState(() {
                  _pomodoroSessions++;
                  _isPomodoroRunning = false;
                });
                _showPomodoroComplete();
              } else {
                setState(() {
                  _isPomodoroBreak = false;
                  _isPomodoroRunning = false;
                  _pomodoroTimeLeft = _pomodoroDuration;
                });
              }
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.skip_next_rounded,
              color: Colors.white70,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPomodoroStats() {
    // Calcular tempo total focado hoje via pomodoro
    final focusMinutes = _pomodoroSessions * 25;
    final hours = focusMinutes ~/ 60;
    final mins = focusMinutes % 60;
    
    return OdysseyCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderRadius: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPomodoroStatItem(
            icon: '🍅',
            value: '$_pomodoroSessions',
            label: 'Sessões',
          ),
          Container(
            width: 1,
            height: 40,
            color: UltravioletColors.divider,
          ),
          _buildPomodoroStatItem(
            icon: '⏱️',
            value: hours > 0 ? '${hours}h${mins}m' : '${mins}m',
            label: 'Focado',
          ),
          Container(
            width: 1,
            height: 40,
            color: UltravioletColors.divider,
          ),
          _buildPomodoroStatItem(
            icon: '🎯',
            value: '$_pomodoroTotalSessions',
            label: 'Meta',
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Mostra configurações rápidas de som
  void _showSoundSettings() {
    String selectedAmbient = soundService.currentAmbientSound ?? 'none';
    bool tickEnabled = soundService.isTickingEnabled;
    double ambientVolume = soundService.ambientVolume;
    String selectedCategory = 'all';

    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: UltravioletColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                UltravioletColors.secondary.withOpacity(0.3),
                                UltravioletColors.primary.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.headphones, color: UltravioletColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sons de Concentração',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Escolha o ambiente perfeito',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tick sound section with type selector
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: UltravioletColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: tickEnabled 
                                      ? UltravioletColors.primary.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('⏱️', style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Som de Tick',
                                      style: TextStyle(
                                        color: UltravioletColors.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      tickEnabled 
                                          ? 'Vibração + som suave a cada segundo'
                                          : 'Desativado',
                                      style: const TextStyle(
                                        color: UltravioletColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: tickEnabled,
                                onChanged: (value) {
                                  setModalState(() => tickEnabled = value);
                                  if (value) {
                                    soundService.startTickSound();
                                  } else {
                                    soundService.stopTickSound();
                                  }
                                  setState(() {});
                                },
                                activeThumbColor: UltravioletColors.primary,
                              ),
                            ],
                          ),
                          // Tick type selector (only if enabled)
                          if (tickEnabled) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      setModalState(() {});
                                      soundService.tickType = 'soft_tick';
                                      // Preview - para e inicia com await
                                      await soundService.stopTickSound();
                                      await soundService.startTickSound(type: 'soft_tick');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: soundService.tickType == 'soft_tick'
                                            ? UltravioletColors.primary.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: soundService.tickType == 'soft_tick'
                                            ? Border.all(color: UltravioletColors.primary, width: 1.5)
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('🔔', style: TextStyle(fontSize: 18)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Suave',
                                            style: TextStyle(
                                              color: soundService.tickType == 'soft_tick'
                                                  ? UltravioletColors.primary
                                                  : UltravioletColors.onSurfaceVariant,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      setModalState(() {});
                                      soundService.tickType = 'clock_tick';
                                      // Preview - para e inicia com await
                                      await soundService.stopTickSound();
                                      await soundService.startTickSound(type: 'clock_tick');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: soundService.tickType == 'clock_tick'
                                            ? UltravioletColors.primary.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: soundService.tickType == 'clock_tick'
                                            ? Border.all(color: UltravioletColors.primary, width: 1.5)
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('🕐', style: TextStyle(fontSize: 18)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Relógio',
                                            style: TextStyle(
                                              color: soundService.tickType == 'clock_tick'
                                                  ? UltravioletColors.primary
                                                  : UltravioletColors.onSurfaceVariant,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Volume do tick - sempre mostrar quando tick ativado
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: UltravioletColors.onSurfaceVariant, size: 16),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: soundService.tickVolume.clamp(0.1, 1.0),
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 9,
                                      activeColor: UltravioletColors.primary,
                                      inactiveColor: UltravioletColors.primary.withOpacity(0.2),
                                      onChanged: (value) {
                                        setModalState(() {});
                                        soundService.setTickVolume(value);
                                      },
                                    ),
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: UltravioletColors.onSurfaceVariant, size: 16),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Category filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('all', '🎵 Todos', selectedCategory, (cat) {
                            setModalState(() => selectedCategory = cat);
                          }),
                          const SizedBox(width: 8),
                          ...SoundService.categoryNames.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(e.key, e.value, selectedCategory, (cat) {
                              setModalState(() => selectedCategory = cat);
                            }),
                          )),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Ambient sounds grid
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎧 Som de Fundo (ambiente)',
                          style: TextStyle(
                            color: UltravioletColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Sons ambiente são independentes do som de tick',
                          style: TextStyle(
                            color: UltravioletColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // None option
                        GestureDetector(
                          onTap: () async {
                            setModalState(() => selectedAmbient = 'none');
                            await soundService.stopAmbientSound();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: selectedAmbient == 'none' 
                                  ? UltravioletColors.primary.withOpacity(0.2)
                                  : UltravioletColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: selectedAmbient == 'none'
                                  ? Border.all(color: UltravioletColors.primary, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Text('🔇', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sem Som',
                                      style: TextStyle(
                                        color: selectedAmbient == 'none' 
                                            ? UltravioletColors.primary 
                                            : UltravioletColors.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      'Silêncio total',
                                      style: TextStyle(
                                        color: UltravioletColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (selectedAmbient == 'none')
                                  const Icon(Icons.check_circle, color: UltravioletColors.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                        // Other sounds
                        ...SoundService.ambientSoundsLibrary.entries
                            .where((e) => e.key != 'none' && 
                                (selectedCategory == 'all' || e.value.category == selectedCategory))
                            .map((entry) {
                          final isSelected = selectedAmbient == entry.key;
                          final info = entry.value;
                          return GestureDetector(
                            onTap: () async {
                              setModalState(() => selectedAmbient = entry.key);
                              await soundService.startAmbientSound(entry.key);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? UltravioletColors.primary.withOpacity(0.2)
                                    : UltravioletColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: UltravioletColors.primary, width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Text(info.name.split(' ')[0], style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          info.name.substring(info.name.indexOf(' ') + 1),
                                          style: TextStyle(
                                            color: isSelected 
                                                ? UltravioletColors.primary 
                                                : UltravioletColors.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          info.description,
                                          style: const TextStyle(
                                            color: UltravioletColors.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!info.isLocal)
                                    FutureBuilder<bool>(
                                      future: soundService.isSoundDownloaded(entry.key),
                                      builder: (context, snapshot) {
                                        if (snapshot.data == true) {
                                          return const Icon(Icons.download_done, 
                                            color: UltravioletColors.accentGreen, 
                                            size: 18);
                                        }
                                        return Icon(Icons.cloud_download_outlined, 
                                          color: UltravioletColors.onSurfaceVariant.withOpacity(0.5), 
                                          size: 18);
                                      },
                                    ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: UltravioletColors.primary, size: 22),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    
                    // Volume slider for ambient (only if not 'none')
                    if (selectedAmbient != 'none') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: UltravioletColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.volume_up, color: UltravioletColors.onSurfaceVariant, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Volume',
                                  style: TextStyle(
                                    color: UltravioletColors.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(ambientVolume * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: UltravioletColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                              ),
                              child: Slider(
                                value: ambientVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                activeColor: UltravioletColors.primary,
                                inactiveColor: UltravioletColors.primary.withOpacity(0.2),
                                onChanged: (value) {
                                  setModalState(() => ambientVolume = value);
                                  soundService.setAmbientVolume(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(String key, String label, String selected, Function(String) onTap) {
    final isSelected = selected == key;
    return GestureDetector(
      onTap: () => onTap(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? UltravioletColors.primary.withOpacity(0.2)
              : UltravioletColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: UltravioletColors.primary, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? UltravioletColors.primary 
                : UltravioletColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _showExitPomodoroDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🍅', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Sair do Pomodoro?'),
          ],
        ),
        content: const Text('O timer será pausado, mas seu progresso será mantido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pausePomodoro();
              setState(() => _showPomodoroScreen = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPomodoroSettings() {
    int focusMinutes = _pomodoroDuration.inMinutes;
    int shortBreakMinutes = _shortBreakDuration.inMinutes;
    int longBreakMinutes = _longBreakDuration.inMinutes;
    int sessions = _pomodoroTotalSessions;
    String selectedAmbient = soundService.currentAmbientSound ?? 'none';
    bool tickEnabled = soundService.isTickingEnabled;
    double ambientVolume = soundService.ambientVolume;

    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UltravioletColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Row(
                    children: [
                      Text('🍅', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'Configurações Pomodoro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Focus time
                  _buildPomodoroSettingRow(
                    label: 'Tempo de Foco',
                    value: focusMinutes,
                    unit: 'min',
                    onDecrease: () => setModalState(() {
                      if (focusMinutes > 5) focusMinutes -= 5;
                    }),
                    onIncrease: () => setModalState(() {
                      if (focusMinutes < 60) focusMinutes += 5;
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Short break
                  _buildPomodoroSettingRow(
                    label: 'Pausa Curta',
                    value: shortBreakMinutes,
                    unit: 'min',
                    onDecrease: () => setModalState(() {
                      if (shortBreakMinutes > 1) shortBreakMinutes -= 1;
                    }),
                    onIncrease: () => setModalState(() {
                      if (shortBreakMinutes < 15) shortBreakMinutes += 1;
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Long break
                  _buildPomodoroSettingRow(
                    label: 'Pausa Longa',
                    value: longBreakMinutes,
                    unit: 'min',
                    onDecrease: () => setModalState(() {
                      if (longBreakMinutes > 5) longBreakMinutes -= 5;
                    }),
                    onIncrease: () => setModalState(() {
                      if (longBreakMinutes < 30) longBreakMinutes += 5;
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sessions
                  _buildPomodoroSettingRow(
                    label: 'Sessões até Pausa Longa',
                    value: sessions,
                    unit: '',
                    onDecrease: () => setModalState(() {
                      if (sessions > 2) sessions -= 1;
                    }),
                    onIncrease: () => setModalState(() {
                      if (sessions < 8) sessions += 1;
                    }),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  const Divider(color: UltravioletColors.divider),
                  const SizedBox(height: 16),
                  
                  // Sound settings title
                  const Row(
                    children: [
                      Icon(Icons.music_note, color: UltravioletColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sons & Ambiente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: UltravioletColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tick sound toggle
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⏱️ Som de Tick',
                              style: TextStyle(
                                color: UltravioletColors.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Toca a cada segundo',
                              style: TextStyle(
                                color: UltravioletColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: tickEnabled,
                        onChanged: (value) {
                          setModalState(() => tickEnabled = value);
                        },
                        activeThumbColor: UltravioletColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ambient sound selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎵 Som de Fundo',
                        style: TextStyle(
                          color: UltravioletColors.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: SoundService.ambientSoundNames.entries.map((entry) {
                            final isSelected = selectedAmbient == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() => selectedAmbient = entry.key);
                                  // Preview do som
                                  if (entry.key != 'none') {
                                    soundService.startAmbientSound(entry.key);
                                  } else {
                                    soundService.stopAmbientSound();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? UltravioletColors.primary.withOpacity(0.2)
                                        : UltravioletColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected 
                                        ? Border.all(color: UltravioletColors.primary, width: 2)
                                        : null,
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? UltravioletColors.primary 
                                          : UltravioletColors.onSurfaceVariant,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  // Volume slider for ambient (only if not 'none')
                  if (selectedAmbient != 'none') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.volume_down, color: UltravioletColors.onSurfaceVariant, size: 20),
                        Expanded(
                          child: Slider(
                            value: ambientVolume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            activeColor: UltravioletColors.primary,
                            inactiveColor: UltravioletColors.surfaceVariant,
                            onChanged: (value) {
                              setModalState(() => ambientVolume = value);
                              soundService.setAmbientVolume(value);
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up, color: UltravioletColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _pomodoroDuration = Duration(minutes: focusMinutes);
                          _shortBreakDuration = Duration(minutes: shortBreakMinutes);
                          _longBreakDuration = Duration(minutes: longBreakMinutes);
                          _pomodoroTotalSessions = sessions;
                          if (!_isPomodoroRunning) {
                            _pomodoroTimeLeft = _pomodoroDuration;
                          }
                        });
                        
                        // Aplicar configurações de som
                        if (tickEnabled) {
                          soundService.startTickSound();
                        } else {
                          soundService.stopTickSound();
                        }
                        
                        // Se não está tocando, parar o preview
                        if (!_isPomodoroRunning && selectedAmbient == 'none') {
                          soundService.stopAmbientSound();
                        }
                        
                        Navigator.pop(context);
                        FeedbackService.showSuccess(context, '⚙️ Configurações salvas');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroSettingRow({
    required String label,
    required int value,
    required String unit,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: UltravioletColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        // Stepper
        Container(
          decoration: BoxDecoration(
            color: UltravioletColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onDecrease,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.remove,
                    color: UltravioletColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$value${unit.isNotEmpty ? " $unit" : ""}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrease,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.add,
                    color: UltravioletColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // PRODUCTIVITY SCREEN - Tela de estatísticas
  // =====================================================
  Widget _buildProductivityScreen() {
    final repo = ref.watch(timeTrackingRepositoryProvider);
    
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: repo.box.listenable(),
        builder: (context, box, _) {
          final today = DateTime.now();
          final allRecords = box.values.cast<TimeTrackingRecord>().toList();
          final todayRecords = allRecords
              .where((r) => _isSameDay(r.startTime, today))
              .toList();
          
          // Debug
          debugPrint('📊 Total records: ${allRecords.length}');
          debugPrint('📊 Today records: ${todayRecords.length}');
          
          // Contar tarefas concluídas hoje
          final completedToday = todayRecords.where((r) => r.isCompleted).length;
          
          final totalMinutes = todayRecords.fold<int>(
            0, (sum, r) => sum + r.durationInSeconds ~/ 60,
          );
          final hours = totalMinutes ~/ 60;
          final minutes = totalMinutes % 60;

          // Calcular dados da semana
          final weekData = _calculateWeekData(allRecords);
          debugPrint('📊 Week data: $weekData');

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showProductivity = false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UltravioletColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Minha Produtividade',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        iconColor: UltravioletColors.accentGreen,
                        label: 'Tarefas\nConcluídas',
                        value: '$completedToday',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.access_time,
                        iconColor: UltravioletColors.secondary,
                        label: 'Tempo\nTotal',
                        value: '${hours}h${minutes.toString().padLeft(2, '0')}m',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Segunda linha de stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.timer,
                        iconColor: UltravioletColors.tertiary,
                        label: 'Sessões\nHoje',
                        value: '${todayRecords.length}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        iconColor: UltravioletColors.primary,
                        label: 'Taxa de\nConclusão',
                        value: todayRecords.isEmpty 
                            ? '0%' 
                            : '${(completedToday / todayRecords.length * 100).round()}%',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Day/Week toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: UltravioletColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showWeekStats = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_showWeekStats ? UltravioletColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Day',
                                style: TextStyle(
                                  color: !_showWeekStats ? Colors.white : UltravioletColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showWeekStats = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _showWeekStats ? UltravioletColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Week',
                                style: TextStyle(
                                  color: _showWeekStats ? Colors.white : UltravioletColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildWeekChart(weekData),
                ),
              ),

              // Bottom nav
              _buildBottomNavBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: UltravioletColors.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _calculateWeekData(List<TimeTrackingRecord> records) {
    final now = DateTime.now();
    final weekData = List<double>.filled(7, 0);
    
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayRecords = records.where((r) => _isSameDay(r.startTime, day));
      final totalMinutes = dayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60);
      weekData[i] = totalMinutes / 60; // Converter para horas
    }
    
    return weekData;
  }

  Widget _buildWeekChart(List<double> weekData) {
    final maxValue = weekData.isEmpty ? 1.0 : weekData.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? maxValue + 0.5 : 2.0; // Adiciona margem ao topo
    final now = DateTime.now();
    
    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderRadius: 16,
      child: Column(
        children: [
          // Y-axis labels and chart
          Expanded(
            child: Row(
              children: [
                // Y-axis labels
                SizedBox(
                  width: 45,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${chartMax.toStringAsFixed(1)}h', style: const TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 10)),
                      Text('${(chartMax * 0.75).toStringAsFixed(1)}h', style: const TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 10)),
                      Text('${(chartMax * 0.5).toStringAsFixed(1)}h', style: const TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 10)),
                      Text('${(chartMax * 0.25).toStringAsFixed(1)}h', style: const TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 10)),
                      const Text('0h', style: TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Chart area
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _WeekChartPainter(
                        data: weekData,
                        maxValue: chartMax,
                        color: UltravioletColors.primary,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 57),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = now.subtract(Duration(days: 6 - i));
                final isToday = i == 6;
                final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                final dayName = dayNames[day.weekday - 1];
                return Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isToday ? UltravioletColors.primary : UltravioletColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday ? UltravioletColors.primary : UltravioletColors.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// =====================================================
// TOMATO CLOCK PAINTER - Timer de Tomate estilo relógio
// =====================================================
class _TomatoClockPainter extends CustomPainter {
  final double progress;
  final bool isBreak;
  final bool isRunning;

  _TomatoClockPainter({
    required this.progress,
    required this.isBreak,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final tomatoRadius = size.width * 0.42;

    // Cores
    final baseColor = isBreak ? const Color(0xFF3498DB) : const Color(0xFFE74C3C);
    final lightColor = isBreak ? const Color(0xFF5DADE2) : const Color(0xFFFF6B6B);
    final darkColor = isBreak ? const Color(0xFF2980B9) : const Color(0xFFC0392B);
    const leafColor = Color(0xFF27AE60);
    const leafDarkColor = Color(0xFF1E8449);

    // Sombra do tomate
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + tomatoRadius * 0.9),
        width: tomatoRadius * 1.4,
        height: tomatoRadius * 0.3,
      ),
      shadowPaint,
    );

    // Corpo do tomate (base)
    final tomatoPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.2,
        colors: [lightColor, baseColor, darkColor],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: tomatoRadius));

    // Desenha o tomate com forma levemente achatada
    final tomatoRect = Rect.fromCenter(
      center: center,
      width: tomatoRadius * 2,
      height: tomatoRadius * 1.85,
    );
    canvas.drawOval(tomatoRect, tomatoPaint);

    // Highlight (brilho)
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.dx - tomatoRadius * 0.3, center.dy - tomatoRadius * 0.3),
        radius: tomatoRadius * 0.5,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - tomatoRadius * 0.3, center.dy - tomatoRadius * 0.3),
        width: tomatoRadius * 0.6,
        height: tomatoRadius * 0.4,
      ),
      highlightPaint,
    );

    // Indicador de progresso (fatia estilo relógio)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      final progressPath = Path();
      progressPath.moveTo(center.dx, center.dy);
      
      // Desenha a fatia do progresso (como um relógio)
      final sweepAngle = progress * 2 * math.pi;
      progressPath.arcTo(
        Rect.fromCircle(center: center, radius: tomatoRadius * 0.75),
        -math.pi / 2, // Começa do topo
        sweepAngle,
        false,
      );
      progressPath.close();

      canvas.save();
      canvas.clipPath(Path()..addOval(tomatoRect));
      canvas.drawPath(progressPath, progressPaint);
      canvas.restore();

      // Borda da fatia
      final borderPaint = Paint()
        ..color = darkColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(progressPath, borderPaint);
    }

    // Ponteiro do relógio
    _drawClockHand(canvas, center, tomatoRadius * 0.65, progress, darkColor);

    // Folhas (caule)
    _drawLeaves(canvas, Offset(center.dx, center.dy - tomatoRadius * 0.85), leafColor, leafDarkColor);

    // Marcadores de minutos ao redor
    _drawMinuteMarkers(canvas, center, tomatoRadius);
  }

  void _drawClockHand(Canvas canvas, Offset center, double length, double progress, Color color) {
    final angle = -math.pi / 2 + (progress * 2 * math.pi);
    final endX = center.dx + math.cos(angle) * length;
    final endY = center.dy + math.sin(angle) * length;

    // Sombra do ponteiro
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(endX + 2, endY + 2),
      shadowPaint,
    );

    // Ponteiro principal
    final handPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(endX, endY), handPaint);

    // Centro do ponteiro
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);
    
    // Brilho no centro
    final centerHighlight = Paint()
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, centerHighlight);
  }

  void _drawLeaves(Canvas canvas, Offset stemBase, Color leafColor, Color leafDarkColor) {
    final leafPaint = Paint()..style = PaintingStyle.fill;

    // Caule central
    final stemPaint = Paint()
      ..color = leafDarkColor
      ..style = PaintingStyle.fill;
    
    final stemPath = Path();
    stemPath.moveTo(stemBase.dx - 4, stemBase.dy);
    stemPath.quadraticBezierTo(stemBase.dx, stemBase.dy - 15, stemBase.dx + 4, stemBase.dy);
    stemPath.close();
    canvas.drawPath(stemPath, stemPaint);

    // Folhas
    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.5 - math.pi / 2;
      final leafLength = 25.0 + (i % 2) * 8;
      
      leafPaint.shader = LinearGradient(
        colors: [leafColor, leafDarkColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(stemBase.dx - 20, stemBase.dy - 30, 40, 30));

      final leafPath = Path();
      final leafTip = Offset(
        stemBase.dx + math.cos(angle) * leafLength,
        stemBase.dy + math.sin(angle) * leafLength,
      );
      
      leafPath.moveTo(stemBase.dx, stemBase.dy - 5);
      leafPath.quadraticBezierTo(
        stemBase.dx + math.cos(angle + 0.3) * leafLength * 0.5,
        stemBase.dy + math.sin(angle + 0.3) * leafLength * 0.5,
        leafTip.dx,
        leafTip.dy,
      );
      leafPath.quadraticBezierTo(
        stemBase.dx + math.cos(angle - 0.3) * leafLength * 0.5,
        stemBase.dy + math.sin(angle - 0.3) * leafLength * 0.5,
        stemBase.dx,
        stemBase.dy - 5,
      );
      
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  void _drawMinuteMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Marcadores a cada 5 minutos (12 marcadores)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final innerRadius = radius * 0.82;
      final outerRadius = radius * 0.88;

      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * outerRadius * 0.92,
      );
      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius * 0.92,
      );

      canvas.drawLine(start, end, markerPaint);
    }
  }

  @override
  bool shouldRepaint(_TomatoClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isBreak != isBreak ||
        oldDelegate.isRunning != isRunning;
  }
}

// TimePad style ring painter with gradient
class _TimePadRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _TimePadRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring with gradient
    final sweepAngle = 2 * math.pi * progress;
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: [
        color.withOpacity(0.6),
        color,
        color.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimePadRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Week chart painter
class _WeekChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;

  _WeekChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final stepX = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

// Pomodoro ring painter with beautiful gradient
class _PomodoroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _PomodoroRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring with gradient
    final sweepAngle = 2 * math.pi * progress;
    
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      // Gradiente mais bonito para o pomodoro
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: [
          color.withOpacity(0.4),
          color,
          color.withOpacity(0.9),
          color,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Brilho na ponta
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      
      final glowPaint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PomodoroRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

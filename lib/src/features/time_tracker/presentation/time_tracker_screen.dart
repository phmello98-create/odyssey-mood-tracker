import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import 'package:odyssey/src/features/time_tracker/widgets/tomato_timer_widget.dart';

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

  late TabController _tabController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late AnimationController _appleController;
  late Animation<double> _appleAnimation;

  // Predefined activities with colors (editáveis)
  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Desenvolvimento App',
      'icon': Icons.phone_android,
      'color': const Color(0xFF9B51E0),
      'category': 'Trabalho',
      'project': 'Odyssey',
    },
    {
      'name': 'Reunião de equipe',
      'icon': Icons.groups,
      'color': const Color(0xFFFFA556),
      'category': 'Trabalho',
      'project': 'Odyssey',
    },
    {
      'name': 'Estudar Flutter',
      'icon': Icons.code,
      'color': const Color(0xFFFD5B71),
      'category': 'Estudo',
      'project': 'Aprendizado',
    },
    {
      'name': 'Leitura',
      'icon': Icons.menu_book,
      'color': const Color(0xFF07E092),
      'category': 'Pessoal',
      'project': 'Leitura',
    },
    {
      'name': 'Exercícios',
      'icon': Icons.fitness_center,
      'color': const Color(0xFFFF6B6B),
      'category': 'Saúde',
      'project': 'Fitness',
    },
    {
      'name': 'Meditação',
      'icon': Icons.self_improvement,
      'color': const Color(0xFFE91E63),
      'category': 'Pessoal',
      'project': null,
    },
  ];

  // Categorias disponíveis (editáveis)
  final List<String> _categories = [
    'Trabalho',
    'Pessoal',
    'Estudo',
    'Saúde',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _initShowcase();

    // Tab controller para as abas
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
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
      final numTasks = dayOffset == 0
          ? 4
          : (dayOffset % 3) + 2; // Mais tarefas hoje

      for (int taskIndex = 0; taskIndex < numTasks; taskIndex++) {
        final taskVariants = [
          {
            'name': 'Desenvolvimento App',
            'icon': Icons.phone_android,
            'color': const Color(0xFF9B51E0),
            'cat': 'Trabalho',
            'proj': 'Odyssey',
          },
          {
            'name': 'Reunião de equipe',
            'icon': Icons.groups,
            'color': const Color(0xFFFFA556),
            'cat': 'Trabalho',
            'proj': 'Odyssey',
          },
          {
            'name': 'Estudar Flutter',
            'icon': Icons.code,
            'color': const Color(0xFFFD5B71),
            'cat': 'Estudo',
            'proj': 'Aprendizado',
          },
          {
            'name': 'Leitura',
            'icon': Icons.menu_book,
            'color': const Color(0xFF07E092),
            'cat': 'Pessoal',
            'proj': 'Leitura',
          },
          {
            'name': 'Exercícios',
            'icon': Icons.fitness_center,
            'color': const Color(0xFFFF6B6B),
            'cat': 'Saúde',
            'proj': 'Fitness',
          },
          {
            'name': 'Meditação',
            'icon': Icons.self_improvement,
            'color': const Color(0xFF9B51E0),
            'cat': 'Saúde',
            'proj': null,
          },
          {
            'name': 'Design UI',
            'icon': Icons.design_services,
            'color': const Color(0xFF00B4D8),
            'cat': 'Trabalho',
            'proj': 'Odyssey',
          },
        ];

        final task =
            taskVariants[(dayOffset + taskIndex) % taskVariants.length];
        final durationMinutes =
            30 +
            (taskIndex * 20) +
            (dayOffset * 10) % 90; // 30-120 min variável
        final startHour = 8 + (taskIndex * 2);

        sampleRecords.add(
          TimeTrackingRecord(
            id: '${idCounter++}',
            activityName: task['name'] as String,
            iconCode: (task['icon'] as IconData).codePoint,
            startTime: day.add(Duration(hours: startHour)),
            endTime: day.add(
              Duration(hours: startHour, minutes: durationMinutes),
            ),
            duration: Duration(minutes: durationMinutes),
            category: task['cat'] as String,
            project: task['proj'] as String?,
            isCompleted:
                dayOffset > 0 ||
                taskIndex < 2, // Hoje: só 2 primeiras concluídas
            colorValue: (task['color'] as Color).value,
          ),
        );
      }
    }

    for (final record in sampleRecords) {
      await repo.addTimeTrackingRecord(record);
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(
      showcase.ShowcaseTour.timeTracker,
    );
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
    final timerState = ref.read(timerProvider);

    // VALIDAÇÃO: Não permitir iniciar timer livre se Pomodoro está rodando
    if (timerState.isPomodoroMode && timerState.isRunning) {
      FeedbackService.showError(
        context,
        '🍅 Pomodoro em andamento! Pause-o antes de iniciar outro timer.',
      );
      return;
    }

    final taskName = customTask ?? _taskNameController.text;

    // Pegar cor e ícone da atividade
    final activityData = _activities.firstWhere(
      (a) => a['name'] == taskName,
      orElse: () => {
        'icon': Icons.timer,
        'color': Theme.of(context).colorScheme.primary,
      },
    );
    final color = activityData['color'] as Color;
    final icon = activityData['icon'] as IconData;

    // Usar o provider global para iniciar o timer
    ref
        .read(timerProvider.notifier)
        .startTimer(
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
      final elapsed = timerState.elapsed.inSeconds > 0
          ? timerState.elapsed
          : _elapsedTime;
      final startTime =
          timerState.startTime ??
          _startTime ??
          DateTime.now().subtract(elapsed);
      final endTime = DateTime.now();

      // Pegar cor da atividade selecionada
      final activityData = _activities.firstWhere(
        (a) => a['name'] == activityName,
        orElse: () => {
          'icon': Icons.timer,
          'color': Theme.of(context).colorScheme.primary,
        },
      );
      final color = timerState.colorValue != null
          ? Color(timerState.colorValue!)
          : activityData['color'] as Color;

      final record = TimeTrackingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityName: activityName,
        iconCode:
            timerState.iconCode ??
            _selectedActivity?.iconCode ??
            (activityData['icon'] as IconData).codePoint,
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
      FeedbackService.showFocusSessionComplete(
        context,
        activityName,
        minutes,
        xp: xp > 0 ? xp : null,
      );

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
          NotificationService.instance.showPomodoroComplete(
            activityName,
            minutes,
          );
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
    final timerState = ref.read(timerProvider);

    // VALIDAÇÃO: Não permitir iniciar Pomodoro se timer livre está rodando
    if (!timerState.isPomodoroMode && timerState.isRunning) {
      FeedbackService.showError(
        context,
        '⏱️ Timer livre em andamento! Pause-o antes de iniciar o Pomodoro.',
      );
      return;
    }

    // Verificar se há um Pomodoro pausado - se sim, retomar em vez de reiniciar
    if (timerState.isPaused && timerState.isPomodoroMode) {
      // RETOMAR Pomodoro pausado
      soundService.playTimerStart();
      ref.read(timerProvider.notifier).resumePomodoro();

      setState(() {
        _isPomodoroRunning = true;
        // NÃO resetar _pomodoroTimeLeft - manter o valor atual
      });

      _pulseController.repeat(reverse: true);
      return;
    }

    // INICIAR novo Pomodoro
    soundService.playTimerStart();
    final taskName =
        _customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa';

    // Usar o provider global para iniciar o Pomodoro
    ref
        .read(timerProvider.notifier)
        .startPomodoro(
          taskName: taskName,
          category: _selectedCategory,
          project: _selectedProject,
        );

    // Atualizar estado local apenas para UI
    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = _pomodoroDuration;
    });

    // Parar timer local antigo se existir
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;

    _pulseController.repeat(reverse: true);
  }

  void _pausePomodoro() {
    // Usar o provider global para pausar
    ref.read(timerProvider.notifier).pausePomodoro();

    setState(() {
      _isPomodoroRunning = false;
    });
    _pomodoroTimer?.cancel();
    _pulseController.stop();
    // Parar sons do timer
    soundService.stopTimerSounds();
  }

  void _resetPomodoro() {
    // Usar o provider global para resetar
    ref.read(timerProvider.notifier).resetPomodoro();

    _pomodoroTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    // Parar sons do timer
    soundService.stopTimerSounds();
    setState(() {
      _isPomodoroRunning = false;
      _isPomodoroBreak = false;
      _pomodoroTimeLeft = _pomodoroDuration;
      _pomodoroSessions = 0;
    });
  }

  void _startBreak() {
    // Usar o provider global para iniciar a pausa
    ref.read(timerProvider.notifier).startBreak();

    // Atualizar estado local para UI
    final isLongBreak = _pomodoroSessions >= _pomodoroTotalSessions;
    final breakDuration = isLongBreak
        ? _longBreakDuration
        : _shortBreakDuration;

    setState(() {
      _isPomodoroRunning = true;
      _isPomodoroBreak = true;
      _pomodoroTimeLeft = breakDuration;
      // Se completou todas as sessões, resetar contador
      if (isLongBreak) {
        _pomodoroSessions = 0;
      }
    });

    // Parar timer local antigo se existir
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;

    _pulseController.repeat(reverse: true);
  }

  /// Salva um registro de sessão Pomodoro no repositório
  void _savePomodoroRecord(TimerState timerState) {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final now = DateTime.now();
    final duration = timerState.pomodoroDuration;
    final startTime = now.subtract(duration);

    final record = TimeTrackingRecord(
      id: 'pomodoro_${DateTime.now().millisecondsSinceEpoch}',
      activityName: timerState.taskName ?? 'Pomodoro',
      iconCode: Icons.timer_rounded.codePoint,
      startTime: startTime,
      endTime: now,
      duration: duration,
      category: 'Pomodoro',
      project: timerState.project,
      isCompleted: true,
      colorValue: const Color(0xFFE74C3C).value, // Vermelho tomate
    );

    repo.addTimeTrackingRecord(record);

    debugPrint(
      '[Pomodoro] Sessão salva: ${record.activityName} - ${duration.inMinutes}min',
    );
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
    if (activityName == null) return Theme.of(context).colorScheme.primary;
    final activity = _activities.firstWhere(
      (a) => a['name'] == activityName,
      orElse: () => {'color': Theme.of(context).colorScheme.primary},
    );
    return activity['color'] as Color;
  }

  void _initShowcase() {
    final keys = [_showcaseTimer, _showcasePlay, _showcaseTasks];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.timeTracker,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(
      showcase.ShowcaseTour.timeTracker,
      keys,
    );
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

            _tabController.animateTo(1);
            _pomodoroDuration = notifier.pomodoroDuration;
            _pomodoroTimeLeft = notifier.pomodoroDuration;
          });
          // Limpar a flag para não reabrir novamente
          notifier.clearPomodoroScreenFlag();
        }
      });
    }

    // Sincronizar estado local do TIMER LIVRE com o provider global
    // IMPORTANTE: Só sincronizar se NÃO estiver em modo Pomodoro
    if (!timerState.isPomodoroMode) {
      if (timerState.isRunning && !_isRunning) {
        // Timer livre foi iniciado em outro lugar ou restaurado
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
        // Timer livre foi parado
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
        // Atualizar tempo do timer livre
        _elapsedTime = timerState.elapsed;
      }
    }

    // Sincronizar estado do Pomodoro com o provider global
    if (timerState.isPomodoroMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Detectar conclusão de sessão de foco (NÃO pausa)
          // Quando sessions aumenta e não está em break, uma sessão foi concluída
          final sessionCompleted =
              timerState.pomodoroSessions > _pomodoroSessions &&
              !timerState.isPomodoroBreak &&
              _pomodoroSessions > 0;

          // Salvar registro de Pomodoro quando sessão completa
          if (sessionCompleted && !_isPomodoroBreak) {
            _savePomodoroRecord(timerState);
          }

          final needsUpdate =
              _isPomodoroRunning != timerState.isRunning ||
              _isPomodoroBreak != timerState.isPomodoroBreak ||
              _pomodoroTimeLeft != timerState.pomodoroTimeLeft ||
              _pomodoroSessions != timerState.pomodoroSessions;

          if (needsUpdate) {
            setState(() {
              _isPomodoroRunning = timerState.isRunning;
              _isPomodoroBreak = timerState.isPomodoroBreak;
              _pomodoroTimeLeft = timerState.pomodoroTimeLeft;
              _pomodoroSessions = timerState.pomodoroSessions;
              _customTaskName = timerState.taskName;
            });

            if (timerState.isRunning && !_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            } else if (!timerState.isRunning && _pulseController.isAnimating) {
              _pulseController.stop();
            }
          }
        }
      });
    } else if (_isPomodoroRunning) {
      // Não está mais em modo Pomodoro, resetar estado local
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isPomodoroRunning = false;
            _isPomodoroBreak = false;
          });
        }
      });
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
          // Header com botões minimalistas
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Projetos
                _buildHeaderButton(
                  icon: Icons.folder_outlined,
                  label: 'Projetos',
                  onTap: _showProjectsDialog,
                ),
                // Add
                _buildHeaderButton(
                  icon: Icons.add,
                  label: 'Add',
                  onTap: _showAddTaskDialog,
                  isPrimary: true,
                ),
                // Histórico
                _buildHeaderButton(
                  icon: Icons.history,
                  label: 'Histórico',
                  onTap: _showAllTasksDialogFromNav,
                ),
              ],
            ),
          ),

          // Tab Bar - Design minimalista com pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Tempo Livre
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _tabController.index == 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _tabController.index == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: _tabController.index == 0
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tempo Livre',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabController.index == 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Pomodoro
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? const Color(0xFFE74C3C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _tabController.index == 1
                              ? const Color(0xFFE74C3C)
                              : Theme.of(
                                  context,
                                ).colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍅', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Pomodoro',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

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

          // Remove Bottom Nav Bar usage since we moved items to header
          // But keep a spacer if needed, or remove completely if not needed
          // The old UI had _buildBottomNavBar(), we don't need it anymore.
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
        Expanded(child: _buildTodayTasksList()),
      ],
    );
  }

  // =====================================================
  // POMODORO TAB - Aba de Pomodoro com timer de tomate
  // =====================================================
  Widget _buildPomodoroTab() {
    final repo = ref.watch(timeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final allRecords = box.values.cast<TimeTrackingRecord>().toList();

        // Filter Pomodoro sessions (duration ~25 min or records with pomodoro flag)
        final pomodoroRecords = allRecords
            .where((r) => _isSameDay(r.startTime, now))
            .where(
              (r) => r.durationInSeconds >= 1200 && r.durationInSeconds <= 1800,
            ) // 20-30 min sessions
            .toList();
        pomodoroRecords.sort((a, b) => b.startTime.compareTo(a.startTime));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Timer de Tomate reutilizável
              TomatoTimerWidget(
                timeLeft: _pomodoroTimeLeft,
                totalTime: _pomodoroDuration,
                isRunning: _isPomodoroRunning,
                isBreak: _isPomodoroBreak,
                onStart: _startPomodoro,
                onPause: _pausePomodoro,
                onReset: _resetPomodoro,
              ),

              const SizedBox(height: 24),

              // Stats do Pomodoro
              _buildPomodoroQuickStats(),

              const SizedBox(height: 16),

              // Seletor de tarefa rápido
              _buildQuickTaskSelector(),

              const SizedBox(height: 24),

              // Histórico de sessões Pomodoro
              _buildPomodoroHistory(pomodoroRecords),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPomodoroHistory(List<TimeTrackingRecord> sessions) {
    final colorScheme = Theme.of(context).colorScheme;
    const pomodoroColor = Color(0xFFE74C3C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: pomodoroColor),
            const SizedBox(width: 8),
            Text(
              'Sessões de Hoje',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            if (sessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pomodoroColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sessions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pomodoroColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (sessions.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 32,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nenhuma sessão hoje',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicie um Pomodoro para começar!',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ...sessions.map((session) => _buildPomodoroSessionCard(session)),
        ],
      ],
    );
  }

  Widget _buildPomodoroSessionCard(TimeTrackingRecord session) {
    final colorScheme = Theme.of(context).colorScheme;
    const pomodoroColor = Color(0xFFE74C3C);
    final isCompleted = session.isCompleted;

    final startTime = DateFormat('HH:mm').format(session.startTime);
    final duration = session.duration;
    final minutes = duration.inMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF27AE60).withOpacity(0.08)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF27AE60).withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Tomato icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  pomodoroColor.withOpacity(0.2),
                  pomodoroColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🍅', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.activityName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      startTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pomodoroColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${minutes}m',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: pomodoroColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Completion status
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF27AE60),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }

  // Controles modernos do Pomodoro
  Widget _buildModernPomodoroControls() {
    final color = _isPomodoroBreak
        ? const Color(0xFF3498DB)
        : const Color(0xFFE74C3C);

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
              _isPomodoroRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: isSmall ? 24 : 32,
        ),
      ),
    );
  }

  void _skipPomodoroSession() {
    final timerState = ref.read(timerProvider);

    // REGRA 1: Não pode pular durante pausas
    if (_isPomodoroBreak || timerState.isPomodoroBreak) {
      FeedbackService.showError(
        context,
        '⏸️ Não é possível pular a pausa. Aproveite para descansar!',
      );
      return;
    }

    // REGRA 2: Só pode pular após 5 minutos de foco (300 segundos)
    final elapsedSeconds =
        _pomodoroDuration.inSeconds - _pomodoroTimeLeft.inSeconds;
    const minSecondsToSkip = 300; // 5 minutos

    if (elapsedSeconds < minSecondsToSkip) {
      final remainingToSkip = minSecondsToSkip - elapsedSeconds;
      final minutesRemaining = (remainingToSkip / 60).ceil();
      FeedbackService.showWarning(
        context,
        '⏰ Foque por mais $minutesRemaining min antes de pular',
      );
      return;
    }

    // REGRA 3: Pular sessão de foco e iniciar pausa automaticamente
    HapticFeedback.mediumImpact();

    // Parar timer atual
    _pomodoroTimer?.cancel();
    _pulseController.stop();

    // Incrementar sessões completadas
    setState(() {
      _pomodoroSessions++;
      _isPomodoroRunning = false;
    });

    // Feedback de sessão pulada
    FeedbackService.showSuccess(
      context,
      '🍅 Sessão $_pomodoroSessions/$_pomodoroTotalSessions completa!',
    );

    // Iniciar pausa automaticamente após curto delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _startBreak();
      }
    });
  }

  // Stats rápidas do Pomodoro - Design compacto inline
  Widget _buildPomodoroQuickStats() {
    final colorScheme = Theme.of(context).colorScheme;
    final focusMinutes = _pomodoroSessions * _pomodoroDuration.inMinutes;
    final hours = focusMinutes ~/ 60;
    final mins = focusMinutes % 60;

    final pomodoroColor = _isPomodoroBreak
        ? const Color(0xFF3498DB)
        : const Color(0xFFE74C3C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sessões
          _buildCompactStat(
            icon: '🍅',
            value: '$_pomodoroSessions',
            label: 'Sessões',
            color: pomodoroColor,
            colorScheme: colorScheme,
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),

          // Focado
          _buildCompactStat(
            icon: '⏱️',
            value: hours > 0 ? '${hours}h${mins}m' : '${mins}m',
            label: 'Focado',
            color: const Color(0xFF27AE60),
            colorScheme: colorScheme,
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),

          // Meta
          _buildCompactStat(
            icon: '🎯',
            value: '$_pomodoroTotalSessions',
            label: 'Meta',
            color: const Color(0xFFF39C12),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({
    required String icon,
    required String value,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Seletor de tarefa rápido - Design moderno
  Widget _buildQuickTaskSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com título e botão de config
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _isPomodoroBreak
                          ? const Color(0xFF3498DB)
                          : const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Escolha uma tarefa',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showPomodoroSettings,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ajustar',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tarefa atualmente selecionada (se houver)
        if (_customTaskName != null) ...[
          _buildSelectedTaskCard(colorScheme),
          const SizedBox(height: 12),
        ],

        // Lista horizontal de tarefas
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final isSelected = _customTaskName == activity['name'];
              final color = activity['color'] as Color;
              final icon = activity['icon'] as IconData;
              final name = activity['name'] as String;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < _activities.length - 1 ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        // Deselect if tapping same task
                        _customTaskName = null;
                        _selectedCategory = null;
                      } else {
                        _customTaskName = name;
                        _selectedCategory = activity['category'] as String?;
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 100,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.25),
                                color.withOpacity(0.1),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : colorScheme.surfaceContainerHighest.withOpacity(
                              0.6,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color.withOpacity(0.6)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ícone com background
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? color
                                : colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Nome da tarefa (truncado)
                        Text(
                          name.length > 10
                              ? '${name.substring(0, 8)}...'
                              : name,
                          style: TextStyle(
                            color: isSelected
                                ? color
                                : colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  // Card mostrando a tarefa atualmente selecionada
  Widget _buildSelectedTaskCard(ColorScheme colorScheme) {
    final activity = _activities.firstWhere(
      (a) => a['name'] == _customTaskName,
      orElse: () => {
        'name': _customTaskName,
        'icon': Icons.task_alt,
        'color': const Color(0xFFE74C3C),
      },
    );
    final color = activity['color'] as Color;
    final icon = activity['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarefa selecionada',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _customTaskName ?? '',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _customTaskName = null;
                _selectedCategory = null;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LEGACY - Task Screen (não usado mais, mantido para referência)
  // =====================================================
  Widget _buildTaskScreen() {
    return _buildMainScreen();
  }

  Widget _buildCurrentTimerCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelectedTask =
        _customTaskName != null || _taskNameController.text.isNotEmpty;
    final taskName = _isRunning
        ? (_customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa')
        : (_taskNameController.text.isEmpty
              ? 'Selecione uma tarefa'
              : _taskNameController.text);

    // Cor baseada no estado
    final taskColor = _isRunning
        ? _getActivityColor(_customTaskName ?? _selectedActivity?.activityName)
        : (hasSelectedTask
              ? _getActivityColor(_taskNameController.text)
              : colorScheme.primary);

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
          0,
          (sum, r) => sum + r.durationInSeconds,
        );
        final displayTime = _isRunning
            ? _elapsedTime
            : Duration(seconds: totalSeconds);

        // Progress para o ring (baseado em meta diária de 8h)
        const dailyGoalSeconds = 8 * 60 * 60;
        final progress = (totalSeconds / dailyGoalSeconds).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _isRunning
                ? () => setState(() => _showFullscreenTimer = true)
                : (hasSelectedTask && _taskNameController.text.isNotEmpty
                      ? () => _startTimer(customTask: _taskNameController.text)
                      : null),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isRunning
                      ? [
                          taskColor.withOpacity(0.12),
                          taskColor.withOpacity(0.04),
                        ]
                      : [
                          colorScheme.surfaceContainerHighest.withOpacity(0.6),
                          colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: _isRunning
                      ? taskColor.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _isRunning
                    ? [
                        BoxShadow(
                          color: taskColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Elemento decorativo de fundo
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            taskColor.withOpacity(0.1),
                            taskColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Timer Ring Esquerdo
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Fundo do anel
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: 1,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(
                                    _isRunning
                                        ? taskColor.withOpacity(0.2)
                                        : colorScheme.outlineVariant
                                              .withOpacity(0.2),
                                  ),
                                ),
                              ),
                              // Progresso
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.easeInOut,
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: _isRunning ? 0.0 : progress,
                                  ),
                                  builder: (context, value, _) {
                                    return CircularProgressIndicator(
                                      value: _isRunning
                                          ? null
                                          : (value > 0
                                                ? value
                                                : 0.02), // Mínimo visual
                                      strokeWidth: 8,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation(
                                        _isRunning
                                            ? taskColor
                                            : colorScheme.primary,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    );
                                  },
                                ),
                              ),
                              // Ícone central
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRunning
                                      ? taskColor
                                      : colorScheme.surface,
                                  boxShadow: _isRunning
                                      ? [
                                          BoxShadow(
                                            color: taskColor.withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  _isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: _isRunning ? Colors.white : taskColor,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Informações Centrais
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (_isRunning) ...[
                                    // Dot pulsante
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.4, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      curve: Curves.easeInOut,
                                      onEnd:
                                          () {}, // Loop handled by parent pulse controller conceptually
                                      builder: (context, value, _) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.redAccent.withOpacity(
                                              value,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    _isRunning ? 'FOCANDO AGORA' : 'TOTAL HOJE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isRunning
                                          ? taskColor
                                          : colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDuration(displayTime),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  height: 1.1,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.label_outline_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      taskName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Botão Stop (apenas se rodando)
                        if (_isRunning)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: _stopTimer,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.stop_rounded,
                                  color: colorScheme.onErrorContainer,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksList() {
    final repo = ref.watch(timeTrackingRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: repo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();

        final allRecords = box.values.cast<TimeTrackingRecord>().toList();
        allRecords.sort((a, b) => b.startTime.compareTo(a.startTime));

        // Separate today's records into pending and completed
        final todayRecords = allRecords
            .where((r) => _isSameDay(r.startTime, now))
            .toList();

        // AGRUPAR registros por nome de atividade para evitar poluição de cards
        Map<String, List<TimeTrackingRecord>> groupByActivity(
          List<TimeTrackingRecord> records,
        ) {
          final map = <String, List<TimeTrackingRecord>>{};
          for (final record in records) {
            final key = record.activityName;
            map.putIfAbsent(key, () => []).add(record);
          }
          return map;
        }

        final pendingRecords = todayRecords
            .where((r) => !r.isCompleted)
            .toList();
        final completedRecords = todayRecords
            .where((r) => r.isCompleted)
            .toList();

        // Agrupar por atividade
        final groupedPending = groupByActivity(pendingRecords);
        final groupedCompleted = groupByActivity(completedRecords);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Atividades',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${groupedPending.length + groupedCompleted.length}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _showAllTasksDialog(context, allRecords),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Histórico'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Task list
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Pending tasks section (AGRUPADOS)
                    if (groupedPending.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.timer_outlined,
                        title: 'Em andamento',
                        count: groupedPending.length,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      ...groupedPending.entries.map(
                        (entry) => _buildGroupedRecordCard(
                          entry.key,
                          entry.value,
                          isCompleted: false,
                        ),
                      ),
                    ],

                    // Suggestions if no pending
                    if (groupedPending.isEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Comece uma tarefa',
                        count: null,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(height: 8),
                      ...(_activities
                          .take(4)
                          .map((a) => _buildTaskCard(a, isPreset: true))),
                    ],

                    // Completed tasks section (AGRUPADOS)
                    if (groupedCompleted.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Concluídos',
                        count: groupedCompleted.length,
                        color: const Color(0xFF27AE60),
                      ),
                      const SizedBox(height: 8),
                      ...groupedCompleted.entries.map(
                        (entry) => _buildGroupedRecordCard(
                          entry.key,
                          entry.value,
                          isCompleted: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), // Padding for bottom nav
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int? count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAllTasksDialog(
    BuildContext context,
    List<TimeTrackingRecord> allRecords,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle draggável
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ),
              // Header fixo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Histórico',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${allRecords.length} registros',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lista scrollável
              Expanded(
                child: allRecords.isEmpty
                    ? _buildEmptyHistoryState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: allRecords.length,
                        itemBuilder: (context, index) {
                          final record = allRecords[index];
                          final showDateHeader =
                              index == 0 ||
                              !_isSameDay(
                                record.startTime,
                                allRecords[index - 1].startTime,
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader) ...[
                                if (index > 0) const SizedBox(height: 16),
                                _buildDateHeader(record.startTime),
                                const SizedBox(height: 10),
                              ],
                              _buildHistoryRecordCard(record),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comece a rastrear seu tempo!',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatDateHeader(date),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Card específico para o histórico com visual mais compacto
  Widget _buildHistoryRecordCard(TimeTrackingRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = record.colorValue != null
        ? Color(record.colorValue!)
        : _getActivityColor(record.activityName);

    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    final startTime = DateFormat('HH:mm').format(record.startTime);
    final endTime = DateFormat('HH:mm').format(record.endTime);

    // Detectar se é registro de Pomodoro
    final isPomodoro =
        record.activityName.toLowerCase().contains('pomodoro') ||
        record.category?.toLowerCase().contains('pomodoro') == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPomodoro
                  ? Icons.timer_rounded
                  : IconData(record.iconCode, fontFamily: 'MaterialIcons'),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.activityName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPomodoro)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('🍅', style: TextStyle(fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Duração
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hoje';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Ontem';
    return DateFormat('EEEE, d MMM', 'pt_BR').format(date);
  }

  Widget _buildTaskCard(
    Map<String, dynamic> activity, {
    bool isPreset = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = activity['color'] as Color;
    final name = activity['name'] as String;
    final icon = activity['icon'] as IconData;
    final category = activity['category'] as String?;
    final project = activity['project'] as String?;
    final isSelected = _taskNameController.text == name;
    final isRunningThis =
        _isRunning &&
        (_customTaskName == name || _selectedActivity?.activityName == name);

    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected || isRunningThis
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                )
              : null,
          color: isSelected || isRunningThis
              ? null
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : isRunningThis
                ? const Color(0xFF27AE60).withOpacity(0.5)
                : colorScheme.outlineVariant.withOpacity(0.2),
            width: isSelected || isRunningThis ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected || isRunningThis
                          ? color
                          : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null || project != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (category != null) ...[
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (category != null && project != null)
                          Text(
                            ' • ',
                            style: TextStyle(color: colorScheme.outlineVariant),
                          ),
                        if (project != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              project,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500,
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
            // Timer status or play button
            if (isRunningThis) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDurationShort(_elapsedTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_isRunning) {
                    _stopTimer();
                  }
                  setState(() {
                    _taskNameController.text = name;
                    _selectedCategory = category;
                    _selectedProject = project;
                  });
                  _startTimer(customTask: name);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: color, size: 22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(TimeTrackingRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = record.colorValue != null
        ? Color(record.colorValue!)
        : _getActivityColor(record.activityName);
    final duration = record.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final timeStr = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m ${seconds}s';

    final category = record.category ?? 'Pessoal';
    final project = record.project;
    final isCompleted = record.isCompleted;

    // Format start time
    final startTime = DateFormat('HH:mm').format(record.startTime);
    final endTime = DateFormat('HH:mm').format(record.endTime);

    return GestureDetector(
      onTap: () {
        // Show details modal
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
              : colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF27AE60).withOpacity(0.3)
                : colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Icon with gradient background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(isCompleted ? 0.15 : 0.25),
                    color.withOpacity(isCompleted ? 0.08 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(record.iconCode, fontFamily: 'MaterialIcons'),
                color: isCompleted ? color.withOpacity(0.5) : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task name row with completion checkbox
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.activityName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Completion checkbox
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final repo = ref.read(timeTrackingRepositoryProvider);
                          await repo.toggleCompleted(record.id);
                          if (!isCompleted && mounted) {
                            final taskName = record.activityName;
                            try {
                              final gamificationRepo = ref.read(
                                gamificationRepositoryProvider,
                              );
                              final gamResult = await gamificationRepo
                                  .completeTask();
                              final newBadges = gamResult.newBadges;
                              if (mounted) {
                                FeedbackService.showTaskCompleted(
                                  context,
                                  taskName,
                                  xp: 15,
                                );
                              }
                              if (newBadges.isNotEmpty) {
                                Future.delayed(
                                  const Duration(milliseconds: 2500),
                                  () {
                                    if (mounted) {
                                      FeedbackService.showAchievement(
                                        context,
                                        '${newBadges.first.icon} ${newBadges.first.name}',
                                        newBadges.first.description,
                                      );
                                    }
                                  },
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                FeedbackService.showTaskCompleted(
                                  context,
                                  taskName,
                                );
                              }
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? const Color(0xFF27AE60)
                                : Colors.transparent,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF27AE60)
                                  : colorScheme.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Time info row
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$startTime${' → $endTime'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? const Color(0xFF27AE60)
                                : color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Category and project
                  if (project != null && project.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 12,
                          color: color.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side: Play button (only if not completed)
            if (!isCompleted) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_isRunning &&
                      (_customTaskName == record.activityName ||
                          _selectedActivity?.activityName ==
                              record.activityName)) {
                    _stopTimer();
                  } else {
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
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        (_isRunning &&
                            (_customTaskName == record.activityName ||
                                _selectedActivity?.activityName ==
                                    record.activityName))
                        ? colorScheme.error.withOpacity(0.1)
                        : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (_isRunning &&
                            (_customTaskName == record.activityName ||
                                _selectedActivity?.activityName ==
                                    record.activityName))
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color:
                        (_isRunning &&
                            (_customTaskName == record.activityName ||
                                _selectedActivity?.activityName ==
                                    record.activityName))
                        ? colorScheme.error
                        : color,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card agrupado que mostra tempo total de múltiplas sessões da mesma atividade
  Widget _buildGroupedRecordCard(
    String activityName,
    List<TimeTrackingRecord> records, {
    required bool isCompleted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Usar dados do primeiro registro como referência
    final firstRecord = records.first;
    final color = firstRecord.colorValue != null
        ? Color(firstRecord.colorValue!)
        : _getActivityColor(activityName);

    // Somar todas as durações
    final totalDuration = records.fold<Duration>(
      Duration.zero,
      (sum, record) => sum + record.duration,
    );

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);
    final timeStr = hours > 0
        ? '${hours}h ${minutes}m'
        : minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';

    final category = firstRecord.category ?? 'Pessoal';
    final project = firstRecord.project;
    final sessionCount = records.length;

    // Pegar horário da primeira e última sessão
    final sortedRecords = List<TimeTrackingRecord>.from(records)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final firstStart = DateFormat(
      'HH:mm',
    ).format(sortedRecords.first.startTime);
    final lastEnd = DateFormat('HH:mm').format(sortedRecords.last.endTime);

    return GestureDetector(
      onTap: () {
        // Poderia abrir um modal com detalhes de todas as sessões
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
              : colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF27AE60).withOpacity(0.3)
                : colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Icon with gradient background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(isCompleted ? 0.15 : 0.25),
                    color.withOpacity(isCompleted ? 0.08 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(firstRecord.iconCode, fontFamily: 'MaterialIcons'),
                color: isCompleted ? color.withOpacity(0.5) : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activityName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge de sessões (se mais de 1)
                      if (sessionCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$sessionCount sessões',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Time info row
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$firstStart - $lastEnd',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? color.withOpacity(0.6) : color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tags row
                  if (category.isNotEmpty || project != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(
                          category,
                          colorScheme.surfaceContainerHigh,
                          colorScheme.onSurfaceVariant,
                        ),
                        if (project != null) ...[
                          const SizedBox(width: 6),
                          _buildTag(project, color.withOpacity(0.15), color),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side: Play button (only if not completed)
            if (!isCompleted) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Se já está rodando essa tarefa, para
                  if (_isRunning && _customTaskName == activityName) {
                    _stopTimer();
                  } else {
                    // Para qualquer timer atual e inicia essa tarefa
                    if (_isRunning) {
                      _stopTimer();
                    }
                    setState(() {
                      _taskNameController.text = activityName;
                      _selectedCategory = category;
                      _selectedProject = project;
                    });
                    _startTimer(customTask: activityName);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (_isRunning && _customTaskName == activityName)
                        ? colorScheme.error.withOpacity(0.1)
                        : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (_isRunning && _customTaskName == activityName)
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: (_isRunning && _customTaskName == activityName)
                        ? colorScheme.error
                        : color,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
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
        color: Theme.of(context).colorScheme.surface,
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
          _buildNavItem(
            Icons.folder_outlined,
            false,
            'Projetos',
            () => _showProjectsDialog(),
          ),

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
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          // Histórico
          _buildNavItem(
            Icons.history,
            false,
            'Histórico',
            () => _showAllTasksDialogFromNav(),
          ),
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

  Widget _buildNavItem(
    IconData icon,
    bool isSelected,
    String label,
    VoidCallback onTap,
  ) {
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
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final repo = ref.read(timeTrackingRepositoryProvider);
        // Combinar projetos dos registros + projetos das atividades predefinidas
        final repoProjects = repo.getAllProjects();
        final activityProjects = _activities
            .where(
              (a) =>
                  a['project'] != null && (a['project'] as String).isNotEmpty,
            )
            .map((a) => a['project'] as String)
            .toSet();
        final allProjects = {...repoProjects, ...activityProjects}.toList()
          ..sort();

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
                      color: Theme.of(context).colorScheme.outlineVariant,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum projeto ainda',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
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
                          final completedCount = projectTasks
                              .where((r) => r.isCompleted)
                              .length;
                          final progress = projectTasks.isEmpty
                              ? 0.0
                              : completedCount / projectTasks.length;

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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
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
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        Icon(
                                          Icons.folder,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
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
                                          _showDeleteProjectDialog(
                                            project,
                                            projectTasks.length,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 18,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome da categoria...',
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
              if (controller.text.isNotEmpty &&
                  !_categories.contains(controller.text)) {
                setState(() {
                  _categories.add(controller.text);
                });
                Navigator.pop(context);
                FeedbackService.showSuccess(
                  context,
                  'Categoria "${controller.text}" criada',
                );
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
            child: Text(
              'Apagar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome do projeto...',
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Novo Projeto'),
        content: TextField(
          controller: projectNameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome do projeto...',
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
    final projectController = TextEditingController(
      text: _selectedProject ?? '',
    );

    // Combinar projetos das atividades predefinidas com os do repositório
    final repo = ref.read(timeTrackingRepositoryProvider);
    final repoProjects = repo.getAllProjects();
    final activityProjects = _activities
        .where((a) => a['project'] != null)
        .map((a) => a['project'] as String)
        .toSet();
    final existingProjects = {...activityProjects, ...repoProjects}.toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return StatefulBuilder(
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
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nova Tarefa',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Nome da tarefa
                TextField(
                  controller: _taskNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Nome da tarefa...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                      0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.task_alt,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Categoria
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Categoria',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.2),
                                      colorScheme.primary.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Projeto
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Projeto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'opcional',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Projetos existentes
                if (existingProjects.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: existingProjects.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final proj = existingProjects[index];
                        final isSelected = selectedProject == proj;
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            selectedProject = isSelected ? null : proj;
                            projectController.text = isSelected ? '' : proj;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        colorScheme.secondary.withOpacity(0.2),
                                        colorScheme.secondary.withOpacity(0.1),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.secondary
                                    : colorScheme.outlineVariant.withOpacity(
                                        0.3,
                                      ),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                Text(
                                  proj,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.secondary
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Campo para novo projeto
                TextField(
                  controller: projectController,
                  decoration: InputDecoration(
                    hintText: 'Ou digite um novo projeto...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                      0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.folder_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => setModalState(
                    () => selectedProject = value.isEmpty ? null : value,
                  ),
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
                          _selectedProject =
                              selectedProject ?? projectController.text;
                          if (_selectedProject?.isEmpty ?? true) {
                            _selectedProject = null;
                          }
                        });
                        _startTimer(customTask: _taskNameController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Timer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // ACTIVE TIMER SCREEN - Tela com cronômetro em execução
  // =====================================================
  Widget _buildActiveTimerScreen() {
    final taskName =
        _customTaskName ?? _selectedActivity?.activityName ?? 'Tarefa';
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
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
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
                        soundService.isAmbientPlaying
                            ? Icons.music_note
                            : Icons.music_off,
                        color: soundService.isAmbientPlaying
                            ? color
                            : Colors.white70,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
        return Transform.scale(scale: _pulseAnimation.value, child: child);
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
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
    final color = _getActivityColor(
      _customTaskName ?? _selectedActivity?.activityName,
    );

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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.4),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
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
        ? (_pomodoroSessions >= _pomodoroTotalSessions
              ? _longBreakDuration
              : _shortBreakDuration)
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
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
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
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white60,
                            size: 22,
                          ),
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
                            soundService.isAmbientPlaying
                                ? Icons.music_note
                                : Icons.music_off_rounded,
                            color: soundService.isAmbientPlaying
                                ? currentColor
                                : Colors.white60,
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
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white60,
                            size: 22,
                          ),
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
                      TomatoTimerWidget(
                        timeLeft: _pomodoroTimeLeft,
                        totalTime: _pomodoroDuration,
                        isRunning: _isPomodoroRunning,
                        isBreak: _isPomodoroBreak,
                        onStart: _startPomodoro,
                        onPause: _pausePomodoro,
                        onReset: _resetPomodoro,
                      ),
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
    final hasTask =
        _customTaskName != null || _taskNameController.text.isNotEmpty;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                final isSelected =
                    _customTaskName == name || _taskNameController.text == name;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.25)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? color : Colors.white60,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name.length > 15
                              ? '${name.substring(0, 15)}...'
                              : name,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
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
      orElse: () => {
        'icon': Icons.timer,
        'color': Theme.of(context).colorScheme.primary,
        'category': null,
        'project': null,
      },
    );
    final icon = activityData['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedProject!,
                          style: TextStyle(color: color, fontSize: 11),
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
            Icon(
              Icons.add_circle_outline,
              color: Colors.white.withOpacity(0.4),
              size: 22,
            ),
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
    String? selectedCategory = _categories.isNotEmpty
        ? _categories.first
        : null;
    String? selectedProject;
    Color selectedColor = Theme.of(context).colorScheme.primary;
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Theme.of(context).colorScheme.outlineVariant,
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
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      hintText: 'Ex: Estudar Flutter',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
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
                            color: isSelected
                                ? selectedColor.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: selectedColor, width: 2)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? selectedColor : Colors.white60,
                            size: 22,
                          ),
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
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
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
                        onTap: () =>
                            setModalState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(color: selectedColor)
                                : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
                          FeedbackService.showError(
                            context,
                            'Digite um nome para a tarefa',
                          );
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
                        FeedbackService.showSuccess(
                          context,
                          '✅ Tarefa "${taskController.text.trim()}" criada!',
                        );
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
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildPomodoroStatItem(
            icon: '⏱️',
            value: hours > 0 ? '${hours}h${mins}m' : '${mins}m',
            label: 'Focado',
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
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
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.outlineVariant,
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
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.3),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.headphones,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 22,
                          ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
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
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '⏱️',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Som de Tick',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      tickEnabled
                                          ? 'Vibração + som suave a cada segundo'
                                          : 'Desativado',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                                activeThumbColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
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
                                      soundService.stopTickSound();
                                      soundService.startTickSound(
                                        type: 'soft_tick',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            soundService.tickType == 'soft_tick'
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            soundService.tickType == 'soft_tick'
                                            ? Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            '🔔',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Suave',
                                            style: TextStyle(
                                              color:
                                                  soundService.tickType ==
                                                      'soft_tick'
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
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
                                      soundService.stopTickSound();
                                      soundService.startTickSound(
                                        type: 'clock_tick',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            soundService.tickType ==
                                                'clock_tick'
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            soundService.tickType ==
                                                'clock_tick'
                                            ? Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            '🕐',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Relógio',
                                            style: TextStyle(
                                              color:
                                                  soundService.tickType ==
                                                      'clock_tick'
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
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
                                Icon(
                                  Icons.volume_down,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                    ),
                                    child: Slider(
                                      value: soundService.tickVolume.clamp(
                                        0.1,
                                        1.0,
                                      ),
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 9,
                                      activeColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2),
                                      onChanged: (value) {
                                        setModalState(() {});
                                        soundService.setTickVolume(value);
                                      },
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.volume_up,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
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
                          _buildCategoryChip(
                            'all',
                            '🎵 Todos',
                            selectedCategory,
                            (cat) {
                              setModalState(() => selectedCategory = cat);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...SoundService.categoryNames.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(
                                e.key,
                                e.value,
                                selectedCategory,
                                (cat) {
                                  setModalState(() => selectedCategory = cat);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ambient sounds grid
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎧 Som de Fundo (ambiente)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Sons ambiente são independentes do som de tick',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: selectedAmbient == 'none'
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: selectedAmbient == 'none'
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🔇',
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sem Som',
                                      style: TextStyle(
                                        color: selectedAmbient == 'none'
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Silêncio total',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (selectedAmbient == 'none')
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Other sounds
                        ...SoundService.ambientSoundsLibrary.entries
                            .where(
                              (e) =>
                                  e.key != 'none' &&
                                  (selectedCategory == 'all' ||
                                      e.value.category == selectedCategory),
                            )
                            .map((entry) {
                              final isSelected = selectedAmbient == entry.key;
                              final info = entry.value;
                              return GestureDetector(
                                onTap: () async {
                                  setModalState(
                                    () => selectedAmbient = entry.key,
                                  );
                                  await soundService.startAmbientSound(
                                    entry.key,
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.2)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        info.name.split(' ')[0],
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              info.name.substring(
                                                info.name.indexOf(' ') + 1,
                                              ),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              info.description,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!info.isLocal)
                                        FutureBuilder<bool>(
                                          future: soundService
                                              .isSoundDownloaded(entry.key),
                                          builder: (context, snapshot) {
                                            if (snapshot.data == true) {
                                              return const Icon(
                                                Icons.download_done,
                                                color: Color(0xFF27AE60),
                                                size: 18,
                                              );
                                            }
                                            return Icon(
                                              Icons.cloud_download_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withOpacity(0.5),
                                              size: 18,
                                            );
                                          },
                                        ),
                                      const SizedBox(width: 8),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 22,
                                        ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Volume',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(ambientVolume * 100).toInt()}%',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                              ),
                              child: Slider(
                                value: ambientVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                inactiveColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
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

  Widget _buildCategoryChip(
    String key,
    String label,
    String selected,
    Function(String) onTap,
  ) {
    final isSelected = selected == key;
    return GestureDetector(
      onTap: () => onTap(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🍅', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Sair do Pomodoro?'),
          ],
        ),
        content: const Text(
          'O timer será pausado, mas seu progresso será mantido.',
        ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
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
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),

                  // Sound settings title
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sons & Ambiente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tick sound toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⏱️ Som de Tick',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Toca a cada segundo',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                        },
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ambient sound selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎵 Som de Fundo',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: SoundService.ambientSoundNames.entries.map((
                            entry,
                          ) {
                            final isSelected = selectedAmbient == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () => selectedAmbient = entry.key,
                                  );
                                  // Preview do som
                                  if (entry.key != 'none') {
                                    soundService.startAmbientSound(entry.key);
                                  } else {
                                    soundService.stopAmbientSound();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.2)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
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
                        Icon(
                          Icons.volume_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        Expanded(
                          child: Slider(
                            value: ambientVolume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            onChanged: (value) {
                              setModalState(() => ambientVolume = value);
                              soundService.setAmbientVolume(value);
                            },
                          ),
                        ),
                        Icon(
                          Icons.volume_up,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
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
                          _shortBreakDuration = Duration(
                            minutes: shortBreakMinutes,
                          );
                          _longBreakDuration = Duration(
                            minutes: longBreakMinutes,
                          );
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
                        FeedbackService.showSuccess(
                          context,
                          '⚙️ Configurações salvas',
                        );
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        // Stepper
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onDecrease,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.remove,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          final completedToday = todayRecords
              .where((r) => r.isCompleted)
              .length;

          final totalMinutes = todayRecords.fold<int>(
            0,
            (sum, r) => sum + r.durationInSeconds ~/ 60,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
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
                        iconColor: const Color(0xFF27AE60),
                        label: 'Tarefas\nConcluídas',
                        value: '$completedToday',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.access_time,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        label: 'Tempo\nTotal',
                        value:
                            '${hours}h${minutes.toString().padLeft(2, '0')}m',
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
                        iconColor: Theme.of(context).colorScheme.tertiary,
                        label: 'Sessões\nHoje',
                        value: '${todayRecords.length}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        iconColor: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                              color: !_showWeekStats
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Day',
                                style: TextStyle(
                                  color: !_showWeekStats
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                              color: _showWeekStats
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Week',
                                style: TextStyle(
                                  color: _showWeekStats
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      final totalMinutes = dayRecords.fold<int>(
        0,
        (sum, r) => sum + r.durationInSeconds ~/ 60,
      );
      weekData[i] = totalMinutes / 60; // Converter para horas
    }

    return weekData;
  }

  Widget _buildWeekChart(List<double> weekData) {
    final maxValue = weekData.isEmpty
        ? 1.0
        : weekData.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0
        ? maxValue + 0.5
        : 2.0; // Adiciona margem ao topo
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
                      Text(
                        '${chartMax.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(chartMax * 0.75).toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(chartMax * 0.5).toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(chartMax * 0.25).toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '0h',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
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
                        color: Theme.of(context).colorScheme.primary,
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
                final dayNames = [
                  'Seg',
                  'Ter',
                  'Qua',
                  'Qui',
                  'Sex',
                  'Sáb',
                  'Dom',
                ];
                final dayName = dayNames[day.weekday - 1];
                return Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
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
      colors: [color.withOpacity(0.6), color, color.withOpacity(0.8)],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
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
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
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

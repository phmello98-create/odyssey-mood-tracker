import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/features/notes/data/notes_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/gamification/domain/user_stats.dart';

import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/animations/animations.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/tasks/data/synced_task_repository.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/features/news/presentation/news_screen.dart';
import 'package:odyssey/src/utils/smart_classifier.dart';
import 'package:odyssey/src/utils/widgets/smart_quick_add.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:odyssey/src/features/news/data/news_image_fetcher.dart';
import 'package:odyssey/src/features/home/data/home_widgets_provider.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_notes_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/streak_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/today_tasks_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_pomodoro_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/current_reading_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/daily_goals_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/activity_grid_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_mood_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/water_tracker_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/task_checkbox.dart';
import 'package:odyssey/src/features/home/presentation/widgets/header_arrow_button.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_suggestions_widget.dart'
    hide AnimatedBuilder;
import 'package:odyssey/src/features/home/presentation/widgets/global_search_bar.dart';
import 'package:odyssey/src/features/community/presentation/screens/community_screen.dart';
import 'package:odyssey/src/features/community/presentation/screens/create_post_screen.dart';
import 'package:odyssey/src/features/community/presentation/providers/community_providers.dart';
import 'package:odyssey/src/features/community/domain/post.dart';
import 'package:odyssey/src/features/community/domain/topic.dart';
import 'package:odyssey/src/features/community/presentation/widgets/user_avatar.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/features/settings/presentation/modern_notification_settings_screen.dart';
import 'package:odyssey/src/features/subscription/presentation/donation_screen.dart';

// Frases e insights profundos: Nietzsche, Spinoza, Maslow, Psicologia e Ciência
const List<String> _dailyInsights = [
  // Spinoza (A Essência da Serenidade)
  '"Não rir, não chorar, nem detestar, mas compreender." — Spinoza',
  'A serenidade vem de entender que as pessoas agem segundo sua própria natureza e necessidade, não contra você.',
  '"A alegria é a passagem do homem de uma perfeição menor para uma maior." — Spinoza',
  'A liberdade é o entendimento da necessidade: quando compreendemos as causas do nosso sofrimento, ele deixa de ser paixão e torna-se ação.',
  'O ódio é uma tristeza acompanhada da ideia de uma causa exterior. Diminua a tristeza, compreendendo a causa.',

  // Nietzsche (Superação e Amor Fati)
  '"Amor Fati: não querer que nada seja diferente. Nem para frente, nem para trás, nem em toda a eternidade." — Nietzsche',
  '"O que não me mata, fortalece-me." — Nietzsche (O convite para transmutar a dor em potência).',
  '"É preciso ter o caos dentro de si para dar à luz uma estrela dançante." — Nietzsche',
  '"Torna-te quem tu és." — A jornada para a autenticidade além das pressões externas.',
  '"Quem tem um porquê para viver suporta quase qualquer como." — Nietzsche',
  'O deserto cresce: proteja sua própria fonte de água em ambientes áridos.',

  // Maslow (Psicologia e Transcendência)
  '"O que um homem pode ser, ele deve ser." — Maslow',
  'A autorrealização exige a coragem de ser impopular e o desapego das expectativas alheias.',
  'O "Vazio" não é falta, é o espaço necessário para a autoatualização ocorrer sem interferência.',
  '"A capacidade de ser solitário é a condição para a capacidade de amar." — Maslow',
  'A necessidade de privacidade e independência é marca das mentes mais desenvolvidas.',

  // Realidade, Ciência e Ambiente Tóxico
  'O seu cérebro não foi feito para ser feliz, mas para sobreviver. A ansiedade em ambientes tóxicos é seu sistema de defesa funcionando.',
  'Pessoas invasivas não respeitam limites porque não os enxergam. O limite é uma construção sua, não uma concessão deles.',
  'A neuroplasticidade prova que seu cérebro pode se reconstruir, mesmo após anos de ambientes pesados.',
  'Você não é o seu diagnóstico. Bipolaridade, depressão e vício são ondas; você é o oceano onde elas ocorrem.',
  'O vácuo quântico prova que o vazio é, na verdade, um estado de energia latente infinita.',
  'Ambientes pesados consomem glicose e energia mental. Descansar não é preguiça, é manutenção de sistema.',

  // Sabedoria Cética e Existencial
  'O universo é indiferente aos seus erros. Essa é a maior das liberdades.',
  'O sentido da vida não é algo que se encontra, é algo que se cria no vazio da existência.',
  'A verdadeira autonomia começa quando a opinião dos seus pais deixa de soar como uma sentença.',
  'Sobreviver a 100% dos seus piores dias é a prova empírica da sua resiliência.',
  'O caos é o estado natural; a ordem exige esforço consciente. Não se culpe pela desordem ao redor.',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Showcase keys
  final GlobalKey _showcaseMood = GlobalKey();
  final GlobalKey _showcaseHabits = GlobalKey();
  final GlobalKey _showcaseStats = GlobalKey();
  final GlobalKey _showcaseCalendar = GlobalKey();
  final GlobalKey _showcaseTasks = GlobalKey();
  final GlobalKey _showcaseInsights = GlobalKey();
  final GlobalKey _showcaseAdd = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _progressController;

  late AnimationController _insightController;
  late AnimationController _staggeredInsightsController;

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _habitRepoInitialized = false;
  bool _taskRepoInitialized = false;
  String? _expandedHabitId;
  String _currentInsight = '';
  String _previousInsight = '';
  Timer? _insightTimer;

  // Tabs de Hábitos/Tarefas
  int _habitsTasksTabIndex = 0;

  // Calendário expandido (semana/mês)
  bool _isCalendarExpanded = false;

  // New variables for chart interactivity
  int _focusTouchedIndex = -1; // For Focus Pie Chart interaction
  final int _moodTouchedIndex = -1; // For Mood Pie Chart interaction

  // NOTE: _selectedDate and _habitRepoInitialized are at lines 153-154
  int _selectedChartIndex = 0; // 0: Habits, 1: Focus, 2: Mood
  int _chartViewMode = 0; // 0: Trend, 1: Analysis
  final bool _isQuoteVisible =
      true; // Restoring this as it was flagged as unused but removal caused more errors? Or maybe not, but chart view logic depends on _selectedChartIndex.

  // Show/Hide completed items
  bool _showCompletedHabits = false;
  bool _showCompletedTasks = false;

  // Quick task creation controller
  final TextEditingController _quickTaskController = TextEditingController();

  // Floating header scroll detection
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  Timer? _floatingHeaderTimer;
  bool _isScrolling = false;

  // Side Menu Animation (Rive App Style)
  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Controller para animar porcentagens
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller para animar texto de insights
    _insightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _staggeredInsightsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _staggeredInsightsController.forward();
    });

    _animationController.forward();
    // Delay para iniciar animação de progresso após fade in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });

    _initHabitRepo();
    _initTaskRepo();
    _setRandomInsight(animate: false);

    // Troca insight a cada 30 segundos
    _insightTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setRandomInsight(animate: true);
    });

    // Floating header scroll detection
    _scrollController.addListener(_onScroll);

    // Side Menu Animation Controller (Rive App Style)
    _menuAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutCubic),
    );
  }

  void _toggleSideMenu() {
    HapticFeedback.mediumImpact();
    setState(() => _isMenuOpen = !_isMenuOpen);
    if (_isMenuOpen) {
      _menuAnimController.forward();
    } else {
      _menuAnimController.reverse();
    }
  }

  void _onScroll() {
    // Mostrar header flutuante quando scrollar para baixo (além de 80px)
    final shouldShow = _scrollController.offset > 80;

    if (shouldShow != _showFloatingHeader) {
      setState(() => _showFloatingHeader = shouldShow);
    }

    // Marcar como scrollando
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }

    // Resetar timer de auto-hide
    _floatingHeaderTimer?.cancel();
    _floatingHeaderTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _showFloatingHeader) {
        setState(() => _isScrolling = false);
      }
    });
  }

  Future<void> _initHabitRepo() async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.init();
    if (mounted) {
      setState(() => _habitRepoInitialized = true);
    }
  }

  Future<void> _initTaskRepo() async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.init();
    if (mounted) {
      setState(() => _taskRepoInitialized = true);
    }
  }

  void _setRandomInsight({bool animate = false}) {
    final newInsight = _dailyInsights[Random().nextInt(_dailyInsights.length)];

    if (animate && mounted) {
      _previousInsight = _currentInsight;
      _insightController.forward(from: 0.0).then((_) {
        setState(() => _currentInsight = newInsight);
      });
    } else {
      setState(() => _currentInsight = newInsight);
    }
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.home);
    _animationController.dispose();
    _progressController.dispose();
    _insightController.dispose();
    _staggeredInsightsController.dispose();
    _insightTimer?.cancel();
    _quickTaskController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _floatingHeaderTimer?.cancel();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _initShowcase() {
    final keys = [
      _showcaseMood,
      _showcaseHabits,
      _showcaseStats,
      _showcaseCalendar,
      _showcaseTasks,
      _showcaseInsights,
      _showcaseAdd,
    ];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.home,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.home, keys);
  }

  void _startTour() {
    final keys = [
      _showcaseMood,
      _showcaseHabits,
      _showcaseStats,
      _showcaseCalendar,
      _showcaseTasks,
      _showcaseInsights,
      _showcaseAdd,
    ];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.home, keys);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'pt_BR');
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;

    // Cor de fundo quando o menu está aberto (escuro estilo Rive App)
    final menuBgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF17203A)
        : const Color(0xFF1E2A47);

    return Scaffold(
      extendBody: true,
      backgroundColor: menuBgColor,
      body: Stack(
        children: [
          // Fundo quando menu está aberto
          Positioned.fill(child: Container(color: menuBgColor)),

          // ==========================================
          // SIDE MENU (Atrás do conteúdo principal)
          // ==========================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(((1 - _menuAnimation.value) * -30) * pi / 180)
                    ..translate((1 - _menuAnimation.value) * -300),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _menuAnimation,
                child: _buildSideMenu(settings, colors),
              ),
            ),
          ),

          // ==========================================
          // CONTEÚDO PRINCIPAL (Animado quando menu abre)
          // ==========================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 - (_menuAnimation.value * 0.1),
                  child: Transform.translate(
                    offset: Offset(_menuAnimation.value * 265, 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY((_menuAnimation.value * 30) * pi / 180),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _menuAnimation.value * 24,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: GestureDetector(
                onTap: _isMenuOpen ? _toggleSideMenu : null,
                child: AbsorbPointer(
                  absorbing: _isMenuOpen,
                  child: _buildMainContent(monthFormat, settings, colors),
                ),
              ),
            ),
          ),

          // ==========================================
          // MENU BUTTON (Hamburger/Close)
          // ==========================================
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return SafeArea(
                  child: Row(
                    children: [
                      SizedBox(width: _menuAnimation.value * 216),
                      child!,
                    ],
                  ),
                );
              },
              child: GestureDetector(
                onTap: _toggleSideMenu,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                        key: ValueKey(_isMenuOpen),
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // FLOATING HEADER (aparece durante scroll)
          // ==========================================
          if (!_isMenuOpen)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: (_showFloatingHeader && _isScrolling) ? 0 : -80,
              left: 0,
              right: 0,
              child: _buildFloatingHeader(settings, colors),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SIDE MENU - Estilo Rive App
  // ==========================================
  Widget _buildSideMenu(AppSettings settings, ColorScheme colors) {
    final stats = ref.read(userStatsProvider);
    final title = UserTitles.getTitleForXP(stats.totalXP);

    return SafeArea(
      child: Container(
        width: 288,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      _toggleSideMenu();
                      ref.read(navigationProvider.notifier).goToProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.tertiary],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF17203A),
                        backgroundImage: settings.avatarPath != null
                            ? FileImage(File(settings.avatarPath!))
                            : null,
                        child: settings.avatarPath == null
                            ? Text(
                                settings.userName.isNotEmpty
                                    ? settings.userName[0].toUpperCase()
                                    : 'O',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.userName.isNotEmpty
                              ? settings.userName
                              : 'Viajante',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${title.emoji} ${title.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _menuSectionLabel('NAVEGAÇÃO'),
                    _sideMenuItem(Icons.home_rounded, 'Início', true, () {
                      _toggleSideMenu();
                    }),
                    _sideMenuItem(
                      Icons.person_rounded,
                      'Meu Perfil',
                      false,
                      () {
                        _toggleSideMenu();
                        ref.read(navigationProvider.notifier).goToProfile();
                      },
                    ),
                    _sideMenuItem(
                      Icons.calendar_month_rounded,
                      'Calendário',
                      false,
                      () {
                        _toggleSideMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HabitsCalendarScreen(),
                          ),
                        );
                      },
                    ),
                    _sideMenuItem(
                      Icons.library_books_rounded,
                      'Biblioteca',
                      false,
                      () {
                        _toggleSideMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    _menuSectionLabel('PROGRESSO'),
                    _sideMenuItem(
                      Icons.insights_rounded,
                      'Estatísticas',
                      false,
                      () {
                        _toggleSideMenu();
                        ref
                            .read(navigationProvider.notifier)
                            .goToProfile(tabIndex: 0);
                      },
                    ),
                    _sideMenuItem(
                      Icons.emoji_events_rounded,
                      'Conquistas',
                      false,
                      () {
                        _toggleSideMenu();
                        ref
                            .read(navigationProvider.notifier)
                            .goToProfile(tabIndex: 2);
                      },
                    ),
                    _sideMenuItem(Icons.flag_rounded, 'Metas', false, () {
                      _toggleSideMenu();
                      ref
                          .read(navigationProvider.notifier)
                          .goToProfile(tabIndex: 4);
                    }),

                    const SizedBox(height: 24),
                    _menuSectionLabel('CONFIGURAÇÕES'),
                    _sideMenuItem(
                      Icons.settings_rounded,
                      'Preferências',
                      false,
                      () {
                        _toggleSideMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _sideMenuItem(
                      Icons.notifications_rounded,
                      'Notificações',
                      false,
                      () {
                        _toggleSideMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ModernNotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _sideMenuItem(Icons.favorite_rounded, 'Apoiar', false, () {
                      _toggleSideMenu();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DonationScreen(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Dark Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Modo Escuro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: Theme.of(context).brightness == Brightness.dark,
                    activeColor: colors.primary,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Odyssey v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 1.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _sideMenuItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MAIN CONTENT - Conteúdo Principal
  // ==========================================
  Widget _buildMainContent(
    DateFormat monthFormat,
    AppSettings settings,
    ColorScheme colors,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Main scrollable content
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ==========================================
                  // HEADER CYBERPUNK - RELÓGIO DIGITAL EM TEMPO REAL
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        70,
                        16,
                        20,
                        0,
                      ), // Extra left para menu button
                      child: Builder(
                        builder: (context) {
                          final settings = ref.watch(settingsProvider);
                          return _WellnessHeader(
                            avatarPath: settings.avatarPath,
                            userName: settings.userName,
                            onMenuTap: _toggleSideMenu,
                            onCalendarTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HabitsCalendarScreen(),
                                ),
                              );
                            },
                            onAddTap: () => _showSmartAddSheet(context),
                          );
                        },
                      ),
                    ),
                  ),

                  // ==========================================
                  // BARRA DE BUSCA GLOBAL
                  // ==========================================
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: GlobalSearchBar(),
                    ),
                  ),

                  // ==========================================
                  // ACTIVITY CARD (Meditation/Yoga)
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildWellnessActivityCard(),
                    ),
                  ),

                  // ==========================================
                  // SUGESTÕES INTELIGENTES
                  // ==========================================
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: HomeSuggestionsWidget(),
                    ),
                  ),

                  // ==========================================
                  // INSPIRAÇÃO DO DIA (Highlight)
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildDailyQuoteWidget(),
                    ),
                  ),

                  // ==========================================
                  // REGISTRO DE HUMOR
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildMoodSection(context),
                    ),
                  ),

                  // ==========================================
                  // WIDGETS DINÂMICOS CONFIGURÁVEIS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildDynamicWidgets(),
                    ),
                  ),

                  // ==========================================
                  // SEÇÃO COMUNIDADE (PLACEHOLDER)
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildCommunitySection(),
                    ),
                  ),

                  // ==========================================
                  // NAVEGAÇÃO DE MÊS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _previousMonth();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 140,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(0, 0.2),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  monthFormat
                                      .format(_selectedMonth)
                                      .capitalize(),
                                  key: ValueKey(_selectedMonth.toString()),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _nextMonth();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ==========================================
                  // SEÇÃO COMBINADA HÁBITOS/TAREFAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildHabitsTasksSection(context),
                    ),
                  ),

                  // ==========================================
                  // ESTATÍSTICAS RÁPIDAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildQuickStats(context),
                    ),
                  ),

                  // ==========================================
                  // GRÁFICO SEMANAL
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildWeeklyChart(context),
                    ),
                  ),

                  // ==========================================
                  // INSIGHTS BASEADOS EM DADOS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildDataInsights(context),
                    ),
                  ),

                  // ==========================================
                  // WIDGETS DE NOTAS E LEITURAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildNotesAndReadingsSection(context),
                    ),
                  ),

                  // ==========================================
                  // RESUMO MENSAL
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: _buildMonthlyOverview(context),
                    ),
                  ),

                  // ==========================================
                  // WIDGET DE NOTÍCIAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: _buildNewsWidget(context),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Header (aparece durante scroll)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: (_showFloatingHeader && _isScrolling) ? 0 : -80,
              left: 0,
              right: 0,
              child: _buildFloatingHeader(settings, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(AppSettings settings, ColorScheme colors) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(color: colors.outline.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showModernSideMenu(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.tertiary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.surface,
                    backgroundImage: settings.avatarPath != null
                        ? FileImage(File(settings.avatarPath!))
                        : null,
                    child: settings.avatarPath == null
                        ? Text(
                            settings.userName.isNotEmpty
                                ? settings.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nome
              Expanded(
                child: Text(
                  settings.userName.isNotEmpty ? settings.userName : 'Viajante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Botão Calendário
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HabitsCalendarScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Add
              GestureDetector(
                onTap: () => _showSmartAddSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS DINÂMICOS CONFIGURÁVEIS
  // ==========================================
  Widget _buildDynamicWidgets() {
    final enabledWidgets = ref.watch(enabledHomeWidgetsProvider);

    if (enabledWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: enabledWidgets.map((config) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(sizeFactor: animation, child: child),
              );
            },
            child: _buildWidgetByType(config.type),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommunitySection() {
    final colors = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        final feedAsync = ref.watch(feedProvider);

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Comunidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CommunityScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(
                        'Ver tudo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              feedAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return _buildEmptyCommunityState(colors);
                  }

                  // Mostrar últimos 3 posts
                  final recentPosts = posts.take(3).toList();
                  return Column(
                    children: [
                      ...recentPosts.map(
                        (post) => _buildCommunityPostPreview(post, colors),
                      ),
                      const SizedBox(height: 12),
                      // Botão para criar post
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreatePostScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                            label: Text(
                              'Compartilhar algo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: colors.primary.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (_, __) => _buildEmptyCommunityState(colors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCommunityState(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Icon(
            Icons.groups_rounded,
            size: 48,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Seja o primeiro!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compartilhe suas conquistas e inspire\noutros usuários na comunidade',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Criar Primeiro Post',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostPreview(Post post, ColorScheme colors) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CommunityScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.outlineVariant.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            UserAvatar(
              photoUrl: post.userPhotoUrl,
              level: post.userLevel,
              size: 36,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatTimeAgo(post.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  if (post.totalReactions > 0 || post.commentCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          if (post.totalReactions > 0) ...[
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.totalReactions}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (post.commentCount > 0) ...[
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: colors.onSurfaceVariant.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.commentCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM', 'pt_BR').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }

  Widget _buildWidgetByType(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.quickNotes:
        return const QuickNotesWidget();
      case HomeWidgetType.streak:
        return const StreakWidget();
      case HomeWidgetType.todayTasks:
        return const TodayTasksWidget();
      case HomeWidgetType.quickPomodoro:
        return const QuickPomodoroWidget();
      case HomeWidgetType.dailyQuote:
        return _buildDailyQuoteWidget();
      case HomeWidgetType.weeklyChart:
        return _buildWeeklyChartWidget();
      case HomeWidgetType.currentReading:
        return const CurrentReadingWidget();
      case HomeWidgetType.dailyGoals:
        return const DailyGoalsWidget();
      case HomeWidgetType.habits:
        return _buildHabitsWidgetCompact();
      case HomeWidgetType.activityGrid:
        return const ActivityGridWidget();
      case HomeWidgetType.quickMood:
        return const QuickMoodWidget();
      case HomeWidgetType.weekCalendar:
        return _buildWeekCalendar(context);
      case HomeWidgetType.monthlyOverview:
        return _buildMonthlyOverview(context);
      case HomeWidgetType.waterTracker:
        return const WaterTrackerWidget();
    }
  }

  Widget _buildDailyQuoteWidget() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LibraryScreen(initialType: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: WellnessColors.purpleGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Inspiração do Dia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentInsight,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.7, // Mock progress
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dia ${DateTime.now().day}/30',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartWidget() {
    final colors = Theme.of(context).colorScheme;
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Atividade Semanal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isToday = index == todayIndex;
                final height = 15.0 + (index * 5) + (isToday ? 15 : 0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: height.clamp(10, 45),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [
                                  const Color(0xFF26A69A),
                                  const Color(0xFF26A69A).withOpacity(0.7),
                                ]
                              : [
                                  const Color(0xFF26A69A).withOpacity(0.4),
                                  const Color(0xFF26A69A).withOpacity(0.2),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF26A69A)
                            : colors.onSurfaceVariant.withOpacity(0.7),
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

  Widget _buildHabitsWidgetCompact() {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HabitsCalendarScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.repeat_rounded,
                color: Color(0xFF5C6BC0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hábitos do Dia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Toque para ver seus hábitos',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MOOD SECTION COMPACTO
  // ==========================================
  Widget _buildWellnessActivityCard() {
    return _DayOverviewCard(
      habitRepoInitialized: _habitRepoInitialized,
      taskRepoInitialized: _taskRepoInitialized,
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: ref.read(settingsProvider).avatarPath != null
                    ? FileImage(File(ref.read(settingsProvider).avatarPath!))
                    : null,
                child: ref.read(settingsProvider).avatarPath == null
                    ? Icon(Icons.person, color: colors.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como você está se sentindo?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registre seu humor do momento ✨',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMoodButton(
                'assets/mood_icons/smile.svg',
                'Ótimo',
                WellnessColors.success,
              ),
              _buildMoodButton(
                'assets/mood_icons/calm.svg',
                'Bem',
                WellnessColors.primary,
              ),
              _buildMoodButton(
                'assets/mood_icons/neutral.svg',
                'Ok',
                Colors.amber,
              ),
              _buildMoodButton(
                'assets/mood_icons/sad.svg',
                'Mal',
                Colors.orange,
              ),
              _buildMoodButton(
                'assets/mood_icons/loudly_crying.svg',
                'Péssimo',
                WellnessColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botão de compartilhar na comunidade
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showShareMoodSplash(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Compartilhar com a comunidade',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mostra splash animado e navega para criar post de humor
  void _showShareMoodSplash(
    BuildContext context, {
    String? moodLabel,
    String? moodEmoji,
  }) {
    HapticFeedback.lightImpact();

    // Mostrar overlay animado
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final colors = Theme.of(context).colorScheme;

        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone animado
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.primary,
                                  colors.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      moodEmoji != null
                          ? 'Compartilhando $moodEmoji'
                          : 'Compartilhando com a comunidade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sua experiência pode inspirar outros! ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Aguardar um momento e depois navegar
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pop(); // Fecha o splash
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(
              initialType: PostType.mood,
              initialTopic: CommunityTopic.wellness,
              initialContent: '',
              selectedMoodLabel: moodLabel,
              selectedMoodEmoji: moodEmoji,
            ),
          ),
        );
      }
    });
  }

  Widget _buildMoodButton(String svgPath, String label, Color color) {
    // Mapeamento de labels para emojis
    const moodEmojis = {
      'Ótimo': '😊',
      'Bem': '🙂',
      'Ok': '😐',
      'Mal': '😔',
      'Péssimo': '😢',
    };
    final emoji = moodEmojis[label] ?? '😊';

    return GestureDetector(
      onLongPress: () {
        // Long press para compartilhar diretamente
        HapticFeedback.mediumImpact();
        _showShareMoodSplash(context, moodLabel: label, moodEmoji: emoji);
      },
      child: MotionButton(
        pressedScale: 0.9,
        motion: AppMotion.button,
        onTap: () {
          soundService.playMoodSelect();
          showModalBottomSheet(
            useSafeArea: true,
            isScrollControlled: true,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) =>
                  const AddMoodRecordForm(recordToEdit: null),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CALENDÁRIO SEMANAL (estilo HabitMate)
  // ==========================================
  Widget _buildWeekCalendar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Row(
      children: [
        // Dias da semana
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, now);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = date);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.primary
                              : colors.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : (isToday
                                    ? colors.primaryContainer
                                    : Colors.transparent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colors.onPrimary
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        // Botão expandir/mês (compacto)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isCalendarExpanded = !_isCalendarExpanded);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isCalendarExpanded
                  ? colors.primary
                  : colors.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isCalendarExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.calendar_month_rounded,
              size: 20,
              color: _isCalendarExpanded
                  ? colors.onPrimary
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SEÇÃO COMBINADA HÁBITOS/TAREFAS COM TABS
  // ==========================================
  Widget _buildHabitsTasksSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Conteúdo principal (sempre visível)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab selector animado
            _buildHabitsTasksTabBar(context),
            const SizedBox(height: 12),
            // Calendário semanal (compartilhado)
            _buildWeekCalendar(context),
            const SizedBox(height: 12),
            // Conteúdo dinâmico (Hábitos ou Tarefas)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _habitsTasksTabIndex == 0
                  ? _buildHabitsList(context)
                  : _buildTasksListInline(context),
            ),
          ],
        ),

        // Calendário expandido (overlay)
        if (_isCalendarExpanded)
          Positioned(
            top: 100, // Logo abaixo do tab bar + week calendar
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // Impede taps passarem para o fundo
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini calendário do mês
                    _buildMonthCalendarGrid(context),
                    const SizedBox(height: 12),
                    // Botão fechar
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isCalendarExpanded = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pronto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Calendário do mês em grid
  Widget _buildMonthCalendarGrid(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );
    final startPadding = firstDayOfMonth.weekday - 1; // Segunda = 0

    final days = <Widget>[];
    final dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    // Header com nome do mês
    days.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                    1,
                  );
                });
              },
              child: Icon(Icons.chevron_left_rounded, color: colors.primary),
            ),
            Text(
              DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                    1,
                  );
                });
              },
              child: Icon(Icons.chevron_right_rounded, color: colors.primary),
            ),
          ],
        ),
      ),
    );

    // Dias da semana header
    days.add(
      Row(
        children: dayNames
            .map(
              (name) => Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    days.add(const SizedBox(height: 8));

    // Dias do mês
    final totalDays = lastDayOfMonth.day + startPadding;
    final weeks = (totalDays / 7).ceil();

    for (int week = 0; week < weeks; week++) {
      final weekDays = <Widget>[];
      for (int day = 0; day < 7; day++) {
        final dayIndex = week * 7 + day - startPadding + 1;
        if (dayIndex < 1 || dayIndex > lastDayOfMonth.day) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else {
          final date = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            dayIndex,
          );
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, now);

          weekDays.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : (isToday ? colors.primaryContainer : null),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$dayIndex',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      days.add(Row(children: weekDays));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: days);
  }

  double _calculatePageViewHeight() {
    // Altura mais compacta para melhor uso do espaço
    return 280;
  }

  Widget _buildHabitsTasksTabBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Cores por categoria
    const habitColor = Color(0xFF4CAF50); // Verde
    const taskColor = Color(0xFF2196F3); // Azul

    return Row(
      children: [
        // Tab Hábitos
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _habitsTasksTabIndex = 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: _habitsTasksTabIndex == 0
                    ? const LinearGradient(
                        colors: [habitColor, Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _habitsTasksTabIndex == 0
                    ? null
                    : colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 18,
                    color: _habitsTasksTabIndex == 0
                        ? Colors.white
                        : colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hábitos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _habitsTasksTabIndex == 0
                          ? Colors.white
                          : colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tab Tarefas
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _habitsTasksTabIndex = 1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: _habitsTasksTabIndex == 1
                    ? const LinearGradient(
                        colors: [taskColor, Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _habitsTasksTabIndex == 1
                    ? null
                    : colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: _habitsTasksTabIndex == 1
                        ? Colors.white
                        : colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tarefas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _habitsTasksTabIndex == 1
                          ? Colors.white
                          : colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Lista de tarefas inline (sem card wrapper) para o PageView
  Widget _buildTasksListInline(BuildContext context) {
    if (!_taskRepoInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final taskRepo = ref.watch(taskRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<TaskData>>(
      future: taskRepo.getTasksForDate(_selectedDate),
      builder: (context, snapshot) {
        // Não mostra loading se já tem dados (evita flash)
        final tasks = snapshot.data ?? [];
        final isFirstLoad =
            !snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting;

        if (isFirstLoad) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final pendingTasks = tasks.where((t) => !t.completed).toList();
        final completedTasks = tasks.where((t) => t.completed).toList();

        // Input field é sempre exibido primeiro (fora do AnimatedSwitcher)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick add task field - sempre visível, sem animação
            _buildQuickAddTaskField(colors, taskRepo),
            const SizedBox(height: 16),

            // Conteúdo animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: tasks.isEmpty
                  ? _buildEmptyTasksContent(context, colors)
                  : _buildTasksContent(
                      context,
                      colors,
                      pendingTasks,
                      completedTasks,
                      key: ValueKey(
                        'tasks_${tasks.length}_${pendingTasks.length}',
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Campo de adicionar tarefa separado (não re-renderiza)
  Widget _buildQuickAddTaskField(ColorScheme colors, TaskRepository taskRepo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.08),
            colors.primaryContainer.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(
              Icons.add_task_rounded,
              color: colors.primary.withOpacity(0.6),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _quickTaskController,
              onSubmitted: (_) => _createQuickTask(taskRepo),
              decoration: InputDecoration(
                hintText: 'Adicionar nova tarefa...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _createQuickTask(taskRepo),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Conteúdo quando não há tarefas
  Widget _buildEmptyTasksContent(BuildContext context, ColorScheme colors) {
    return Container(
      key: const ValueKey('empty_tasks'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 48,
            color: UltravioletColors.accentGreen.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            _isSameDay(_selectedDate, DateTime.now())
                ? 'Nenhuma tarefa para hoje!'
                : 'Nenhuma tarefa para este dia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Digite acima para criar',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Conteúdo quando há tarefas
  Widget _buildTasksContent(
    BuildContext context,
    ColorScheme colors,
    List<TaskData> pendingTasks,
    List<TaskData> completedTasks, {
    Key? key,
  }) {
    final completed = completedTasks.length;
    final total = pendingTasks.length + completedTasks.length;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com progresso
        Row(
          children: [
            Text(
              'Para ${_isSameDay(_selectedDate, DateTime.now()) ? "hoje" : DateFormat('dd/MM').format(_selectedDate)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completed.toDouble()),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: completed == total && total > 0
                        ? UltravioletColors.accentGreen.withOpacity(0.15)
                        : colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${value.round()}/$total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completed == total && total > 0
                          ? UltravioletColors.accentGreen
                          : colors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            HeaderArrowButton(
              colors: colors,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress bar animada
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: total > 0 ? completed / total : 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  completed == total && total > 0
                      ? UltravioletColors.accentGreen
                      : colors.primary,
                ),
                minHeight: 5,
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Tarefas pendentes com animação individual
        ...pendingTasks.asMap().entries.map((entry) {
          return TweenAnimationBuilder<double>(
            key: ValueKey(entry.value.key),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (entry.key * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: _buildTaskItem(context, entry.value),
                ),
              );
            },
          );
        }),

        // Botão mostrar/ocultar concluídos
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showCompletedTasks = !_showCompletedTasks);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _showCompletedTasks ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showCompletedTasks
                        ? 'Ocultar Concluídas (${completedTasks.length})'
                        : 'Ver Concluídas (${completedTasks.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Tarefas concluídas (com animação)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showCompletedTasks
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    ...completedTasks.map(
                      (task) => _buildTaskItem(context, task),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskData task) {
    final colors = Theme.of(context).colorScheme;
    final isCompleted = task.completed;
    final syncedRepo = ref.read(syncedTaskRepositoryProvider);

    // Helpers para cores de prioridade
    Color priorityColor;
    switch (task.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      case 'medium':
      default:
        priorityColor = Colors.orange;
    }

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              TaskFormSheet(task: task, onSave: (_) => setState(() {})),
        ).then((_) => setState(() {}));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? UltravioletColors.accentGreen.withOpacity(0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? UltravioletColors.accentGreen.withOpacity(0.2)
                : colors.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox clicável
            // Checkbox clicável com hover
            TaskCheckbox(
              isCompleted: isCompleted,
              colors: colors,
              onTap: () async {
                HapticFeedback.lightImpact();
                await syncedRepo.toggleTaskCompletion(task.key);
                setState(() {});
              },
            ),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e Prioridade
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? colors.onSurfaceVariant.withOpacity(0.7)
                                : colors.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colors.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ),
                      // Badge de Prioridade
                      if (!isCompleted && task.priority != 'medium')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: priorityColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Notes (Descrição)
                  if (task.notes != null &&
                      task.notes!.isNotEmpty &&
                      !isCompleted) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Metadata Row (Data, Hora, Tag)
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Data
                        if (task.dueDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM').format(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                        // Hora
                        if (task.dueTime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.dueTime!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                        // Categoria (Tag)
                        if (task.category != null && task.category!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.category!,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LISTA DE HÁBITOS EXPANDÍVEIS
  // ==========================================
  Widget _buildHabitsList(BuildContext context) {
    if (!_habitRepoInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final allHabits = habitRepo.getHabitsForDate(_selectedDate);

        if (allHabits.isEmpty) {
          return _buildEmptyHabitsState(context);
        }

        // Separar pendentes e concluídos
        final pendingHabits = allHabits
            .where((h) => !h.isCompletedOn(_selectedDate))
            .toList();
        final completedHabits = allHabits
            .where((h) => h.isCompletedOn(_selectedDate))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hábitos pendentes
            ...pendingHabits.map(
              (habit) => _buildExpandableHabitCard(context, habit, habitRepo),
            ),

            // Botão mostrar/ocultar concluídos
            if (completedHabits.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showCompletedHabits = !_showCompletedHabits);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showCompletedHabits
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showCompletedHabits
                            ? 'Ocultar Concluídos (${completedHabits.length})'
                            : 'Mostrar Concluídos (${completedHabits.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Hábitos concluídos (com animação)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCompletedHabits
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        ...completedHabits.map(
                          (habit) => _buildExpandableHabitCard(
                            context,
                            habit,
                            habitRepo,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandableHabitCard(
    BuildContext context,
    Habit habit,
    HabitRepository repo,
  ) {
    final isExpanded = _expandedHabitId == habit.id;
    final isCompleted = habit.isCompletedOn(_selectedDate);
    final color = Color(habit.colorValue);
    final streak = habit.calculateCurrentStreak();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withOpacity(0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? color.withOpacity(0.4)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header do hábito
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _expandedHabitId = isExpanded ? null : habit.id;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Checkbox circular para marcar como concluído
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await repo.toggleHabitCompletion(
                          habit.id,
                          _selectedDate,
                        );

                        if (!isCompleted && mounted) {
                          final currentStreak =
                              habit.calculateCurrentStreak() + 1;
                          try {
                            final gamificationRepo = ref.read(
                              gamificationRepositoryProvider,
                            );
                            await gamificationRepo.completeTask();
                            if (mounted) {
                              FeedbackService.showHabitCompleted(
                                context,
                                habit.name,
                                streak: currentStreak,
                                xp: 15,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              FeedbackService.showHabitCompleted(
                                context,
                                habit.name,
                                streak: currentStreak,
                              );
                            }
                          }
                        } else if (mounted) {
                          FeedbackService.showHabitUncompleted(
                            context,
                            habit.name,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCompleted ? color : color.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? color : color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    size: 24,
                                    key: const ValueKey('check'),
                                  )
                                : Icon(
                                    IconData(
                                      habit.iconCode,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: color,
                                    size: 22,
                                    key: const ValueKey('icon'),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nome e streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (streak > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$streak dias',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (habit.scheduledTime != null) ...[
                                Icon(
                                  Icons.schedule,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  habit.scheduledTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Seta expandir
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botões de ação (sempre visíveis)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                // Edit
                TextButton.icon(
                  onPressed: () => _showEditHabitFormDialog(context, habit),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Editar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const Spacer(),
                // Concluir/Desfazer
                isCompleted
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await repo.toggleHabitCompletion(
                            habit.id,
                            _selectedDate,
                          );

                          if (mounted) {
                            FeedbackService.showHabitUncompleted(
                              context,
                              habit.name,
                            );
                          }
                        },
                        icon: Icon(Icons.undo, size: 16, color: color),
                        label: Text(
                          'Desfazer',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await repo.toggleHabitCompletion(
                            habit.id,
                            _selectedDate,
                          );

                          if (mounted) {
                            final currentStreak =
                                habit.calculateCurrentStreak() + 1;
                            try {
                              final gamificationRepo = ref.read(
                                gamificationRepositoryProvider,
                              );
                              await gamificationRepo.completeTask();
                              FeedbackService.showHabitCompleted(
                                context,
                                habit.name,
                                streak: currentStreak,
                                xp: 15,
                              );
                            } catch (e) {
                              FeedbackService.showHabitCompleted(
                                context,
                                habit.name,
                                streak: currentStreak,
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Concluir',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          elevation: 2,
                          shadowColor: color.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          // Conteúdo expandido (apenas calendário)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  color: UltravioletColors.outline.withOpacity(0.1),
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHabitMonthCalendar(habit),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Calendário mensal dentro do hábito expandido (estilo HabitMate)
  Widget _buildHabitMonthCalendar(Habit habit) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final color = Color(habit.colorValue);
    final today = DateTime.now();

    // Dias do mês anterior para preencher
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final daysInPrevMonth = DateTime(
      prevMonth.year,
      prevMonth.month + 1,
      0,
    ).day;

    List<Widget> dayWidgets = [];

    // Dias do mês anterior
    for (int i = startWeekday - 1; i > 0; i--) {
      final day = daysInPrevMonth - i + 1;
      dayWidgets.add(_buildCalendarDay(day, false, false, false, color));
    }

    // Dias do mês atual
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isCompleted = habit.isCompletedOn(date);
      final isToday = _isSameDay(date, today);
      final isSelected = _isSameDay(date, _selectedDate);
      dayWidgets.add(
        _buildCalendarDay(day, true, isCompleted, isToday || isSelected, color),
      );
    }

    // Dias do próximo mês
    final remainingDays = 42 - dayWidgets.length;
    for (int day = 1; day <= remainingDays; day++) {
      dayWidgets.add(_buildCalendarDay(day, false, false, false, color));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize =
            (constraints.maxWidth - 6 * 4) / 7; // 7 cells with 4px spacing
        final size = cellSize.clamp(28.0, 36.0);

        return Column(
          children: [
            // Header dos dias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayNames
                  .map(
                    (d) => SizedBox(
                      width: size,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Grid de dias
            ...List.generate(6, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    return _buildCalendarDayResponsive(dayWidgets[index], size);
                  }),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCalendarDayResponsive(Widget original, double size) {
    // Extract the data from the original widget
    // Since we're using fixed widgets, we just return it with constrained size
    return SizedBox(width: size, height: size, child: original);
  }

  Widget _buildCalendarDay(
    int day,
    bool isCurrentMonth,
    bool isCompleted,
    bool isHighlighted,
    Color color,
  ) {
    // Determine text color based on state for visibility in any theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color textColor;
    if (isCompleted) {
      // If completed, background is soft color tint, so text should be darker color
      textColor = color;
    } else if (isHighlighted) {
      // Highlighted usually means filled with color
      textColor = Colors.white;
    } else if (isCurrentMonth) {
      // Normal day number
      textColor = colorScheme.onSurface;
    } else {
      // Other month day number
      textColor = colorScheme.onSurface.withOpacity(0.3);
    }

    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withOpacity(0.15) // Soft tint for completed
            : (isHighlighted ? color : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
        border: isCompleted
            ? Border.all(color: color, width: 1.5) // Border for completed
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted || isHighlighted
                ? FontWeight.w600
                : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHabitsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: UltravioletColors.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum hábito para este dia',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAddHabitDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: UltravioletColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: UltravioletColors.primary.withOpacity(0.5),
                ),
              ),
              child: const Text(
                '+ Criar hábito',
                style: TextStyle(
                  color: UltravioletColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ESTATÍSTICAS RÁPIDAS
  // ==========================================
  Widget _buildQuickStats(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final allHabits = habitRepo.getAllHabits();
        final todayHabits = habitRepo.getHabitsForDate(_selectedDate);
        final completedToday = todayHabits
            .where((h) => h.isCompletedOn(_selectedDate))
            .length;

        // Calcular melhor streak
        int bestStreak = 0;
        for (final habit in allHabits) {
          final streak = habit.calculateCurrentStreak();
          if (streak > bestStreak) bestStreak = streak;
        }

        // Taxa de conclusão da semana
        double weekRate = 0;
        final weekRates = habitRepo.getWeekCompletionRates();
        if (weekRates.isNotEmpty) {
          weekRate =
              weekRates.values.reduce((a, b) => a + b) / weekRates.length;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Resumo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats pills row
              Row(
                children: [
                  // Streak pill
                  Expanded(
                    child: _buildStatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '$bestStreak',
                      suffix: 'd',
                      label: 'Streak',
                      color: const Color(0xFFFF6B6B),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hoje pill
                  Expanded(
                    child: _buildStatPill(
                      icon: Icons.check_circle_rounded,
                      value: '$completedToday',
                      suffix: '/${todayHabits.length}',
                      label: 'Hoje',
                      color: WellnessColors.success,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Semana pill
                  Expanded(
                    child: _buildStatPill(
                      icon: Icons.trending_up_rounded,
                      value: '${(weekRate * 100).round()}',
                      suffix: '%',
                      label: 'Semana',
                      color: UltravioletColors.primary,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    String? suffix,
    required String label,
    required Color color,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  Widget _buildWeeklyChart(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return OdysseyCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              // Chart Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chartViewMode = _chartViewMode == 0 ? 1 : 0;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withOpacity(0.1)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _chartViewMode == 0
                          ? Icons.pie_chart_rounded
                          : Icons.show_chart_rounded,
                      key: ValueKey(_chartViewMode),
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Premium Category Selector Pills
          Row(
            children: [
              _buildPremiumTab(0, 'Hábitos', Icons.check_circle_outline),
              _buildPremiumTab(1, 'Foco', Icons.timer_outlined),
              _buildPremiumTab(2, 'Humor', Icons.mood_outlined),
            ],
          ),

          const SizedBox(height: 32),

          // Chart Area
          SizedBox(
            height: 220,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              child: KeyedSubtree(
                key: ValueKey(_selectedChartIndex),
                child: _buildSelectedChart(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(int index, String label, IconData icon) {
    final isSelected = _selectedChartIndex == index;
    final colors = Theme.of(context).colorScheme;

    // Cores por categoria
    final categoryColors = [
      const Color(0xFF4CAF50), // Hábitos - Verde
      const Color(0xFF2196F3), // Foco - Azul
      const Color(0xFFFF9800), // Humor - Laranja
    ];
    final color = categoryColors[index];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedChartIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : colors.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : colors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context) {
    if (_chartViewMode == 1) {
      switch (_selectedChartIndex) {
        case 0:
          return _buildHabitsRadarChartAnalysis(context);
        case 1:
          return _buildFocusDonutChart(context);
        case 2:
          return _buildMoodFrequencyChart(context);
      }
    }

    switch (_selectedChartIndex) {
      case 0:
        return _buildHabitsBarChart(context);
      case 1:
        return _buildFocusLineChart(context);
      case 2:
        return _buildMoodTrendChart(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHabitsBarChart(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        double totalRate = 0;
        for (var rate in weekRates.values) {
          totalRate += rate;
        }
        final avgRate = (totalRate / 7 * 100).toInt();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Média Semanal',
                  '$avgRate%',
                  Icons.bar_chart_rounded,
                  colors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceContainerHighest,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY * 100).toInt()}%',
                          TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '\nConcluído',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dayNames.length) {
                            return const SizedBox.shrink();
                          }

                          final isToday = index == (DateTime.now().weekday - 1);
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: isToday
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final rate = weekRates[index] ?? 0.0;
                    final isToday = index == (DateTime.now().weekday - 1);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: rate.clamp(0.01, 1.0),
                          gradient: LinearGradient(
                            colors: isToday
                                ? [colors.primary, colors.tertiary]
                                : [
                                    const Color(0xFF07E092).withOpacity(0.7),
                                    const Color(0xFF00C853),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 1.0,
                            color: colors.surfaceContainerHighest.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  maxY: 1.05,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieDetail(
    String title,
    String value,
    Color color, {
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Container(
          width: isLarge ? 12 : 8,
          height: isLarge ? 12 : 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isLarge ? 14 : 11,
                  fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isLarge)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (!isLarge)
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  // ==========================================
  // FOCUS CHARTS (Values: 0: Line, 2: Scatter)
  // ==========================================

  Widget _buildFocusLineChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final dailyMinutes = List.filled(7, 0.0);

        final allRecords = timeRepo.fetchAllTimeTrackingRecords();
        for (var record in allRecords) {
          if (record.startTime.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              record.startTime.isBefore(endOfWeek)) {
            final dayIndex = record.startTime.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              dailyMinutes[dayIndex] += record.durationInSeconds / 60;
            }
          }
        }

        final maxVal = dailyMinutes.reduce(max);

        if (maxVal == 0) {
          return Center(
            child: Text(
              'Sem sessões de foco',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final totalMinutes =
            dailyMinutes.reduce((value, element) => value + element) * 60;
        final totalHours = totalMinutes / 60;
        final dailyAvg = totalHours / 7;

        final allPoints = <FlSpot>[];
        for (int i = 0; i < 7; i++) {
          allPoints.add(FlSpot(i.toDouble(), dailyMinutes[i]));
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Total Foco',
                  '${totalHours.toStringAsFixed(1)}h',
                  Icons.timer_outlined,
                  colors.primary,
                ),
                _buildAnalysisBadge(
                  context,
                  'Média Diária',
                  '${dailyAvg.toStringAsFixed(1)}h',
                  Icons.show_chart_rounded,
                  colors.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    verticalInterval: 1,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 15,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: colors.outlineVariant.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 7) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              dayNames[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxVal > 0 ? maxVal * 1.2 : 60,
                  lineBarsData: [
                    LineChartBarData(
                      spots: allPoints,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: colors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colors.surface,
                            strokeWidth: 2,
                            strokeColor: colors.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            colors.primary.withOpacity(0.3),
                            colors.primary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hours = spot.y.toInt();
                          final minutes = ((spot.y - hours) * 60).toInt();
                          return LineTooltipItem(
                            '${hours}h ${minutes}m',
                            TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // MOOD CHARTS
  // ==========================================

  Widget _buildMoodTrendChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        final dailyScores = List.filled(7, 0.0);
        final dailyCounts = List.filled(7, 0);

        final allRecords = moodRepo.fetchMoodRecords().values;
        for (var record in allRecords) {
          if (record.date.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              record.date.isBefore(endOfWeek)) {
            final dayIndex = record.date.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              dailyScores[dayIndex] += record.score;
              dailyCounts[dayIndex]++;
            }
          }
        }

        final spots = <FlSpot>[];
        double totalScore = 0;
        int totalDays = 0;

        for (int i = 0; i < 7; i++) {
          if (dailyCounts[i] > 0) {
            final dailyAvg = dailyScores[i] / dailyCounts[i];
            spots.add(FlSpot(i.toDouble(), dailyAvg));
            totalScore += dailyAvg;
            totalDays++;
          }
        }

        if (spots.isEmpty) {
          return Center(
            child: Text(
              'Sem registros de humor',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final avgMood = totalScore / totalDays;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Humor Médio',
                  avgMood.toStringAsFixed(1),
                  Icons.mood,
                  _getColorForScore(avgMood),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 7) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              dayNames[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 1,
                  maxY: 5.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF5E5E),
                          Color(0xFFFFB703),
                          Color(0xFF07E092),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          Color color = Colors.grey;
                          if (spot.y >= 4) {
                            color = const Color(0xFF07E092);
                          } else if (spot.y >= 3) {
                            color = const Color(0xFFFFB703);
                          } else {
                            color = const Color(0xFFFF5E5E);
                          }

                          return FlDotCirclePainter(
                            radius: 5,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: colors.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFB703).withOpacity(0.2),
                            const Color(0xFFFFB703).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceContainerHighest,

                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String moodText;
                          if (spot.y >= 4.5) {
                            moodText = 'Maravilhoso';
                          } else if (spot.y >= 3.5) {
                            moodText = 'Bem';
                          } else if (spot.y >= 2.5) {
                            moodText = 'Neutro';
                          } else if (spot.y >= 1.5) {
                            moodText = 'Mal';
                          } else {
                            moodText = 'Horrível';
                          }
                          return LineTooltipItem(
                            moodText,
                            TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // ANALYSIS CHARTS (Mode 1 - Premium Views)
  // ==========================================

  Widget _buildFocusDonutChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        final allRecords = timeRepo.fetchAllTimeTrackingRecords();
        final weeklyRecords = allRecords
            .where(
              (r) =>
                  r.startTime.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                  ) &&
                  r.startTime.isBefore(endOfWeek),
            )
            .toList();

        final durationByActivity = <String, double>{};
        double totalMinutes = 0;

        for (var record in weeklyRecords) {
          final minutes = record.durationInSeconds / 60;
          if (minutes > 0) {
            durationByActivity.update(
              record.activityName,
              (v) => v + minutes,
              ifAbsent: () => minutes,
            );
            totalMinutes += minutes;
          }
        }

        if (totalMinutes == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.donut_small_rounded,
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem foco essa semana',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedEntries = durationByActivity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Row(
          children: [
            Expanded(
              flex: 5, // Slightly more space for chart
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      startDegreeOffset: 270,
                      sections: List.generate(sortedEntries.length, (i) {
                        final entry = sortedEntries[i];
                        final isTouched = i == _focusTouchedIndex;
                        return PieChartSectionData(
                          color: _getNiceColor(i, colors),
                          value: entry.value,
                          title: '',
                          radius: isTouched ? 30 : 25,
                          showTitle: false,
                        );
                      }),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _focusTouchedIndex = -1;
                              return;
                            }
                            _focusTouchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _focusTouchedIndex != -1 &&
                                _focusTouchedIndex < sortedEntries.length
                            ? sortedEntries[_focusTouchedIndex].key
                            : 'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _focusTouchedIndex != -1 &&
                                _focusTouchedIndex < sortedEntries.length
                            ? '${(sortedEntries[_focusTouchedIndex].value).toInt()}m'
                            : '${(totalMinutes / 60).toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Atividades',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedEntries.take(4).map((e) {
                      final i = sortedEntries.indexOf(e);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getNiceColor(i, colors),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(e.value / totalMinutes * 100).toInt()}% • ${(e.value).toInt()}m',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getNiceColor(int index, ColorScheme colors) {
    final palette = [
      const Color(0xFF6930C3),
      const Color(0xFF5E60CE),
      const Color(0xFF5390D9),
      const Color(0xFF48BFE3),
      const Color(0xFF64DFDF),
    ];
    return palette[index % palette.length];
  }

  Widget _buildMoodFrequencyChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final records = moodRepo
            .fetchMoodRecords()
            .values
            .where(
              (r) =>
                  r.date.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                  ) &&
                  r.date.isBefore(endOfWeek),
            )
            .toList();

        if (records.isEmpty) {
          return Center(
            child: Text(
              'Sem registros',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final counts = List.filled(6, 0); // 1 to 5
        int maxCount = 0;
        int dominantScore = 0;

        for (var r in records) {
          final score = r.score.round().clamp(1, 5);
          counts[score]++;
          if (counts[score] > maxCount) {
            maxCount = counts[score];
            dominantScore = score;
          }
        }

        final dominantLabel = dominantScore > 0
            ? [
                '',
                'Horrível',
                'Mal',
                'Neutro',
                'Bem',
                'Maravilhoso',
              ][dominantScore]
            : 'N/A';
        final dominantIconData = dominantScore > 0
            ? [
                Icons.sentiment_very_dissatisfied,
                Icons.sentiment_very_dissatisfied,
                Icons.sentiment_dissatisfied,
                Icons.sentiment_neutral,
                Icons.sentiment_satisfied,
                Icons.sentiment_very_satisfied_rounded,
              ][dominantScore]
            : Icons.help_outline;

        return Column(
          children: [
            // Summary Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  dominantIconData,
                  color: dominantScore > 0
                      ? _getColorForScore(dominantScore.toDouble())
                      : colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    text: 'Humor Predominante: ',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: dominantLabel,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount + 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final index = val.toInt();
                          if (index < 1 || index > 5) {
                            return const SizedBox.shrink();
                          }
                          final iconData = [
                            Icons.sentiment_very_dissatisfied,
                            Icons.sentiment_dissatisfied,
                            Icons.sentiment_neutral,
                            Icons.sentiment_satisfied,
                            Icons.sentiment_very_satisfied_rounded,
                          ][index - 1];
                          return SideTitleWidget(
                            meta: meta,
                            child: Icon(
                              iconData,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(5, (i) {
                    final score = i + 1;
                    final count = counts[score];
                    Color color;
                    switch (score) {
                      case 5:
                        color = const Color(0xFF07E092);
                        break;
                      case 4:
                        color = const Color(0xFFB5E48C);
                        break;
                      case 3:
                        color = const Color(0xFFFFB703);
                        break;
                      case 2:
                        color = const Color(0xFFFF832B);
                        break;
                      default:
                        color = const Color(0xFFFF5E5E);
                        break;
                    }

                    return BarChartGroupData(
                      x: score,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: color,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (maxCount + 1).toDouble(),
                            color: colors.surfaceContainerHighest.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: count > 0 ? [0] : [],
                    );
                  }),
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 2,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toInt().toString(),
                          TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsRadarChartAnalysis(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        final entries = <RadarEntry>[];
        bool hasData = false;
        double totalRate = 0;
        int maxDayIndex = 0;
        double maxRate = -1;

        for (int i = 0; i < 7; i++) {
          final baseRate = weekRates[i] ?? 0.0;
          final val = baseRate * 100;
          if (val > 0) hasData = true;
          totalRate += baseRate;
          if (baseRate > maxRate) {
            maxRate = baseRate;
            maxDayIndex = i;
          }
          entries.add(RadarEntry(value: val));
        }

        if (!hasData) {
          return Center(
            child: Text(
              'Sem dados esta semana',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final consistency = (totalRate / 7 * 100).toInt();
        final bestDay = dayNames[maxDayIndex];

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Consistência',
                  '$consistency%',
                  Icons.timelapse_rounded,
                  colors.primary,
                ),
                _buildAnalysisBadge(
                  context,
                  'Melhor Dia',
                  bestDay,
                  Icons.calendar_today_rounded,
                  const Color(0xFF07E092),
                ),
              ],
            ),
            Expanded(
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  tickCount: 1,
                  gridBorderData: BorderSide(
                    color: colors.outlineVariant.withOpacity(0.2),
                    width: 1,
                  ),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  titleTextStyle: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  getTitle: (index, angle) => RadarChartTitle(
                    text: dayNames[index],
                    angle: 0,
                  ), // fixed angle
                  dataSets: [
                    RadarDataSet(
                      fillColor: colors.primary.withOpacity(0.25),
                      borderColor: colors.primary.withOpacity(0.8),
                      entryRadius: 3,
                      borderWidth: 2,
                      dataEntries: entries,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisBadge(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void refresh() {
    if (mounted) setState(() {});
  }
}

// Continuation of _HomeScreenState methods
extension _HomeScreenStateDataInsights on _HomeScreenState {
  // Handle insight card tap - navigate to relevant screen
  void _handleInsightTap(String route) {
    final colors = Theme.of(context).colorScheme;
    String message;
    IconData icon;

    switch (route) {
      case 'habits':
        message = 'Vá para a aba de Hábitos para ver mais detalhes';
        icon = Icons.check_box_rounded;
        break;
      case 'tasks':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TasksScreen()));
        return;
      case 'focus':
        message = 'Vá para a aba de Foco para ver suas sessões';
        icon = Icons.timer_rounded;
        break;
      case 'mood':
        message = 'Registre seu humor para mais insights';
        icon = Icons.mood_rounded;
        break;
      case 'notes':
        message = 'Continue criando notas para capturar ideias';
        icon = Icons.lightbulb_rounded;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: colors.onPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.primary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // INSIGHTS BASEADOS EM DADOS - REDESIGNED 🔥
  // ==========================================
  Widget _buildDataInsights(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);
    final notesRepo = ref.watch(notesRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, habitBox, _) {
        final taskListenable = taskRepo.boxListenable;
        if (taskListenable == null) return const SizedBox.shrink();

        return ValueListenableBuilder(
          valueListenable: taskListenable,
          builder: (context, taskBox, _) {
            final allHabits = habitRepo.getAllHabits();
            if (allHabits.isEmpty) return const SizedBox.shrink();

            final colors = Theme.of(context).colorScheme;
            final now = DateTime.now();

            // CALCULAR ESTATÍSTICAS GERAIS DO APP

            // 1. Hábitos
            Habit? bestHabit;
            int bestStreak = 0;
            for (final h in allHabits) {
              final s = h.calculateCurrentStreak();
              if (s > bestStreak) {
                bestStreak = s;
                bestHabit = h;
              }
            }

            int consistentDays = 0;
            for (int i = 0; i < 7; i++) {
              final date = now.subtract(Duration(days: i));
              final dayHabits = habitRepo.getHabitsForDate(date);
              if (dayHabits.any((h) => h.isCompletedOn(date))) {
                consistentDays++;
              }
            }

            final morningHabits = allHabits.where((h) {
              if (h.scheduledTime == null) return false;
              final parts = h.scheduledTime!.split(':');
              if (parts.length != 2) return false;
              final hour = int.tryParse(parts[0]) ?? 12;
              return hour < 10;
            }).length;

            // 2. Mood Records
            final allMoods = moodRepo.fetchMoodRecords().values.where((m) {
              final diff = now.difference(m.date).inDays;
              return diff <= 7;
            }).toList();

            final avgMoodScore = allMoods.isNotEmpty
                ? allMoods.fold(0.0, (sum, m) => sum + m.score) /
                      allMoods.length
                : 0.0;

            // 3. Tasks
            final allTasks = taskBox.keys
                .map((key) {
                  final value = taskBox.get(key);
                  if (value is Map) {
                    return TaskData.fromMap(
                      key,
                      Map<String, dynamic>.from(value),
                    );
                  }
                  return null;
                })
                .whereType<TaskData>()
                .toList();
            final completedTasks = allTasks.where((t) => t.completed).length;
            final taskCompletionRate = allTasks.isNotEmpty
                ? completedTasks / allTasks.length
                : 0.0;

            // 4. Time Tracking
            final timeRecords = timeRepo.fetchAllTimeTrackingRecords();
            final weekRecords = timeRecords.where((r) {
              return now.difference(r.startTime).inDays <= 7;
            }).toList();
            final totalMinutes = weekRecords.fold(
              0.0,
              (sum, r) => sum + (r.durationInSeconds / 60),
            );

            // 5. Notes
            final allNotes = notesRepo.getAllNotes();
            final recentNotes = allNotes.where((n) {
              final updated = DateTime.tryParse(n['updatedAt'] ?? '');
              if (updated == null) return false;
              return now.difference(updated).inDays <= 7;
            }).length;

            // GERAR INSIGHTS DINÂMICOS
            List<Map<String, dynamic>> insights = [];

            // Insight sobre streak
            if (bestStreak >= 7) {
              insights.add({
                'icon': Icons.emoji_events_rounded,
                'gradient': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                'text':
                    '🏆 Incrível! ${bestHabit?.name} está em uma sequência de $bestStreak dias!',
                'badge': '$bestStreak dias',
              });
            } else if (bestStreak >= 3) {
              insights.add({
                'icon': Icons.local_fire_department_rounded,
                'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFFA556)],
                'text':
                    '🔥 ${bestHabit?.name} está em alta com $bestStreak dias seguidos!',
                'badge': '$bestStreak dias',
                'route': 'habits',
              });
            }

            // Insight sobre consistência
            if (consistentDays >= 6) {
              insights.add({
                'icon': Icons.star_rounded,
                'gradient': [const Color(0xFF07E092), const Color(0xFF00B4D8)],
                'text':
                    '⭐ Você foi consistente em $consistentDays dos últimos 7 dias. Excelente!',
                'badge': '${(consistentDays / 7 * 100).round()}%',
                'route': 'habits',
              });
            } else if (consistentDays >= 4) {
              insights.add({
                'icon': Icons.trending_up_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    'Boa consistência! Ativo em $consistentDays dias esta semana.',
                'badge': '$consistentDays/7',
                'route': 'habits',
              });
            }

            // Insight sobre humor
            if (allMoods.isNotEmpty) {
              String moodText = 'Bem';
              if (avgMoodScore >= 4.5) {
                moodText = 'Excelente';
              } else if (avgMoodScore >= 3.5) {
                moodText = 'Bem';
              } else if (avgMoodScore >= 2.5) {
                moodText = 'Ok';
              } else {
                moodText = 'Desafiador';
              }

              insights.add({
                'icon': Icons.mood_rounded,
                'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                'text':
                    'Seu humor médio esta semana está $moodText (${avgMoodScore.toStringAsFixed(1)}/5).',
                'badge': '${allMoods.length} registros',
                'route': 'mood',
              });
            }

            // Insight sobre tarefas
            if (allTasks.length >= 5) {
              insights.add({
                'icon': Icons.check_circle_rounded,
                'gradient': [const Color(0xFF07E092), const Color(0xFF00B4D8)],
                'text':
                    'Taxa de conclusão de tarefas: ${(taskCompletionRate * 100).round()}% ($completedTasks de ${allTasks.length}).',
                'badge': '${(taskCompletionRate * 100).round()}%',
                'route': 'tasks',
              });
            }

            // Insight sobre foco
            if (totalMinutes >= 60) {
              final hours = (totalMinutes / 60).toStringAsFixed(1);
              insights.add({
                'icon': Icons.timer_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    'Você focou por ${hours}h esta semana. Mantendo o ritmo!',
                'badge': '${hours}h',
                'route': 'focus',
              });
            }

            // Insight sobre notas
            if (recentNotes > 0) {
              insights.add({
                'icon': Icons.lightbulb_rounded,
                'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                'text':
                    '$recentNotes nota${recentNotes > 1 ? 's' : ''} criada${recentNotes > 1 ? 's' : ''} esta semana. Capturando ideias!',
                'badge': '$recentNotes nota${recentNotes > 1 ? 's' : ''}',
                'route': 'notes',
              });
            }

            // Insight sobre horário matinal
            if (morningHabits > 0) {
              insights.add({
                'icon': Icons.wb_sunny_rounded,
                'gradient': [const Color(0xFFFFA556), const Color(0xFFFF6B6B)],
                'text':
                    'Você tem $morningHabits hábito(s) matinal(is). Ótimo para produtividade!',
                'badge': '$morningHabits matinais',
                'route': 'habits',
              });
            }

            // Fallback
            if (insights.isEmpty) {
              insights.add({
                'icon': Icons.rocket_launch_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    'Continue assim! Cada pequeno passo conta na sua jornada.',
                'badge': 'Vamos lá!',
                'route': null,
              });
            }

            // Pegar os 3 insights mais relevantes
            final topInsights = insights.take(3).toList();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withOpacity(0.3),
                    colors.secondaryContainer.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Moderno e Minimalista
                  Row(
                    children: [
                      // Ícone simples com gradiente sutil
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withOpacity(0.15),
                              colors.tertiary.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_graph_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Análise do seu progresso semanal',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Insights cards
                  ...List.generate(topInsights.length, (index) {
                    final insight = topInsights[index];
                    final route = insight['route'] as String?;

                    // Staggered animation
                    final start = index * 0.15;
                    final end = start + 0.6;
                    final animation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _staggeredInsightsController,
                            curve: Interval(
                              start,
                              end > 1.0 ? 1.0 : end,
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                        );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: route != null
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _handleInsightTap(route);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.outline.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Ícone com gradiente
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors:
                                            insight['gradient'] as List<Color>,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      insight['icon'] as IconData,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Texto
                                  Expanded(
                                    child: Text(
                                      insight['text'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.onSurface.withOpacity(
                                          0.9,
                                        ),
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Badge + Arrow
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              (insight['gradient']
                                                      as List<Color>)
                                                  .first
                                                  .withOpacity(0.2),
                                              (insight['gradient']
                                                      as List<Color>)
                                                  .last
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                (insight['gradient']
                                                        as List<Color>)
                                                    .first
                                                    .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          insight['badge'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                (insight['gradient']
                                                        as List<Color>)
                                                    .first,
                                          ),
                                        ),
                                      ),
                                      if (route != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: colors.onSurfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // Resumo geral do app
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                          icon: Icons.repeat_rounded,
                          value: '${allHabits.length}',
                          label: 'Hábitos',
                          color: const Color(0xFF5E60CE),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: colors.outline.withOpacity(0.2),
                        ),
                        _buildMiniStat(
                          icon: Icons.check_circle_rounded,
                          value: '${allTasks.length}',
                          label: 'Tarefas',
                          color: const Color(0xFF07E092),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: colors.outline.withOpacity(0.2),
                        ),
                        _buildMiniStat(
                          icon: Icons.mood_rounded,
                          value: '${allMoods.length}',
                          label: 'Moods',
                          color: const Color(0xFFFFB703),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: colors.outline.withOpacity(0.2),
                        ),
                        _buildMiniStat(
                          icon: Icons.note_rounded,
                          value: '${allNotes.length}',
                          label: 'Notas',
                          color: const Color(0xFFFF6B6B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // RESUMO MENSAL
  // ==========================================
  Widget _buildMonthlyOverview(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, habitBox, _) {
        return ValueListenableBuilder(
          valueListenable:
              taskRepo.boxListenable ??
              ValueNotifier<Box>(
                habitRepo.box,
              ), // Fallback to avoid null error if repo not ready
          builder: (context, taskBox, _) {
            // Se taskBox for o fallback (habitBox), não tentamos ler tarefas dele
            final actualTaskBox = taskRepo.boxListenable != null
                ? taskBox
                : null;

            return FutureBuilder<Box<Book>>(
              future: Hive.openBox<Book>('books'),
              builder: (context, bookSnapshot) {
                final allHabits = habitRepo.getAllHabits();
                if (allHabits.isEmpty) return const SizedBox.shrink();

                final now = DateTime.now();
                final daysPassed = now.day;
                final monthName = DateFormat('MMMM', 'pt_BR').format(now);

                // --- 1. Monthly Stats (Habits) ---
                int totalCompletions = 0;
                int totalPossible = 0;

                for (int day = 1; day <= daysPassed; day++) {
                  final date = DateTime(now.year, now.month, day);
                  final dayHabits = habitRepo.getHabitsForDate(date);
                  totalPossible += dayHabits.length;
                  totalCompletions += dayHabits
                      .where((h) => h.isCompletedOn(date))
                      .length;
                }

                final monthRate = totalPossible > 0
                    ? totalCompletions / totalPossible
                    : 0.0;

                // --- 2. Best Day Analysis ---
                String bestDay = '—';
                double bestDayRate = -1;
                final dayNames = [
                  'Seg',
                  'Ter',
                  'Qua',
                  'Qui',
                  'Sex',
                  'Sáb',
                  'Dom',
                ];
                Map<int, List<double>> weekdayRates = {};

                for (int day = 1; day <= daysPassed; day++) {
                  final date = DateTime(now.year, now.month, day);
                  final weekday = date.weekday;
                  final dayHabits = habitRepo.getHabitsForDate(date);
                  if (dayHabits.isNotEmpty) {
                    final rate =
                        dayHabits.where((h) => h.isCompletedOn(date)).length /
                        dayHabits.length;
                    weekdayRates.putIfAbsent(weekday, () => []).add(rate);
                  }
                }

                weekdayRates.forEach((weekday, rates) {
                  final avg = rates.reduce((a, b) => a + b) / rates.length;
                  if (avg > bestDayRate) {
                    bestDayRate = avg;
                    bestDay = dayNames[weekday - 1];
                  }
                });

                // --- 3. Tasks Stats ---
                int tasksCompletedMonth = 0;
                if (actualTaskBox != null) {
                  for (final key in actualTaskBox.keys) {
                    final value = actualTaskBox.get(key);
                    if (value is Map) {
                      final task = TaskData.fromMap(
                        key,
                        Map<String, dynamic>.from(value),
                      );
                      if (task.completed &&
                          task.completedAt != null &&
                          task.completedAt!.year == now.year &&
                          task.completedAt!.month == now.month) {
                        tasksCompletedMonth++;
                      }
                    }
                  }
                }

                // --- 4. Books Stats ---
                int booksReadMonth = 0;
                if (bookSnapshot.hasData) {
                  final books = bookSnapshot.data!.values;
                  for (final book in books) {
                    if (book.status == BookStatus.read) {
                      // Check if finished this month
                      final finishedDate =
                          book.latestFinishDate ?? book.dateModified;
                      if (finishedDate.year == now.year &&
                          finishedDate.month == now.month) {
                        booksReadMonth++;
                      }
                    }
                  }
                }

                // --- 5. Impulse Phrase ---
                final phraseIndex =
                    (now.year * 12 + now.month) % _dailyInsights.length;
                final impulsePhrase = _dailyInsights[phraseIndex];

                // --- UI Construction ---
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer.withOpacity(0.4),
                        colors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: colors.outline.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.insights_rounded,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RESUMO DE ${monthName.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${(monthRate * 100).toInt()}% ',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSurface,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'de aproveitamento',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Decorative Circular Indicator
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: monthRate,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: colors.surfaceContainerHighest,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // KPI Grid
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildResultCard(
                                  context,
                                  label: 'Hábitos Feitos',
                                  value: totalCompletions.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildResultCard(
                                  context,
                                  label: 'Melhor Dia',
                                  value: bestDay,
                                  icon: Icons.emoji_events_outlined,
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildResultCard(
                                  context,
                                  label: 'Tarefas Concluídas',
                                  value: tasksCompletedMonth.toString(),
                                  icon: Icons.task_alt_rounded,
                                  color: const Color(0xFF29B6F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildResultCard(
                                  context,
                                  label: 'Livros Lidos',
                                  value: booksReadMonth.toString(),
                                  icon: Icons.menu_book_rounded,
                                  color: const Color(0xFFAB47BC),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Last 14 Days Visualization
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Últimos 14 Dias',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate dynamic width for bars
                          const spacing = 4.0;
                          const totalSpacing = spacing * 13;
                          final availableWidth =
                              constraints.maxWidth - totalSpacing;
                          final itemWidth = availableWidth / 14;

                          return SizedBox(
                            height: 50, // Height for the chart area
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(14, (index) {
                                final date = now.subtract(
                                  Duration(days: 13 - index),
                                );
                                final dayHabits = habitRepo.getHabitsForDate(
                                  date,
                                );
                                final completedCount = dayHabits
                                    .where((h) => h.isCompletedOn(date))
                                    .length;
                                final totalCount = dayHabits.length;
                                final rate = totalCount > 0
                                    ? completedCount / totalCount
                                    : 0.0;

                                final isToday = index == 13;
                                // Dynamic height based on rate, min height 15%
                                final heightFactor = rate == 0
                                    ? 0.15
                                    : (rate < 0.2 ? 0.2 : rate);

                                return Tooltip(
                                  message:
                                      '${DateFormat('dd/MM').format(date)}\n${(rate * 100).toInt()}% ($completedCount/$totalCount)',
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.inverseSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: TextStyle(
                                    color: colors.onInverseSurface,
                                    fontSize: 12,
                                  ),
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: itemWidth,
                                        height: 50 * heightFactor,
                                        decoration: BoxDecoration(
                                          color: _getColorForRate(
                                            rate,
                                            colors,
                                          ).withOpacity(isToday ? 1.0 : 0.8),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: isToday && rate > 0
                                              ? [
                                                  BoxShadow(
                                                    color: colors.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Impulse Phrase
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: colors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$impulsePhrase"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurface.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'FRASE DO MÊS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: colors.primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate, ColorScheme colors) {
    if (rate >= 1.0) return const Color(0xFF00C853);
    if (rate >= 0.7) return const Color(0xFF69F0AE);
    if (rate >= 0.4) return colors.primary;
    if (rate > 0) return colors.primary.withOpacity(0.5);
    return colors.surfaceContainerHighest;
  }

  Color _getColorForScore(double score) {
    if (score >= 4.5) return const Color(0xFF07E092);
    if (score >= 3.5) return const Color(0xFFB5E48C);
    if (score >= 2.5) return const Color(0xFFFFB703);
    if (score >= 1.5) return const Color(0xFFFF832B);
    return const Color(0xFFFF5E5E);
  }

  // ==========================================
  // WIDGET DE NOTÍCIAS
  // ==========================================
  Widget _buildNewsWidget(BuildContext context) {
    return _NewsCarouselWidget();
  }

  // ==========================================
  // FAB
  // ==========================================
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _showQuickActionsSheet(context);
      },
      backgroundColor: UltravioletColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UltravioletColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ações Rápidas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.mood_rounded,
                    label: 'Humor',
                    color: UltravioletColors.moodGood,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        useSafeArea: true,
                        isScrollControlled: true,
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.85,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (context, scrollController) =>
                              const AddMoodRecordForm(recordToEdit: null),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.event_repeat_rounded,
                    label: 'Hábito',
                    color: UltravioletColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddHabitDialog(context);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.timer_rounded,
                    label: 'Timer',
                    color: UltravioletColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).goToTimer();
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Calendário',
                    color: UltravioletColors.tertiary,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).goToLog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: UltravioletColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create quick task
  Future<void> _createQuickTask(TaskRepository taskRepo) async {
    final text = _quickTaskController.text.trim();
    if (text.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    final newTask = TaskData(
      key: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      notes: '',
      completed: false,
      priority: 'medium',
      category: 'Personal',
      dueDate: _selectedDate,
      dueTime: null,
      createdAt: DateTime.now(),
      completedAt: null,
    );

    await taskRepo.addTask(newTask);
    _quickTaskController.clear();

    // Mostrar feedback visual de sucesso
    if (mounted) {
      setState(() {}); // Força rebuild para atualizar lista
      FeedbackService.showSuccess(
        context,
        '✅ Tarefa criada!',
        icon: Icons.task_alt_rounded,
      );
    }
  }

  // ==========================================
  // PROFILE MENU - Menu de atalhos rápidos
  // ==========================================
  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final settings = ref.read(settingsProvider);
    final stats = ref.read(userStatsProvider);
    final title = UserTitles.getTitleForXP(stats.totalXP);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User Profile Card - Premium Look
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer.withValues(alpha: 0.7),
                            colors.secondaryContainer.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  ref
                                      .read(navigationProvider.notifier)
                                      .goToProfile();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        colors.primary,
                                        colors.secondary,
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundImage: settings.avatarPath != null
                                        ? FileImage(File(settings.avatarPath!))
                                        : null,
                                    backgroundColor: colors.surface,
                                    child: settings.avatarPath == null
                                        ? Text(
                                            settings.userName.isNotEmpty
                                                ? settings.userName[0]
                                                      .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.userName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${title.emoji} ${title.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Nível ${stats.level}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${stats.totalXP} XP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // XP Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progresso do Nível',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${(stats.levelProgress * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: stats.levelProgress,
                                  backgroundColor: colors.surface.withValues(
                                    alpha: 0.5,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colors.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Grid
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _quickActionCard(
                          ctx,
                          '📊',
                          'Estatísticas',
                          colors.primary,
                          () {
                            Navigator.pop(ctx);
                            ref
                                .read(navigationProvider.notifier)
                                .goToProfile(tabIndex: 0);
                          },
                          colors,
                        ),
                        _quickActionCard(
                          ctx,
                          '🎯',
                          'Metas',
                          colors.secondary,
                          () {
                            Navigator.pop(ctx);
                            ref
                                .read(navigationProvider.notifier)
                                .goToProfile(tabIndex: 4);
                          },
                          colors,
                        ),
                        _quickActionCard(
                          ctx,
                          '🏆',
                          'Conquistas',
                          colors.tertiary,
                          () {
                            Navigator.pop(ctx);
                            ref
                                .read(navigationProvider.notifier)
                                .goToProfile(tabIndex: 2);
                          },
                          colors,
                        ),
                        _quickActionCard(
                          ctx,
                          '📅',
                          'Calendário',
                          WellnessColors.primary,
                          () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HabitsCalendarScreen(),
                              ),
                            );
                          },
                          colors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Secondary Options
                    _menuItem(ctx, '⚙️', 'Configurações', () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    }, colors),
                    _menuItem(
                      ctx,
                      Theme.of(context).brightness == Brightness.dark
                          ? '🌙'
                          : '☀️',
                      'Mudar Tema',
                      () {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(
                              isDark ? ThemeMode.light : ThemeMode.dark,
                            );
                        HapticFeedback.mediumImpact();
                      },
                      colors,
                      trailing: Switch.adaptive(
                        value: Theme.of(context).brightness == Brightness.dark,
                        activeColor: colors.primary,
                        onChanged: (v) {
                          ref
                              .read(settingsProvider.notifier)
                              .setThemeMode(
                                v ? ThemeMode.dark : ThemeMode.light,
                              );
                          HapticFeedback.mediumImpact();
                        },
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

  // ==========================================
  // MENU LATERAL MODERNO - Flutuante com efeito 3D
  // ==========================================
  void _showModernSideMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settings = ref.read(settingsProvider);
    final stats = ref.read(userStatsProvider);
    final title = UserTitles.getTitleForXP(stats.totalXP);
    final screenWidth = MediaQuery.of(context).size.width;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        // Efeito 3D leve - rotação
        final rotateAnimation = Tween<double>(begin: 0.05, end: 0.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return Stack(
          children: [
            // Menu flutuante
            SlideTransition(
              position: slideAnimation,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotateAnimation.value),
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: screenWidth * 0.78,
                      height: double.infinity,
                      margin: const EdgeInsets.only(
                        left: 12,
                        top: 50,
                        bottom: 50,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: colors.outline.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header do Menu
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          ref
                                              .read(navigationProvider.notifier)
                                              .goToProfile();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                colors.primary,
                                                colors.tertiary,
                                              ],
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: colors.surface,
                                            backgroundImage:
                                                settings.avatarPath != null
                                                ? FileImage(
                                                    File(settings.avatarPath!),
                                                  )
                                                : null,
                                            child: settings.avatarPath == null
                                                ? Text(
                                                    settings.userName.isNotEmpty
                                                        ? settings.userName[0]
                                                              .toUpperCase()
                                                        : 'O',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: colors.primary,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              settings.userName.isNotEmpty
                                                  ? settings.userName
                                                  : 'Viajante',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colors.primary.withOpacity(
                                                      0.15,
                                                    ),
                                                    colors.tertiary.withOpacity(
                                                      0.15,
                                                    ),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${title.emoji} ${title.name}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // XP Badge
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colors.primaryContainer.withOpacity(
                                            0.5,
                                          ),
                                          colors.secondaryContainer.withOpacity(
                                            0.3,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nível ${stats.level}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            Text(
                                              '${stats.totalXP} XP',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${(stats.levelProgress * 100).round()}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Menu Items
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _menuSectionTitle('Navegação', colors),
                                        _modernMenuItem(
                                          context,
                                          Icons.home_rounded,
                                          'Início',
                                          colors.primary,
                                          () {
                                            Navigator.pop(context);
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.person_rounded,
                                          'Meu Perfil',
                                          colors.secondary,
                                          () {
                                            Navigator.pop(context);
                                            ref
                                                .read(
                                                  navigationProvider.notifier,
                                                )
                                                .goToProfile();
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.calendar_month_rounded,
                                          'Calendário',
                                          WellnessColors.primary,
                                          () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const HabitsCalendarScreen(),
                                              ),
                                            );
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.library_books_rounded,
                                          'Biblioteca',
                                          Colors.teal,
                                          () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const LibraryScreen(),
                                              ),
                                            );
                                          },
                                          colors,
                                        ),

                                        const SizedBox(height: 12),
                                        _menuSectionTitle('Progresso', colors),
                                        _modernMenuItem(
                                          context,
                                          Icons.insights_rounded,
                                          'Estatísticas',
                                          Colors.orange,
                                          () {
                                            Navigator.pop(context);
                                            ref
                                                .read(
                                                  navigationProvider.notifier,
                                                )
                                                .goToProfile(tabIndex: 0);
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.emoji_events_rounded,
                                          'Conquistas',
                                          Colors.amber,
                                          () {
                                            Navigator.pop(context);
                                            ref
                                                .read(
                                                  navigationProvider.notifier,
                                                )
                                                .goToProfile(tabIndex: 2);
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.flag_rounded,
                                          'Metas',
                                          Colors.green,
                                          () {
                                            Navigator.pop(context);
                                            ref
                                                .read(
                                                  navigationProvider.notifier,
                                                )
                                                .goToProfile(tabIndex: 4);
                                          },
                                          colors,
                                        ),

                                        const SizedBox(height: 12),
                                        _menuSectionTitle(
                                          'Configurações',
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.settings_rounded,
                                          'Preferências',
                                          colors.onSurfaceVariant,
                                          () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SettingsScreen(),
                                              ),
                                            );
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Icons.light_mode_rounded
                                              : Icons.dark_mode_rounded,
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? 'Modo Claro'
                                              : 'Modo Escuro',
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.amber
                                              : Colors.indigo,
                                          () {
                                            final isDark =
                                                Theme.of(context).brightness ==
                                                Brightness.dark;
                                            ref
                                                .read(settingsProvider.notifier)
                                                .setThemeMode(
                                                  isDark
                                                      ? ThemeMode.light
                                                      : ThemeMode.dark,
                                                );
                                            HapticFeedback.mediumImpact();
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.notifications_rounded,
                                          'Notificações',
                                          Colors.red.shade400,
                                          () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ModernNotificationSettingsScreen(),
                                              ),
                                            );
                                          },
                                          colors,
                                        ),
                                        _modernMenuItem(
                                          context,
                                          Icons.favorite_rounded,
                                          'Apoiar Odyssey',
                                          Colors.pink,
                                          () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const DonationScreen(),
                                              ),
                                            );
                                          },
                                          colors,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Odyssey v1.0.0',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _menuSectionTitle(String title, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.onSurfaceVariant.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _modernMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    String emoji,
    String title,
    Color color,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    String emoji,
    String title,
    VoidCallback onTap,
    ColorScheme colors, {
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ==========================================
  // SMART ADD - Adicionar Inteligente
  // ==========================================
  void _showSmartAddSheet(BuildContext context) {
    SmartQuickAddSheet.show(
      context,
      onAdd: (text, type) async {
        if (type == ItemType.habit) {
          // Criar hábito com valores padrão
          final habit = Habit(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: text,
            iconCode: Icons.star.codePoint,
            colorValue: UltravioletColors.primary.value,
            createdAt: DateTime.now(),
          );
          final repo = ref.read(habitRepositoryProvider);
          await repo.addHabit(habit);
          if (mounted) {
            refresh();
            FeedbackService.showSuccessWithXP(
              context,
              'Hábito "$text" criado!',
              5,
            );
          }
        } else {
          // Criar tarefa
          final tasksBox = await Hive.openBox('tasks');
          final taskId = DateTime.now().millisecondsSinceEpoch.toString();
          await tasksBox.put(taskId, {
            'title': text,
            'completed': false,
            'priority': 'medium',
            'createdAt': DateTime.now().toIso8601String(),
          });
          if (mounted) {
            FeedbackService.showSuccessWithXP(
              context,
              'Tarefa "$text" criada!',
              5,
            );
          }
        }
      },
    );
  }

  // ==========================================
  // DIALOGS - CRIAR HÁBITO (com TimePicker)
  // ==========================================
  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    TimeOfDay? selectedTime;
    int selectedIconCode = Icons.star.codePoint;
    Color selectedColor = UltravioletColors.primary;
    List<int> selectedDays = [];

    final icons = [
      Icons.directions_walk,
      Icons.directions_bike,
      Icons.access_time,
      Icons.book,
      Icons.edit,
      Icons.palette,
      Icons.groups,
      Icons.check_circle,
      Icons.emoji_emotions,
      Icons.fitness_center,
      Icons.local_cafe,
      Icons.shopping_cart,
      Icons.star,
      Icons.attach_money,
      Icons.music_note,
      Icons.build,
      Icons.beach_access,
      Icons.train,
      Icons.school,
      Icons.water_drop,
      Icons.self_improvement,
    ];

    final colors = [
      UltravioletColors.primary,
      const Color(0xFFFF6B6B),
      const Color(0xFF07E092),
      const Color(0xFF00B4D8),
      const Color(0xFFFFA556),
      const Color(0xFF9B51E0),
    ];

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Novo Hábito',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: UltravioletColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 24),

                // Nome
                const Text(
                  'Nome',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: Ler um livro',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Horário com TimePicker
                const Text(
                  'Horário (opcional)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: UltravioletColors.primary,
                              surface: UltravioletColors.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setModalState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: UltravioletColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white54),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Selecionar horário',
                          style: TextStyle(
                            color: selectedTime != null
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                        const Spacer(),
                        if (selectedTime != null)
                          GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedTime = null),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dias da semana
                const Text(
                  'Repetir em',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDayChip(
                      'Seg',
                      1,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Ter',
                      2,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Qua',
                      3,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Qui',
                      4,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Sex',
                      5,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Sáb',
                      6,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                    _buildDayChip(
                      'Dom',
                      7,
                      selectedDays,
                      (d) => setModalState(() {
                        if (selectedDays.contains(d)) {
                          selectedDays.remove(d);
                        } else {
                          selectedDays.add(d);
                        }
                      }),
                    ),
                  ],
                ),
                if (selectedDays.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Todos os dias',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ),
                const SizedBox(height: 20),

                // Ícones (grid maior igual HabitMate)
                const Text(
                  'Ícone',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: icons.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return GestureDetector(
                      onTap: () => setModalState(
                        () => selectedIconCode = icon.codePoint,
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.3)
                              : UltravioletColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? selectedColor : Colors.white54,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Cores
                const Text(
                  'Cor',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
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
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Botão Salvar (estilo HabitMate)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;

                      final repo = ref.read(habitRepositoryProvider);
                      String? timeStr;
                      if (selectedTime != null) {
                        timeStr =
                            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                      }

                      final newHabit = Habit(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        iconCode: selectedIconCode,
                        colorValue: selectedColor.value,
                        scheduledTime: timeStr,
                        daysOfWeek: selectedDays,
                        completedDates: [],
                        currentStreak: 0,
                        bestStreak: 0,
                        createdAt: DateTime.now(),
                        order: repo.getAllHabits().length,
                      );

                      await repo.addHabit(newHabit);
                      Navigator.pop(context);
                      FeedbackService.showSuccess(context, '✨ Hábito criado!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UltravioletColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(
    String label,
    int day,
    List<int> selectedDays,
    Function(int) onTap,
  ) {
    final isSelected = selectedDays.contains(day);
    return GestureDetector(
      onTap: () => onTap(day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? UltravioletColors.primary
              : UltravioletColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG - EDITAR HÁBITO
  // ==========================================
  void _showEditHabitFormDialog(BuildContext context, Habit habit) {
    final nameController = TextEditingController(text: habit.name);
    TimeOfDay? selectedTime;
    if (habit.scheduledTime != null && habit.scheduledTime!.contains(':')) {
      final parts = habit.scheduledTime!.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    int selectedIconCode = habit.iconCode;
    Color selectedColor = Color(habit.colorValue);
    List<int> selectedDays = List.from(habit.daysOfWeek);

    final icons = [
      Icons.directions_walk,
      Icons.directions_bike,
      Icons.access_time,
      Icons.book,
      Icons.edit,
      Icons.palette,
      Icons.groups,
      Icons.check_circle,
      Icons.emoji_emotions,
      Icons.fitness_center,
      Icons.local_cafe,
      Icons.shopping_cart,
      Icons.star,
      Icons.attach_money,
      Icons.music_note,
      Icons.build,
      Icons.beach_access,
      Icons.train,
      Icons.school,
      Icons.water_drop,
      Icons.self_improvement,
    ];

    final colors = [
      UltravioletColors.primary,
      const Color(0xFFFF6B6B),
      const Color(0xFF07E092),
      const Color(0xFF00B4D8),
      const Color(0xFFFFA556),
      const Color(0xFF9B51E0),
    ];

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Editar hábito',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: UltravioletColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 24),

                // Nome
                const Text(
                  'Nome',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Horário com TimePicker
                const Text(
                  'Horário (opcional)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: UltravioletColors.primary,
                              surface: UltravioletColors.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setModalState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: UltravioletColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white54),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Selecionar horário',
                          style: TextStyle(
                            color: selectedTime != null
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                        const Spacer(),
                        if (selectedTime != null)
                          GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedTime = null),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Ícones
                const Text(
                  'Ícone',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: icons.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return GestureDetector(
                      onTap: () => setModalState(
                        () => selectedIconCode = icon.codePoint,
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.3)
                              : UltravioletColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? selectedColor : Colors.white54,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Cores
                const Text(
                  'Cor',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
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
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;

                      final repo = ref.read(habitRepositoryProvider);
                      String? timeStr;
                      if (selectedTime != null) {
                        timeStr =
                            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                      }

                      final updatedHabit = habit.copyWith(
                        name: nameController.text,
                        iconCode: selectedIconCode,
                        colorValue: selectedColor.value,
                        scheduledTime: timeStr,
                        daysOfWeek: selectedDays,
                      );

                      await repo.updateHabit(updatedHabit);
                      Navigator.pop(context);
                      FeedbackService.showSuccess(
                        context,
                        '✅ Hábito atualizado!',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UltravioletColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Remover hábito
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final repo = ref.read(habitRepositoryProvider);
                      await repo.deleteHabit(habit.id);
                      Navigator.pop(context);
                      FeedbackService.showSuccess(context, 'Hábito removido');
                    },
                    child: const Text(
                      'Remover hábito',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET DE NOTAS E LEITURAS (PILLS UNIFICADA)
  // ==========================================
  Widget _buildNotesAndReadingsSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildNotesPill(context)),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 32,
            color: colors.outlineVariant.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildReadingsPill(context)),
        ],
      ),
    );
  }

  Widget _buildNotesPill(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.openBox('notes'),
      builder: (context, snapshot) {
        int noteCount = 0;
        if (snapshot.hasData) {
          noteCount = snapshot.data!.length;
        }

        return _buildPillItem(
          context,
          label: 'Notas',
          count: noteCount.toString(),
          icon: Icons.sticky_note_2_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildReadingsPill(BuildContext context) {
    return FutureBuilder<Box<Book>>(
      future: _openBooksBox(),
      builder: (context, snapshot) {
        int readingCount = 0;
        if (snapshot.hasData) {
          final box = snapshot.data!;
          readingCount = box.values
              .where((b) => b.status == BookStatus.inProgress)
              .length;
        }

        return _buildPillItem(
          context,
          label: 'Lendo',
          count: readingCount.toString(),
          icon: Icons.menu_book_rounded,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildPillItem(
    BuildContext context, {
    required String label,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Box<Book>> _openBooksBox() async {
    if (!Hive.isAdapterRegistered(BookAdapter().typeId)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(ReadingPeriodAdapter().typeId)) {
      Hive.registerAdapter(ReadingPeriodAdapter());
    }
    if (Hive.isBoxOpen('books_v3')) {
      return Hive.box<Book>('books_v3');
    }
    return await Hive.openBox<Book>('books_v3');
  }
}

// Extension para capitalizar primeira letra
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// ==========================================
// WIDGET CARROSSEL DE NOTÍCIAS
// ==========================================
class _NewsCarouselWidget extends StatefulWidget {
  @override
  State<_NewsCarouselWidget> createState() => _NewsCarouselWidgetState();
}

class _NewsCarouselWidgetState extends State<_NewsCarouselWidget> {
  List<Map<String, String>> _news = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  final Map<int, String> _images = {};
  final Set<int> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      final articles = await _fetchNewsFromRSS();
      if (mounted) {
        setState(() {
          _news = articles;
          _isLoading = false;
        });
        _startAutoSlide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // kick off image loads
    if (_news.isNotEmpty) {
      for (int i = 0; i < _news.length && i < 6; i++) {
        _loadImageForIndex(i);
      }
    }
  }

  String? getCarouselImage(int index) {
    if (_images.containsKey(index)) return _images[index];
    return null;
  }

  Future<void> _loadImageForIndex(int index) async {
    if (_images.containsKey(index)) return;
    if (_loadingImages.contains(index)) return;
    _loadingImages.add(index);
    try {
      if (index >= _news.length) return;
      final article = _news[index];
      final url = (article['url'] ?? '').toString();

      if (url.isEmpty) return;

      final fastImage = await fetchImageForUrl(url);
      if (fastImage != null && fastImage.isNotEmpty) {
        _images[index] = fastImage;
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      debugPrint('[NewsCarousel] image fetch failed for index $index: $e');
    } finally {
      _loadingImages.remove(index);
      if (mounted) setState(() {});
    }
  }

  Future<List<Map<String, String>>> _fetchNewsFromRSS() async {
    try {
      // Google News RSS via RSS2JSON
      final apiUrl = Uri.parse(
        'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent('https://news.google.com/rss?hl=pt-BR&gl=BR&ceid=BR:pt-419')}',
      );

      final response = await http
          .get(apiUrl)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['items'] != null) {
          return (data['items'] as List)
              .take(6)
              .map(
                (item) => {
                  'title': _stripHtml(item['title'] ?? ''),
                  'source': (item['author'] ?? 'Google News') as String,
                  'url': (item['link'] ?? '') as String,
                },
              )
              .where((n) => n['title']!.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('RSS fetch error: $e');
    }

    // Fallback: Wikipedia
    try {
      final now = DateTime.now();
      final url = Uri.parse(
        'https://pt.wikipedia.org/api/rest_v1/feed/featured/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
      );

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = <Map<String, String>>[];

        if (data['mostread'] != null && data['mostread']['articles'] != null) {
          for (var article in (data['mostread']['articles'] as List).take(6)) {
            if (article['title'] != null &&
                !article['title'].toString().contains(':')) {
              articles.add({
                'title':
                    article['titles']?['normalized'] ?? article['title'] ?? '',
                'source': 'Wikipedia',
                'url': 'https://pt.wikipedia.org/wiki/${article['title']}',
              });
            }
          }
        }

        return articles;
      }
    } catch (e) {
      debugPrint('Wikipedia fetch error: $e');
    }

    return [];
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_news.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _news.length;
          });
        }
      });
    }
  }

  void _nextNews() {
    if (_news.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _news.length;
      });
      _startAutoSlide();
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    try {
      var cleaned = url.trim();
      if (cleaned.isEmpty) return;
      if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
        cleaned = 'https://$cleaned';
      }
      final uri = Uri.parse(Uri.encodeFull(cleaned));
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: const Color(0xFFFF6B6B).withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notícias',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_news.isNotEmpty)
                      Text(
                        '${_currentIndex + 1}/${_news.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Botão próxima
              if (_news.isNotEmpty)
                GestureDetector(
                  onTap: _nextNews,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.skip_next_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 18,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Botão ver mais
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ver mais',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Conteúdo
          if (_isLoading)
            const SizedBox(
              height: 50,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_news.isEmpty)
            GestureDetector(
              onTap: _loadNews,
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Toque para carregar notícias',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                final news = _news[_currentIndex];
                if (news['url']?.isNotEmpty == true) {
                  _openUrl(news['url']!);
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    _nextNews();
                  } else if (details.primaryVelocity! > 0 &&
                      _currentIndex > 0) {
                    setState(() => _currentIndex--);
                    _startAutoSlide();
                  }
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  key: ValueKey(_currentIndex),
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading image
                      Container(
                        width: 64,
                        height: 64,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: getCarouselImage(_currentIndex) != null
                            ? Image.network(
                                getCarouselImage(_currentIndex)!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white24,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.public,
                                  color: Colors.white24,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _news[_currentIndex]['title'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _news[_currentIndex]['source'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: Color(0xFFFF6B6B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Indicadores
          if (_news.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_news.length.clamp(0, 6), (index) {
                final isActive = index == _currentIndex;
                return Container(
                  width: isActive ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 🌆 CYBERPUNK HEADER - MINIMALISTA
// ==========================================
class _WellnessHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onAddTap;
  final String? avatarPath;
  final String userName;

  const _WellnessHeader({
    required this.onMenuTap,
    required this.onCalendarTap,
    required this.onAddTap,
    this.avatarPath,
    this.userName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _timeOfDay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Olá, ${userName.isNotEmpty ? userName : "Viajante"}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildIconButton(
              context,
              icon: Icons.calendar_today_rounded,
              onTap: onCalendarTap,
            ),
            const SizedBox(width: 12),
            _buildIconButton(
              context,
              icon: Icons.add_rounded,
              onTap: onAddTap,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  String get _timeOfDay {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildAvatar(BuildContext context) {
    final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty;
    return GestureDetector(
      onTap: onMenuTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: WellnessColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: WellnessColors.primary.withOpacity(0.1),
          backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
          child: !hasAvatar
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: WellnessColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    if (isPrimary) {
      // Botão primário (+) com gradiente vibrante
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.tertiary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
    }

    // Botões secundários
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Icon(icon, color: colors.onSurfaceVariant, size: 22),
      ),
    );
  }
}

// ==========================================
// CARD DE VISÃO GERAL DO DIA
// ==========================================
class _DayOverviewCard extends ConsumerWidget {
  const _DayOverviewCard({
    required this.habitRepoInitialized,
    required this.taskRepoInitialized,
  });

  final bool habitRepoInitialized;
  final bool taskRepoInitialized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final timerState = ref.watch(timerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.2),
                      colors.tertiary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão Geral',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM', 'pt_BR').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (timerState.isRunning)
                _ActiveTimerIndicator(timerState: timerState),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de Overview Items
          if (!habitRepoInitialized || !taskRepoInitialized)
            _buildLoadingGrid(colors)
          else
            _buildOverviewGrid(context, ref, colors, timerState),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(ColorScheme colors) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: List.generate(
        6,
        (index) => _OverviewItemPlaceholder(colors: colors),
      ),
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
    TimerState timerState,
  ) {
    final taskRepo = ref.watch(taskRepositoryProvider);
    final notesRepo = ref.watch(notesRepositoryProvider);
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final timeTrackingRepo = ref.watch(timeTrackingRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        taskRepo.getPendingTasksForToday(),
        Future.value(notesRepo.getAllNotes()),
        Future.value(moodRepo.fetchMoodRecords()),
        Future.value(
          timeTrackingRepo.fetchTimeTrackingRecordsByDate(DateTime.now()),
        ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingGrid(colors);
        }

        final tasks = snapshot.data![0] as List<TaskData>;
        final notes = snapshot.data![1] as List<Map<String, dynamic>>;
        final moods = snapshot.data![2] as Map<dynamic, MoodRecord>;
        final timeRecords = snapshot.data![3] as List<TimeTrackingRecord>;

        // Filtrar ideias (notas marcadas como ideia ou sem categoria específica)
        final ideas = notes
            .where(
              (n) =>
                  (n['category'] as String?)?.toLowerCase() == 'ideia' ||
                  (n['category'] as String?)?.toLowerCase() == 'idea' ||
                  (n['tags'] as List?)?.any(
                        (t) => t.toString().toLowerCase().contains('ideia'),
                      ) ==
                      true,
            )
            .toList();

        // Pegar humor mais recente de hoje
        final todayMoods = moods.entries.where((e) {
          final moodDate = e.value.date;
          final now = DateTime.now();
          return moodDate.year == now.year &&
              moodDate.month == now.month &&
              moodDate.day == now.day;
        }).toList();
        todayMoods.sort((a, b) => b.value.date.compareTo(a.value.date));
        final latestMood = todayMoods.isNotEmpty
            ? todayMoods.first.value
            : null;

        // Contar sessões Pomodoro de hoje
        final pomodoroSessions = timerState.pomodoroSessions;

        // Tarefas de alta prioridade
        final highPriorityTasks = tasks
            .where((t) => t.priority == 'high')
            .length;

        return Column(
          children: [
            // Primeira linha - 3 cards
            Row(
              children: [
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Tarefas',
                    value: '${tasks.length}',
                    subtitle: highPriorityTasks > 0
                        ? '$highPriorityTasks urgentes'
                        : 'pendentes',
                    color: tasks.isEmpty
                        ? colors.primary
                        : (highPriorityTasks > 0
                              ? colors.error
                              : colors.tertiary),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TasksScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Ideias',
                    value: '${ideas.length}',
                    subtitle: notes.length > ideas.length
                        ? '+${notes.length - ideas.length} notas'
                        : 'capturadas',
                    color: Colors.amber,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OverviewItem(
                    icon: _getMoodIcon(latestMood),
                    label: 'Humor',
                    value: latestMood != null ? _getMoodLabel(latestMood) : '—',
                    subtitle: latestMood != null
                        ? DateFormat('HH:mm').format(latestMood.date)
                        : 'registrar',
                    color: latestMood != null
                        ? _getMoodColor(latestMood)
                        : colors.onSurfaceVariant.withOpacity(0.5),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddMoodRecordForm(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Segunda linha - 2 cards (Timer + Pomodoro)
            Row(
              children: [
                Expanded(
                  child: _OverviewItem(
                    icon: timerState.isRunning
                        ? Icons.timer_rounded
                        : Icons.timer_outlined,
                    label: 'Timer',
                    value: timerState.isRunning
                        ? _formatDuration(timerState.elapsed)
                        : '${timeRecords.length}h',
                    subtitle: timerState.isRunning
                        ? (timerState.taskName ?? 'Em andamento')
                        : 'registradas',
                    color: timerState.isRunning
                        ? WellnessColors.success
                        : colors.primary,
                    isActive: timerState.isRunning,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(navigationProvider.notifier).goToTimer();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Pomodoro',
                    value: '$pomodoroSessions',
                    subtitle: pomodoroSessions == 1 ? 'sessão' : 'sessões',
                    color: pomodoroSessions > 0
                        ? Colors.deepOrange
                        : colors.onSurfaceVariant.withOpacity(0.5),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(timerProvider.notifier)
                          .updatePomodoroSettings(openPomodoroScreen: true);
                      ref.read(navigationProvider.notifier).goToTimer();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getMoodIcon(MoodRecord? mood) {
    if (mood == null) return Icons.sentiment_neutral_rounded;

    switch (mood.score) {
      case 1:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 4:
        return Icons.sentiment_satisfied_rounded;
      case 5:
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  String _getMoodLabel(MoodRecord mood) {
    switch (mood.score) {
      case 1:
        return 'Péssimo';
      case 2:
        return 'Mal';
      case 3:
        return 'Ok';
      case 4:
        return 'Bem';
      case 5:
        return 'Ótimo';
      default:
        return 'Ok';
    }
  }

  Color _getMoodColor(MoodRecord mood) {
    switch (mood.score) {
      case 1:
        return WellnessColors.error;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return WellnessColors.primary;
      case 5:
        return WellnessColors.success;
      default:
        return Colors.amber;
    }
  }
}

// Widget para indicar timer ativo no header
class _ActiveTimerIndicator extends StatefulWidget {
  const _ActiveTimerIndicator({required this.timerState});

  final TimerState timerState;

  @override
  State<_ActiveTimerIndicator> createState() => _ActiveTimerIndicatorState();
}

class _ActiveTimerIndicatorState extends State<_ActiveTimerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: WellnessColors.success.withOpacity(0.15 * _animation.value),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WellnessColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: WellnessColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ativo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WellnessColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Item individual do overview
class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: color.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),

                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder para loading
class _OverviewItemPlaceholder extends StatelessWidget {
  const _OverviewItemPlaceholder({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

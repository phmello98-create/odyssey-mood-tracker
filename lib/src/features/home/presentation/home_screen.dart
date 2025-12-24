import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_daily_quote.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_weekly_chart.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_day_overview.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_stats_section.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';

import 'package:odyssey/src/features/notes/data/notes_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';

import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/animations/animations.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';

import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/tasks/data/synced_task_repository.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/utils/smart_classifier.dart';
import 'package:odyssey/src/utils/widgets/smart_quick_add.dart';
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
import 'package:odyssey/src/features/home/presentation/widgets/home_quick_stats_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_news_carousel_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_notes_readings_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_habits_compact_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/task_checkbox.dart';
import 'package:odyssey/src/features/home/presentation/widgets/header_arrow_button.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_suggestions_widget.dart'
    hide AnimatedBuilder;
import 'package:odyssey/src/features/home/presentation/widgets/global_search_bar.dart';
import 'package:odyssey/src/features/home/presentation/widgets/home_community_section.dart';
import 'package:odyssey/src/features/community/presentation/screens/create_post_screen.dart';
import 'package:odyssey/src/features/community/domain/post.dart';
import 'package:odyssey/src/features/community/domain/topic.dart';

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

  Timer? _insightTimer;

  // Tabs de Hábitos/Tarefas
  int _habitsTasksTabIndex = 0;

  // Calendário expandido (semana/mês)
  bool _isCalendarExpanded = false;

  // New variables for chart interactivity

  // Show/Hide completed items
  bool _showCompletedHabits = false;
  bool _showCompletedTasks = false;

  // Quick task creation controller
  final TextEditingController _quickTaskController = TextEditingController();

  // Floating header scroll detection
  final ScrollController _scrollController = ScrollController();
  final bool _showFloatingHeader = false;
  Timer? _floatingHeaderTimer;
  final bool _isScrolling = false;

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
  }

  void _onScroll() {
    // Scroll listener kept for potential future use or analytics
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
    setState(() => _currentInsight = newInsight);
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    // Performance: watch apenas as propriedades necessárias
    final userName = ref.watch(settingsProvider.select((s) => s.userName));
    final avatarPath = ref.watch(settingsProvider.select((s) => s.avatarPath));
    final colors = Theme.of(context).colorScheme;

    return _buildMainContent(monthFormat, userName, avatarPath, colors);
  }

  // ==========================================
  // MAIN CONTENT - Conteúdo Principal
  // ==========================================
  Widget _buildMainContent(
    DateFormat monthFormat,
    String userName,
    String? avatarPath,
    ColorScheme colors,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
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
                  // ==========================================
                  // HEADER MINIMALISTA
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
                      child: Row(
                        children: [
                          // Spacer to avoid overlap with the drawer toggle button on the left
                          const SizedBox(width: 48),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${_getGreeting()},',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HabitsCalendarScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_month_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showSmartAddSheet(context),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                          ),
                        ],
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
                  // SEÇÃO COMBINADA HÁBITOS/TAREFAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildHabitsTasksSection(context),
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
                      child: HomeDailyQuote(quote: _currentInsight),
                    ),
                  ),

                  // ==========================================
                  // REGISTRO DE HUMOR
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildMoodSection(context, avatarPath),
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
                      child: const HomeCommunitySection(),
                    ),
                  ),

                  // ==========================================
                  // ESTATÍSTICAS RÁPIDAS
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _habitRepoInitialized
                          ? HomeQuickStatsWidget(selectedDate: _selectedDate)
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // ==========================================
                  // GRÁFICO SEMANAL
                  // ==========================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: HomeStatsSection(
                        habitRepoInitialized: _habitRepoInitialized,
                      ),
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
                      child: const HomeNotesReadingsWidget(),
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
              child: _buildFloatingHeader(userName, avatarPath, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(
    String userName,
    String? avatarPath,
    ColorScheme colors,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () {},
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
                    backgroundImage: avatarPath != null
                        ? FileImage(File(avatarPath))
                        : null,
                    child: avatarPath == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
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
                  userName.isNotEmpty ? userName : 'Viajante',
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
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
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

  // NOTE: Community section foi extraído para HomeCommunitySection widget
  // em lib/src/features/home/presentation/widgets/home_community_section.dart

  // NOTE: _formatTimeAgo() também foi movido para HomeCommunitySection

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
        return HomeDailyQuote(quote: _currentInsight);
      case HomeWidgetType.weeklyChart:
        return const HomeWeeklyChart();
      case HomeWidgetType.currentReading:
        return const CurrentReadingWidget();
      case HomeWidgetType.dailyGoals:
        return const DailyGoalsWidget();
      case HomeWidgetType.habits:
        return const HomeHabitsCompactWidget();
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
  // NOTE: _buildHabitsWidgetCompact foi extraído para HomeHabitsCompactWidget
  // em lib/src/features/home/presentation/widgets/home_habits_compact_widget.dart

  // ==========================================
  // MOOD SECTION COMPACTO
  // ==========================================
  Widget _buildWellnessActivityCard() {
    return HomeDayOverview(
      habitRepoInitialized: _habitRepoInitialized,
      taskRepoInitialized: _taskRepoInitialized,
      onTapTasks: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TasksScreen()),
      ),
      onTapNotes: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotesScreen()),
      ),
      onTapMood: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddMoodRecordForm(),
      ),
      onTapTimer: () => ref.read(navigationProvider.notifier).goToTimer(),
    );
  }

  Widget _buildMoodSection(BuildContext context, String? avatarPath) {
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
                backgroundImage: avatarPath != null
                    ? FileImage(File(avatarPath))
                    : null,
                child: avatarPath == null
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
                    color: colors.primary.withValues(alpha: 0.1),
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
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.primary,
                                      colors.primary.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            moodEmoji != null
                                ? 'Compartilhando $moodEmoji'
                                : 'Indo para a comunidade',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sua experiência inspira outros! ✨',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Loading indicator
                        SizedBox(
                          width: 22,
                          height: 22,
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
                color: color.withValues(alpha: 0.12),
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
                              : colors.onSurfaceVariant.withValues(alpha: 0.6),
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
                  : colors.onSurface.withValues(alpha: 0.05),
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
                          color: colors.primary.withValues(alpha: 0.1),
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
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
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
                    : colors.surfaceContainerHighest.withValues(alpha: 0.4),
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
                        : colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hábitos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _habitsTasksTabIndex == 0
                          ? Colors.white
                          : colors.onSurfaceVariant.withValues(alpha: 0.6),
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
                    : colors.surfaceContainerHighest.withValues(alpha: 0.4),
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
                        : colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tarefas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _habitsTasksTabIndex == 1
                          ? Colors.white
                          : colors.onSurfaceVariant.withValues(alpha: 0.6),
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
            colors.primary.withValues(alpha: 0.08),
            colors.primaryContainer.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(
              Icons.add_task_rounded,
              color: colors.primary.withValues(alpha: 0.6),
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
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
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
                    color: colors.primary.withValues(alpha: 0.15),
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
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 48,
            color: UltravioletColors.accentGreen.withValues(alpha: 0.6),
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
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
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
                        ? UltravioletColors.accentGreen.withValues(alpha: 0.15)
                        : colors.primary.withValues(alpha: 0.15),
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
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
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
              ? UltravioletColors.accentGreen.withValues(alpha: 0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? UltravioletColors.accentGreen.withValues(alpha: 0.2)
                : colors.outline.withValues(alpha: 0.1),
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
                                ? colors.onSurfaceVariant.withValues(alpha: 0.7)
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
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: priorityColor.withValues(alpha: 0.2),
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
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
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
            ? color.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? color.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
                          color: isCompleted
                              ? color
                              : color.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? color
                                : color.withValues(alpha: 0.5),
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
                                    color: Colors.orange.withValues(alpha: 0.2),
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
                              .withValues(alpha: 0.3),
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
                          shadowColor: color.withValues(alpha: 0.4),
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
                  color: UltravioletColors.outline.withValues(alpha: 0.1),
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
      textColor = colorScheme.onSurface.withValues(alpha: 0.3);
    }

    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withValues(alpha: 0.15) // Soft tint for completed
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
        color: UltravioletColors.surfaceVariant.withValues(alpha: 0.2),
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
                color: UltravioletColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: UltravioletColors.primary.withValues(alpha: 0.5),
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
  // NOTE: _buildQuickStats e _buildStatPill foram extraídos para HomeQuickStatsWidget
  // em lib/src/features/home/presentation/widgets/home_quick_stats_widget.dart

  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================

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
                    colors.primaryContainer.withValues(alpha: 0.3),
                    colors.secondaryContainer.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
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
                              colors.primary.withValues(alpha: 0.15),
                              colors.tertiary.withValues(alpha: 0.1),
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
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.8,
                                ),
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
                                color: colors.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.outline.withValues(alpha: 0.1),
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
                                                  .withValues(alpha: 0.2),
                                              (insight['gradient']
                                                      as List<Color>)
                                                  .last
                                                  .withValues(alpha: 0.1),
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
                                                    .withValues(alpha: 0.3),
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
                                              .withValues(alpha: 0.5),
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
                      color: colors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.1),
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
                          color: colors.outline.withValues(alpha: 0.2),
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
                          color: colors.outline.withValues(alpha: 0.2),
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
                          color: colors.outline.withValues(alpha: 0.2),
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
                        colors.primaryContainer.withValues(alpha: 0.4),
                        colors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.08),
                    ),
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
                                          color: _getColorForRate(rate, colors)
                                              .withValues(
                                                alpha: isToday ? 1.0 : 0.8,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: isToday && rate > 0
                                              ? [
                                                  BoxShadow(
                                                    color: colors.primary
                                                        .withValues(alpha: 0.4),
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
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.1),
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
                                color: colors.onSurface.withValues(alpha: 0.8),
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
                                color: colors.primary.withValues(alpha: 0.7),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
    if (rate > 0) return colors.primary.withValues(alpha: 0.5);
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
    return const HomeNewsCarouselWidget();
  }

  // ==========================================
  // FAB
  // ==========================================

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
      refresh(); // Força rebuild para atualizar lista
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
            colorValue: UltravioletColors.primary.toARGB32(),
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
                              ? selectedColor.withValues(alpha: 0.3)
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
                                    color: color.withValues(alpha: 0.5),
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
                        colorValue: selectedColor.toARGB32(),
                        scheduledTime: timeStr,
                        daysOfWeek: selectedDays,
                        completedDates: [],
                        currentStreak: 0,
                        bestStreak: 0,
                        createdAt: DateTime.now(),
                        order: repo.getAllHabits().length,
                      );

                      await repo.addHabit(newHabit);
                      if (!mounted) return;
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
                              ? selectedColor.withValues(alpha: 0.3)
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
                                    color: color.withValues(alpha: 0.5),
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
                        colorValue: selectedColor.toARGB32(),
                        scheduledTime: timeStr,
                        daysOfWeek: selectedDays,
                      );

                      await repo.updateHabit(updatedHabit);
                      if (!mounted) return;
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
                      if (!mounted) return;
                      Navigator.pop(context);
                      FeedbackService.showSuccess(
                        context,
                        '🗑️ Hábito removido',
                      );
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
  // NOTE: _buildNotesAndReadingsSection, _buildNotesPill, _buildReadingsPill,
  // _buildPillItem e _openBooksBox foram extraídos para HomeNotesReadingsWidget
  // em lib/src/features/home/presentation/widgets/home_notes_readings_widget.dart
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
// NOTE: _NewsCarouselWidget foi extraído para HomeNewsCarouselWidget
// em lib/src/features/home/presentation/widgets/home_news_carousel_widget.dart

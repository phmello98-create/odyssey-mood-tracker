import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';

import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/animations/animations.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/tasks/data/synced_task_repository.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/features/news/presentation/news_screen.dart';
import 'package:odyssey/src/utils/smart_classifier.dart';
import 'package:odyssey/src/utils/widgets/smart_quick_add.dart';
import 'package:odyssey/src/utils/widgets/animated_stats.dart';
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
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import 'package:odyssey/src/utils/settings_provider.dart';

// Frases motivacionais/céticas e de grandes pensadores
const List<String> _dailyInsights = [
  // Céticas/Estoicas
  'Lembre-se: ninguém sabe o que está fazendo. Todos improvisam.',
  'O universo tem 13.8 bilhões de anos. Seu problema de hoje é temporário.',
  'Você é feito de poeira de estrelas tendo uma experiência humana.',
  'Em 100 anos, nada disso vai importar. Relaxa.',
  'Todo mundo está ocupado demais pensando em si mesmo pra te julgar.',
  'A Terra é um grão de areia no cosmos. Seus erros são microscópicos.',
  'Sucesso e fracasso são narrativas que inventamos. Apenas exista.',
  'Você já sobreviveu a 100% dos seus piores dias.',
  'O caos é o estado natural. Ordem é a exceção temporária.',
  'Seus antepassados sobreviveram a predadores. Você consegue com um e-mail.',
  'A ansiedade é seu cérebro primitivo tentando te proteger de tigres inexistentes.',
  'Nenhum plano sobrevive ao contato com a realidade. Adapte-se.',
  'O "eu ideal" não existe. Você já é a versão que está aqui agora.',
  'Perfeição é uma ilusão coletiva. Feito é melhor que perfeito.',
  'Sua única obrigação é respirar. O resto é extra.',

  // Maslow
  '"O que um homem pode ser, ele deve ser." — Maslow',
  '"A autorrealização é o uso pleno dos talentos e potencialidades." — Maslow',
  '"Se você planeja ser menos do que é capaz, será infeliz pelo resto da vida." — Maslow',
  '"Em qualquer momento, temos duas opções: avançar para o crescimento ou recuar para a segurança." — Maslow',
  '"O músico deve fazer música, o artista deve pintar, o poeta deve escrever." — Maslow',
  '"A vida é um processo contínuo de escolher entre segurança e risco." — Maslow',
  '"Precisamos de algo maior que nós mesmos para nos dedicarmos." — Maslow',

  // Estoicos
  '"Não é o que acontece com você, mas como você reage." — Epicteto',
  '"Sofremos mais na imaginação do que na realidade." — Sêneca',
  '"Quem tem um porquê vive qualquer como." — Nietzsche',
  '"O homem sábio não se aflige pelas coisas que não tem." — Epicteto',
  '"Faça cada ato como se fosse o último da sua vida." — Marco Aurélio',
  '"A felicidade não depende de coisas externas, mas de como as vemos." — Marco Aurélio',
  '"Não desperdice tempo discutindo o que um bom homem deve ser. Seja um." — Marco Aurélio',

  // Viktor Frankl
  '"Quem tem um porquê enfrenta qualquer como." — Viktor Frankl',
  '"Entre o estímulo e a resposta há um espaço. Nesse espaço está nosso poder de escolher." — Viktor Frankl',
  '"A vida nunca é insuportável pelas circunstâncias, apenas pela falta de sentido." — Viktor Frankl',

  // Carl Rogers
  '"O curioso paradoxo é que quando me aceito como sou, posso mudar." — Carl Rogers',
  '"Ser empático é ver o mundo com os olhos do outro." — Carl Rogers',

  // Motivacionais modernas
  'Cada pequeno passo conta. Continue.',
  'Hoje é um bom dia para recomeçar.',
  'Progresso, não perfeição.',
  'Você não precisa ser perfeito para começar, precisa começar para ser melhor.',
  'Disciplina é lembrar o que você quer.',
  'O hábito de hoje é o resultado de amanhã.',
  'Pequenas ações diárias criam grandes transformações.',
  'Não espere motivação. Crie disciplina.',
  'Seu futuro eu agradece suas escolhas de hoje.',
  'A consistência supera a intensidade.',

  // Zen/Mindfulness
  'Onde você está é onde você deve estar.',
  'Este momento é tudo que existe.',
  'Respire. Você está exatamente onde precisa estar.',
  'Não há caminho para a felicidade. A felicidade é o caminho.',
  'Comece onde você está. Use o que você tem. Faça o que puder.',
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

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _habitRepoInitialized = false;
  bool _taskRepoInitialized = false;
  String? _expandedHabitId;
  String _currentInsight = '';
  String _previousInsight = '';
  Timer? _insightTimer;

  // Tabs de Hábitos/Tarefas
  late PageController _habitsTasksPageController;
  int _habitsTasksTabIndex = 0;

  // Show/Hide completed items
  bool _showCompletedHabits = false;
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    _habitsTasksPageController = PageController();
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
    _habitsTasksPageController.dispose();
    _insightTimer?.cancel();
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

    return Scaffold(
      backgroundColor: WellnessColors.background, // Set background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ==========================================
              // HEADER CYBERPUNK - RELÓGIO DIGITAL EM TEMPO REAL
              // ==========================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Builder(
                    builder: (context) {
                      final settings = ref.watch(settingsProvider);
                      return _WellnessHeader(
                        avatarPath: settings.avatarPath,
                        userName: settings.userName,
                        onMenuTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(navigationProvider.notifier).goToProfile();
                        },
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
              // ACTIVITY CARD (Meditation/Yoga)
              // ==========================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildWellnessActivityCard(),
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
              // MOOD / COMUNIDADE
              // ==========================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Comunidade', // Using 'Comunidade' visual style for Mood Check-in
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Ver mais'),
                            ),
                          ],
                        ),
                      ),
                      _buildMoodSection(context),
                    ],
                  ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _previousMonth,
                        child: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        monthFormat.format(_selectedMonth).capitalize(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _nextMonth,
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                  child: Row(
                    children: [
                      Expanded(child: _buildNotesWidget(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildReadingsWidget(context)),
                    ],
                  ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 48,
                  color: colors.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Em breve',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conecte-se com outros usuários,\ncompartilhe conquistas e inspire-se!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                        Icons.rocket_launch_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recursos em desenvolvimento',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    }
  }

  Widget _buildDailyQuoteWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: WellnessColors.purpleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: WellnessColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
    final colors = Theme.of(context).colorScheme;

    if (!_habitRepoInitialized || !_taskRepoInitialized) {
      return _buildActivityCardPlaceholder(colors);
    }

    final habitRepo = ref.watch(habitRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        habitRepo.getPendingHabitsForDate(DateTime.now()),
        taskRepo.getPendingTasksForToday(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildActivityCardPlaceholder(colors);
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return _buildActivityCardPlaceholder(colors);
        }

        final habits = snapshot.data![0] as List<Habit>;
        final tasks = snapshot.data![1] as List<TaskData>;

        // Lógica de Priorização
        String title = 'Tempo Livre';
        String subtitle = 'Que tal uma pausa ou meditação?';
        IconData icon = Icons.spa_rounded;
        Color color = colors.primary;
        int timerMinutes = 15;
        bool hasActivity = false;

        // 1. Hábito agendado para agora ou próximo
        if (habits.isNotEmpty) {
          final scheduledHabits = habits
              .where((h) => h.scheduledTime != null)
              .toList();
          scheduledHabits.sort(
            (a, b) => a.scheduledTime!.compareTo(b.scheduledTime!),
          );

          final habit = scheduledHabits.isNotEmpty
              ? scheduledHabits.first
              : habits.first;

          hasActivity = true;
          title = habit.name;
          subtitle = habit.scheduledTime != null
              ? 'Agendado para ${habit.scheduledTime}'
              : 'Hábito pendente para hoje';
          icon = IconData(habit.iconCode, fontFamily: 'MaterialIcons');
          color = Color(habit.colorValue);
          timerMinutes = 20;
        }
        // 2. Tarefa de alta prioridade ou qualquer tarefa
        else if (tasks.isNotEmpty) {
          final highPriorityTasks = tasks
              .where((t) => t.priority == 'high')
              .toList();
          final task = highPriorityTasks.isNotEmpty
              ? highPriorityTasks.first
              : tasks.first;

          hasActivity = true;
          title = task.title;
          subtitle = task.priority == 'high'
              ? 'Prioridade Alta'
              : 'Tarefa pendente';
          icon = Icons.check_circle_outline_rounded;
          color = task.priority == 'high' ? colors.error : colors.tertiary;
          timerMinutes = 25;
        }

        return _buildActivityCardContent(
          colors: colors,
          title: title,
          subtitle: subtitle,
          icon: icon,
          color: color,
          hasActivity: hasActivity,
          timerMinutes: timerMinutes,
        );
      },
    );
  }

  Widget _buildActivityCardPlaceholder(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: colors.onPrimaryContainer.withOpacity(0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: colors.onSurface.withOpacity(0.1),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  color: colors.onSurfaceVariant.withOpacity(0.1),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCardContent({
    required ColorScheme colors,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool hasActivity,
    required int timerMinutes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: hasActivity
                        ? 0.7
                        : 0.0, // Mock progress based on activity
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref
                  .read(timerProvider.notifier)
                  .updatePomodoroSettings(
                    focusDuration: Duration(minutes: timerMinutes),
                    openPomodoroScreen: true,
                  );
              ref.read(navigationProvider.notifier).goToTimer();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded, color: color, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '48',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '12',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              Icon(
                Icons.share_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String svgPath, String label, Color color) {
    return MotionButton(
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
    );
  }

  // ==========================================
  // CALENDÁRIO SEMANAL (estilo HabitMate)
  // ==========================================
  Widget _buildWeekCalendar(BuildContext context) {
    final now = DateTime.now();
    // Pegar semana do mês selecionado que contém o dia selecionado
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
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
                    fontSize: 11,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isToday
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==========================================
  // SEÇÃO COMBINADA HÁBITOS/TAREFAS COM TABS
  // ==========================================
  Widget _buildHabitsTasksSection(BuildContext context) {
    return Column(
      children: [
        // Tab selector animado
        _buildHabitsTasksTabBar(context),
        const SizedBox(height: 16),
        // Calendário semanal (compartilhado)
        _buildWeekCalendar(context),
        const SizedBox(height: 16),
        // PageView com swipe entre hábitos e tarefas
        SizedBox(
          height: _calculatePageViewHeight(),
          child: PageView(
            controller: _habitsTasksPageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _habitsTasksTabIndex = index);
            },
            children: [
              // Página 0: Hábitos
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildHabitsList(context),
              ),
              // Página 1: Tarefas
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildTasksListInline(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculatePageViewHeight() {
    // Altura dinâmica baseada no conteúdo esperado
    // Mínimo 200, máximo 500 para não ficar muito grande
    return 350; // Valor base, pode ser ajustado
  }

  Widget _buildHabitsTasksTabBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Tab Hábitos
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _habitsTasksPageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _habitsTasksTabIndex == 0
                      ? colors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _habitsTasksTabIndex == 0
                      ? [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 18,
                      color: _habitsTasksTabIndex == 0
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hábitos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _habitsTasksTabIndex == 0
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
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
                _habitsTasksPageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _habitsTasksTabIndex == 1
                      ? colors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _habitsTasksTabIndex == 1
                      ? [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: _habitsTasksTabIndex == 1
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tarefas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _habitsTasksTabIndex == 1
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final tasks = snapshot.data ?? [];
        final pendingTasks = tasks.where((t) => !t.completed).toList();
        final completedTasks = tasks.where((t) => t.completed).toList();

        if (tasks.isEmpty) {
          return _buildEmptyTasksState(context);
        }

        final completed = completedTasks.length;
        final total = tasks.length;

        return Column(
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
                Container(
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
                    '$completed/$total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completed == total && total > 0
                          ? UltravioletColors.accentGreen
                          : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasksScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  completed == total && total > 0
                      ? UltravioletColors.accentGreen
                      : colors.primary,
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 14),

            // Tarefas pendentes
            ...pendingTasks.map((task) => _buildTaskItem(context, task)),

            // Botão mostrar/ocultar concluídos
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showCompletedTasks = !_showCompletedTasks);
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
                        _showCompletedTasks
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showCompletedTasks
                            ? 'Ocultar Concluídas (${completedTasks.length})'
                            : 'Mostrar Concluídas (${completedTasks.length})',
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
      },
    );
  }

  Widget _buildEmptyTasksState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TasksScreen()),
              );
            },
            child: Text(
              'Adicionar tarefa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskData task) {
    final colors = Theme.of(context).colorScheme;
    final isCompleted = task.completed;
    final syncedRepo = ref.read(syncedTaskRepositoryProvider);

    final priorityColor = task.priority == 'high'
        ? Colors.red
        : task.priority == 'low'
        ? Colors.green
        : Colors.orange;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await syncedRepo.toggleTaskCompletion(task.key);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? UltravioletColors.accentGreen.withOpacity(0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? UltravioletColors.accentGreen.withOpacity(0.3)
                : colors.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? UltravioletColors.accentGreen
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(7),
                border: isCompleted
                    ? null
                    : Border.all(color: colors.outline.withOpacity(0.3)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Título
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Indicador de prioridade
            if (task.priority != 'medium' && !isCompleted)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
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
                          color: isCompleted ? color : color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? color : color.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted
                                  ? color.withOpacity(0.3)
                                  : Colors.transparent,
                              blurRadius: isCompleted ? 8 : 0,
                              spreadRadius: isCompleted ? 1 : 0,
                            ),
                          ],
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

          // Conteúdo expandido
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
                  child: Column(
                    children: [
                      // Calendário mensal do hábito
                      _buildHabitMonthCalendar(habit),
                      const SizedBox(height: 16),
                      // Botões de ação
                      Row(
                        children: [
                          // Edit
                          TextButton.icon(
                            onPressed: () =>
                                _showEditHabitFormDialog(context, habit),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: UltravioletColors.primary,
                            ),
                            label: const Text(
                              'Editar',
                              style: TextStyle(
                                color: UltravioletColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Concluir/Desfazer
                          ElevatedButton.icon(
                            onPressed: () async {
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
                            icon: Icon(
                              isCompleted ? Icons.undo : Icons.check,
                              size: 18,
                            ),
                            label: Text(isCompleted ? 'Desfazer' : 'Concluir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? UltravioletColors.surfaceVariant
                                  : color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
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
    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? UltravioletColors.surfaceVariant
            : (isHighlighted ? color : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
        border: isCompleted && isCurrentMonth
            ? Border.all(color: color.withOpacity(0.5), width: 1.5)
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
            color: isCurrentMonth
                ? (isCompleted
                      ? color
                      : (isHighlighted
                            ? Colors.white
                            : Colors.white.withOpacity(0.8)))
                : Colors.white24,
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

        return Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF6B6B),
                value: bestStreak.toDouble(),
                label: 'Melhor Streak',
                delay: const Duration(milliseconds: 0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAnimatedStatCard(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF07E092),
                value: completedToday.toDouble(),
                suffix: '/${todayHabits.length}',
                label: 'Hoje',
                delay: const Duration(milliseconds: 100),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAnimatedStatCard(
                icon: Icons.trending_up_rounded,
                iconColor: UltravioletColors.primary,
                value: (weekRate * 100),
                suffix: '%',
                label: 'Semana',
                delay: const Duration(milliseconds: 200),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required Color iconColor,
    required double value,
    String? suffix,
    required String label,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(opacity: animValue.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [iconColor.withOpacity(0.15), iconColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, val, _) {
                return Transform.scale(
                  scale: val,
                  child: Icon(icon, color: iconColor, size: 24),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedStatNumber(
                  value: value,
                  suffix: suffix,
                  duration: const Duration(milliseconds: 1200),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRÁFICO SEMANAL (Bar Chart)
  // ==========================================
  Widget _buildWeeklyChart(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final now = DateTime.now();
        final todayIndex = now.weekday - 1;

        return OdysseyCard(
          padding: const EdgeInsets.all(20),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Progresso Semanal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                      'Esta semana',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Barras
              SizedBox(
                height: 120,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Largura da barra = espaço total / 7 - margem
                    final barWidth = (constraints.maxWidth / 7 - 6).clamp(
                      16.0,
                      24.0,
                    );

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final rate = weekRates[index] ?? 0.0;
                        final isToday = index == todayIndex;
                        final barHeight = 70 * rate + 8;

                        Color barColor;
                        if (rate >= 1.0) {
                          barColor = const Color(0xFF07E092);
                        } else if (rate >= 0.5) {
                          barColor = Theme.of(context).colorScheme.primary;
                        } else if (rate > 0) {
                          barColor = Theme.of(context).colorScheme.tertiary;
                        } else {
                          barColor = Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest;
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Percentual
                            Text(
                              '${(rate * 100).round()}%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: rate > 0 ? barColor : Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Barra
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              width: barWidth,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: isToday
                                        ? barColor.withOpacity(0.4)
                                        : Colors.transparent,
                                    blurRadius: isToday ? 8 : 0,
                                    spreadRadius: isToday ? 1 : 0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Dia
                            Text(
                              dayNames[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // INSIGHTS BASEADOS EM DADOS
  // ==========================================
  Widget _buildDataInsights(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final allHabits = habitRepo.getAllHabits();
        if (allHabits.isEmpty) return const SizedBox.shrink();

        // Encontrar o hábito com melhor streak
        Habit? bestHabit;
        int bestStreak = 0;
        for (final h in allHabits) {
          final s = h.calculateCurrentStreak();
          if (s > bestStreak) {
            bestStreak = s;
            bestHabit = h;
          }
        }

        // Calcular consistência (dias com pelo menos 1 hábito completado nos últimos 7 dias)
        int consistentDays = 0;
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final dayHabits = habitRepo.getHabitsForDate(date);
          if (dayHabits.any((h) => h.isCompletedOn(date))) {
            consistentDays++;
          }
        }

        // Gerar insights dinâmicos
        List<Map<String, dynamic>> insights = [];

        if (bestStreak >= 7) {
          insights.add({
            'icon': Icons.emoji_events,
            'color': const Color(0xFFFFD700),
            'text':
                '🏆 Incrível! ${bestHabit?.name} está em uma sequência de $bestStreak dias!',
          });
        } else if (bestStreak >= 3) {
          insights.add({
            'icon': Icons.local_fire_department,
            'color': const Color(0xFFFF6B6B),
            'text':
                '🔥 ${bestHabit?.name} está em alta com $bestStreak dias seguidos!',
          });
        }

        if (consistentDays >= 6) {
          insights.add({
            'icon': Icons.star,
            'color': const Color(0xFF07E092),
            'text':
                '⭐ Você foi consistente em $consistentDays dos últimos 7 dias. Excelente!',
          });
        } else if (consistentDays >= 4) {
          insights.add({
            'icon': Icons.trending_up,
            'color': UltravioletColors.primary,
            'text':
                '📈 Boa consistência! Ativo em $consistentDays dias esta semana.',
          });
        } else if (consistentDays < 3) {
          insights.add({
            'icon': Icons.lightbulb,
            'color': UltravioletColors.tertiary,
            'text':
                '💡 Dica: Comece com apenas 1 hábito por dia para criar momentum.',
          });
        }

        // Insight sobre horário (se tiver hábitos matinais)
        final morningHabits = allHabits.where((h) {
          if (h.scheduledTime == null) return false;
          final parts = h.scheduledTime!.split(':');
          if (parts.length != 2) return false;
          final hour = int.tryParse(parts[0]) ?? 12;
          return hour < 10;
        }).length;

        if (morningHabits > 0) {
          insights.add({
            'icon': Icons.wb_sunny,
            'color': const Color(0xFFFFA556),
            'text':
                '🌅 Você tem $morningHabits hábito(s) matinal(is). Ótimo para produtividade!',
          });
        }

        if (insights.isEmpty) {
          insights.add({
            'icon': Icons.rocket_launch,
            'color': UltravioletColors.primary,
            'text':
                '🚀 Continue assim! Cada pequeno passo conta na sua jornada.',
          });
        }

        return OdysseyCard(
          padding: const EdgeInsets.all(20),
          margin: EdgeInsets.zero,
          gradientColors: [
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
          borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Insights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...insights
                  .take(2)
                  .map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            insight['icon'] as IconData,
                            color: insight['color'] as Color,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              insight['text'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // RESUMO MENSAL
  // ==========================================
  Widget _buildMonthlyOverview(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final habitRepo = ref.watch(habitRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final allHabits = habitRepo.getAllHabits();
        if (allHabits.isEmpty) return const SizedBox.shrink();

        // Calcular estatísticas do mês
        final now = DateTime.now();
        final daysPassed = now.day;

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

        // Encontrar dia mais produtivo
        String bestDay = '';
        double bestDayRate = 0;
        final dayNames = [
          'Segunda',
          'Terça',
          'Quarta',
          'Quinta',
          'Sexta',
          'Sábado',
          'Domingo',
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

        return OdysseyCard(
          padding: const EdgeInsets.all(20),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resumo de ${DateFormat('MMMM', 'pt_BR').format(now).capitalize()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress circular grande com animação MOTOR
              Row(
                children: [
                  // Círculo de progresso com Motor
                  MotionCircularProgress(
                    value: monthRate,
                    size: 80,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: monthRate >= 0.7
                        ? const Color(0xFF07E092)
                        : (monthRate >= 0.4
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.tertiary),
                    motion: AppMotion.progress,
                    child: MotionCounter(
                      value: (monthRate * 100).round(),
                      suffix: '%',
                      motion: AppMotion.counter,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalCompletions de $totalPossible',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'hábitos completados',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (bestDay.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Melhor dia: $bestDay',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 16),
              // Mini heatmap dos últimos 14 dias
              Text(
                'Últimos 14 dias',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dotSize =
                      (constraints.maxWidth - 13 * 4) /
                      14; // 14 dots with 4px spacing
                  final size = dotSize.clamp(12.0, 18.0);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(14, (index) {
                      final date = now.subtract(Duration(days: 13 - index));
                      final dayHabits = habitRepo.getHabitsForDate(date);
                      final completedCount = dayHabits
                          .where((h) => h.isCompletedOn(date))
                          .length;
                      final rate = dayHabits.isNotEmpty
                          ? completedCount / dayHabits.length
                          : 0.0;

                      Color dotColor;
                      if (rate >= 1.0) {
                        dotColor = const Color(0xFF07E092);
                      } else if (rate >= 0.5) {
                        dotColor = Theme.of(context).colorScheme.primary;
                      } else if (rate > 0) {
                        dotColor = Theme.of(
                          context,
                        ).colorScheme.tertiary.withOpacity(0.6);
                      } else {
                        dotColor = Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest;
                      }

                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
            setState(() {});
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
  // WIDGET DE NOTAS (COMPACTO)
  // ==========================================
  Widget _buildNotesWidget(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.openBox('notes'),
      builder: (context, snapshot) {
        int noteCount = 0;
        String? lastNote;

        if (snapshot.hasData) {
          final box = snapshot.data!;
          noteCount = box.length;
          if (noteCount > 0) {
            final notes = box.values.toList();
            notes.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a['updatedAt'] ?? '') ?? DateTime(2000);
              final dateB =
                  DateTime.tryParse(b['updatedAt'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
            lastNote = notes.first['title'] ?? 'Sem título';
          }
        }

        return OdysseyCard(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
          },
          padding: const EdgeInsets.all(14),
          margin: EdgeInsets.zero,
          gradientColors: [
            Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
          ],
          borderColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
          child: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$noteCount notas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                if (lastNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastNote,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // WIDGET DE LEITURAS (COMPACTO)
  // ==========================================
  Widget _buildReadingsWidget(BuildContext context) {
    return FutureBuilder<Box<Book>>(
      future: _openBooksBox(),
      builder: (context, snapshot) {
        int readingCount = 0;
        String? currentBook;
        int pagesRead = 0;

        if (snapshot.hasData) {
          final box = snapshot.data!;
          final books = box.values.where((b) => !b.deleted).toList();
          readingCount = books
              .where((b) => b.status == BookStatus.inProgress)
              .length;
          final currentBooks = books
              .where((b) => b.status == BookStatus.inProgress)
              .toList();
          if (currentBooks.isNotEmpty) {
            currentBook = currentBooks.first.title;
          }
          pagesRead = books.fold(0, (sum, b) => sum + b.currentPage);
        }

        return OdysseyCard(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            );
          },
          padding: const EdgeInsets.all(14),
          margin: EdgeInsets.zero,
          gradientColors: [
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          borderColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Biblioteca',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$readingCount',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'lendo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentBook != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentBook,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
    final color = isPrimary
        ? WellnessColors.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final bg = isPrimary
        ? WellnessColors.primary.withOpacity(0.1)
        : Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: WellnessColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

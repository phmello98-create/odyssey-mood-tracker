import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'package:odyssey/src/features/home/presentation/widgets/home_suggestions_widget.dart'
    hide AnimatedBuilder;
import 'package:odyssey/src/features/home/presentation/widgets/global_search_bar.dart';
import 'package:odyssey/src/features/community/presentation/screens/community_screen.dart';
import 'package:odyssey/src/features/community/presentation/screens/create_post_screen.dart';
import 'package:odyssey/src/features/community/presentation/providers/community_providers.dart';
import 'package:odyssey/src/features/community/domain/post.dart';
import 'package:odyssey/src/features/community/presentation/widgets/user_avatar.dart';

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
  int _habitsTasksTabIndex = 0;

  // Calendário expandido (semana/mês)
  bool _isCalendarExpanded = false;

  // New variables for chart interactivity
  int _focusTouchedIndex = -1; // For Focus Pie Chart interaction
  int _moodTouchedIndex = -1; // For Mood Pie Chart interaction
  int _chartViewType = 0; // 0: Trend, 1: Pie, 2: Radar

  // NOTE: _selectedDate and _habitRepoInitialized are at lines 153-154
  int _selectedChartIndex = 0; // 0: Habits, 1: Focus, 2: Mood
  bool _isQuoteVisible =
      true; // Restoring this as it was flagged as unused but removal caused more errors? Or maybe not, but chart view logic depends on _selectedChartIndex.

  // Show/Hide completed items
  bool _showCompletedHabits = false;
  bool _showCompletedTasks = false;

  // Quick task creation controller
  final TextEditingController _quickTaskController = TextEditingController();

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
    _insightTimer?.cancel();
    _quickTaskController.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

    return Consumer(
      builder: (context, ref, child) {
        final feedAsync = ref.watch(feedProvider);

        return Container(
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
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                setState(() => _habitsTasksTabIndex = 0);
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
                setState(() => _habitsTasksTabIndex = 1);
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
            // Quick add task field
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickTaskController,
                      onSubmitted: (_) => _createQuickTask(taskRepo),
                      decoration: InputDecoration(
                        hintText: 'Nova tarefa...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(fontSize: 14, color: colors.onSurface),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () => _createQuickTask(taskRepo),
                      icon: Icon(
                        Icons.add_circle,
                        color: colors.primary,
                        size: 28,
                      ),
                      tooltip: 'Adicionar tarefa',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Column(
      children: [
        // Quick add task field (even when empty)
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickTaskController,
                  onSubmitted: (_) => _createQuickTask(taskRepo),
                  decoration: InputDecoration(
                    hintText: 'Digite uma nova tarefa...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(fontSize: 14, color: colors.onSurface),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _createQuickTask(taskRepo),
                  icon: Icon(Icons.add_circle, color: colors.primary, size: 28),
                  tooltip: 'Adicionar tarefa',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Empty state messaging
        Container(
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
        ),
      ],
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
                          color: isCompleted ? color : color.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? color : color.withOpacity(0.5),
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
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
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
  Widget _buildWeeklyChart(BuildContext context) {
    if (!_habitRepoInitialized) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return OdysseyCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW: Title + View Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumo Semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              // View Type Toggle (Right Aligned)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTypeToggle(
                      context,
                      0,
                      Icons.show_chart_rounded,
                    ), // Trend
                    const SizedBox(width: 4),
                    _buildViewTypeToggle(
                      context,
                      1,
                      Icons.pie_chart_rounded,
                    ), // Pie
                    const SizedBox(width: 4),
                    _buildViewTypeToggle(
                      context,
                      2,
                      Icons.radar_rounded,
                    ), // Radar
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CATEGORY SELECTOR (Centered)
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChartToggleBtn(
                    context,
                    0,
                    Icons.check_circle_outline,
                    'Hábitos',
                  ),
                  _buildChartToggleBtn(
                    context,
                    1,
                    Icons.timer_outlined,
                    'Foco',
                  ),
                  _buildChartToggleBtn(
                    context,
                    2,
                    Icons.mood_outlined,
                    'Humor',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // SELECTED CHART AREA
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildSelectedChart(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context) {
    // Habits
    if (_selectedChartIndex == 0) {
      switch (_chartViewType) {
        case 0:
          return _buildHabitsBarChart(context);
        case 1:
          return _buildHabitsPieChart(context);
        case 2:
          return _buildHabitsRadarChart(context);
        default:
          return _buildHabitsBarChart(context);
      }
    }
    // Focus
    if (_selectedChartIndex == 1) {
      switch (_chartViewType) {
        case 0:
          return _buildFocusLineChart(context);
        case 1:
          return _buildFocusPieChart(context);
        case 2:
          return _buildFocusScatterChart(
            context,
          ); // Using Scatter as 3rd option
        default:
          return _buildFocusLineChart(context);
      }
    }
    // Mood
    switch (_chartViewType) {
      case 0:
        return _buildMoodTrendChart(context);
      case 1:
        return _buildMoodPieChart(context);
      case 2:
        return _buildMoodRadarChart(context);
      default:
        return _buildMoodTrendChart(context);
    }
  }

  Widget _buildViewTypeToggle(BuildContext context, int index, IconData icon) {
    final isSelected = _chartViewType == index;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _chartViewType = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildChartToggleBtn(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedChartIndex == index;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedChartIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsBarChart(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
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
                    if (index < 0 || index >= dayNames.length)
                      return const SizedBox.shrink();

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
                    toY: rate.clamp(0.05, 1.0), // Min height for visibility
                    color: isToday
                        ? colors.primary
                        : (rate >= 1.0
                              ? const Color(0xFF07E092)
                              : colors.primary.withOpacity(
                                  rate > 0 ? 0.7 : 0.3,
                                )),
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 1.0,
                      color: colors.surfaceContainerHighest.withOpacity(0.3),
                    ),
                  ),
                ],
              );
            }),
            maxY: 1.0,
          ),
        );
      },
    );
  }

  Widget _buildFocusPieChart(BuildContext context) {
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
        final weeklyRecords = allRecords.where((r) {
          return r.startTime.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              r.startTime.isBefore(endOfWeek);
        }).toList();

        final durationByActivity = <String, double>{};
        double totalMinutes = 0;

        for (var record in weeklyRecords) {
          final minutes = record.durationInSeconds / 60;
          if (minutes > 0) {
            durationByActivity.update(
              record.activityName,
              (value) => value + minutes,
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
                  Icons.timer_off_outlined,
                  color: colors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem foco esta semana',
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
              flex: 3,
              child: PieChart(
                PieChartData(
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
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: List.generate(sortedEntries.length, (i) {
                    final isTouched = i == _focusTouchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 50.0 : 40.0;
                    final entry = sortedEntries[i];
                    final percentage = (entry.value / totalMinutes) * 100;

                    // Generate a color based on index or existing activity color
                    // Uses a predefined palette or generates one
                    final sectionColor =
                        Colors.primaries[i % Colors.primaries.length];

                    return PieChartSectionData(
                      color: sectionColor,
                      value: entry.value,
                      title: isTouched
                          ? '${percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_focusTouchedIndex != -1 &&
                      _focusTouchedIndex < sortedEntries.length) ...[
                    // Show details for touched section
                    _buildPieDetail(
                      sortedEntries[_focusTouchedIndex].key,
                      '${sortedEntries[_focusTouchedIndex].value.toStringAsFixed(0)} min',
                      Colors.primaries[_focusTouchedIndex %
                          Colors.primaries.length],
                      isLarge: true,
                    ),
                  ] else ...[
                    // Show summary or top activities
                    Text(
                      'Total: ${(totalMinutes / 60).toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedEntries.take(3).map((e) {
                      final index = sortedEntries.indexOf(e);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildPieDetail(
                          e.key,
                          '${(e.value / totalMinutes * 100).round()}%',
                          Colors.primaries[index % Colors.primaries.length],
                        ),
                      );
                    }),
                  ],
                ],
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

  Widget _buildMoodPieChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        final allRecords = moodRepo.fetchMoodRecords().values;
        final weeklyRecords = allRecords.where((r) {
          return r.date.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              r.date.isBefore(endOfWeek);
        }).toList();

        final countByLabel = <String, int>{};
        final colorByLabel = <String, Color>{};
        int totalRecords = weeklyRecords.length;

        for (var record in weeklyRecords) {
          final label = record.label;
          countByLabel.update(label, (val) => val + 1, ifAbsent: () => 1);
          if (!colorByLabel.containsKey(label)) {
            colorByLabel[label] = Color(record.color);
          }
        }

        if (totalRecords == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mood_bad_outlined,
                  color: colors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem registros de humor',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedEntries = countByLabel.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _moodTouchedIndex = -1;
                          return;
                        }
                        _moodTouchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: List.generate(sortedEntries.length, (i) {
                    final isTouched = i == _moodTouchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 50.0 : 40.0;
                    final entry = sortedEntries[i];
                    final percentage = (entry.value / totalRecords) * 100;
                    final color = colorByLabel[entry.key] ?? Colors.grey;

                    return PieChartSectionData(
                      color: color,
                      value: entry.value.toDouble(),
                      title: isTouched
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_moodTouchedIndex != -1 &&
                      _moodTouchedIndex < sortedEntries.length) ...[
                    // Show details for touched section
                    _buildPieDetail(
                      sortedEntries[_moodTouchedIndex].key,
                      '${sortedEntries[_moodTouchedIndex].value} reg.',
                      colorByLabel[sortedEntries[_moodTouchedIndex].key] ??
                          Colors.grey,
                      isLarge: true,
                    ),
                  ] else ...[
                    // General Info
                    Text(
                      'Total: $totalRecords',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedEntries.take(3).map((e) {
                      // final index = sortedEntries.indexOf(e);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildPieDetail(
                          e.key,
                          '${(e.value / totalRecords * 100).round()}%',
                          colorByLabel[e.key] ?? Colors.grey,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // HABITS CHARTS (Values: 1: Pie, 2: Radar)
  // ==========================================

  Widget _buildHabitsPieChart(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();

        double totalCompletedPercent = 0;
        int daysWithData = 0;

        for (int i = 0; i < 7; i++) {
          if (weekRates.containsKey(i)) {
            totalCompletedPercent += weekRates[i]!;
            daysWithData++;
          }
        }

        double averageCompletion = daysWithData > 0
            ? (totalCompletedPercent / 7)
            : 0.0;
        double remaining = 1.0 - averageCompletion;

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF07E092),
                      value: averageCompletion * 100,
                      title: '${(averageCompletion * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: colors.surfaceContainerHighest,
                      value: remaining * 100,
                      title: '',
                      radius: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPieDetail(
                    'Concluído',
                    '${(averageCompletion * 100).toStringAsFixed(0)}%',
                    const Color(0xFF07E092),
                  ),
                  const SizedBox(height: 8),
                  _buildPieDetail(
                    'Pendente',
                    '${(remaining * 100).toStringAsFixed(0)}%',
                    colors.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsRadarChart(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        final dataEntries = <RadarEntry>[];
        for (int i = 0; i < 7; i++) {
          dataEntries.add(RadarEntry(value: (weekRates[i] ?? 0.0) * 100));
        }

        if (dataEntries.every((e) => e.value == 0)) {
          return Center(
            child: Text(
              'Sem dados esta semana',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        return RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            tickCount: 4,
            ticksTextStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 8,
            ),
            tickBorderData: BorderSide(
              color: colors.outlineVariant.withOpacity(0.3),
            ),
            gridBorderData: BorderSide(
              color: colors.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
            titleTextStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
            getTitle: (index, angle) => RadarChartTitle(text: dayNames[index]),
            dataSets: [
              RadarDataSet(
                fillColor: colors.primary.withOpacity(0.2),
                borderColor: colors.primary,
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: dataEntries,
              ),
            ],
          ),
        );
      },
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
        final maxY = maxVal > 0 ? maxVal * 1.2 : 60.0;
        final dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

        if (maxVal == 0) {
          return Center(
            child: Text(
              'Sem sessões de foco',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
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
                    final index = value.toInt();
                    if (index < 0 || index >= dayNames.length)
                      return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        dayNames[index],
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
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  7,
                  (i) => FlSpot(i.toDouble(), dailyMinutes[i]),
                ),
                isCurved: true,
                color: const Color(0xFF5E60CE),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF5E60CE).withOpacity(0.15),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colors.surfaceContainerHighest,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .map(
                        (spot) => LineTooltipItem(
                          '${spot.y.toInt()} min',
                          TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusScatterChart(BuildContext context) {
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

        if (weeklyRecords.isEmpty) {
          return Center(
            child: Text(
              'Sem sessões de foco',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final activityMap = <String, int>{};
        int activityIndex = 0;
        for (var r in weeklyRecords) {
          if (!activityMap.containsKey(r.activityName))
            activityMap[r.activityName] = activityIndex++;
        }

        final spots = weeklyRecords.map((r) {
          return ScatterSpot(
            activityMap[r.activityName]!.toDouble(),
            r.durationInSeconds / 60,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color:
                  Colors.primaries[activityMap[r.activityName]! %
                      Colors.primaries.length],
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          );
        }).toList();

        final maxY = spots.map((s) => s.y).reduce(max) * 1.2;

        return ScatterChart(
          ScatterChartData(
            scatterSpots: spots,
            minX: -0.5,
            maxX: (activityMap.length - 0.5).clamp(0.5, double.infinity),
            minY: 0,
            maxY: maxY > 0 ? maxY : 60,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: colors.outlineVariant.withOpacity(0.2),
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
                    final name = activityMap.keys.elementAtOrNull(
                      value.toInt(),
                    );
                    if (name == null) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        name.length > 4 ? '${name.substring(0, 4)}.' : name,
                        style: TextStyle(
                          fontSize: 8,
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
            scatterTouchData: ScatterTouchData(
              enabled: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipColor: (_) => colors.surfaceContainerHighest,
                getTooltipItems: (touchedSpot) {
                  final name =
                      activityMap.keys.elementAtOrNull(touchedSpot.x.toInt()) ??
                      '?';
                  return ScatterTooltipItem(
                    '$name\n${touchedSpot.y.toInt()} min',
                    textStyle: TextStyle(
                      color: colors.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
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
        for (int i = 0; i < 7; i++) {
          if (dailyCounts[i] > 0)
            spots.add(FlSpot(i.toDouble(), dailyScores[i] / dailyCounts[i]));
        }

        if (spots.isEmpty) {
          return Center(
            child: Text(
              'Sem registros de humor',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
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
                    if (idx < 0 || idx >= 7) return const SizedBox.shrink();
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
            maxY: 5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFFFFB703),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFFB703).withOpacity(0.15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodRadarChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        final allRecords = moodRepo.fetchMoodRecords().values.where(
          (r) =>
              r.date.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              r.date.isBefore(endOfWeek),
        );

        final dailyScores = List.filled(7, 0.0);
        final dailyCounts = List.filled(7, 0);

        for (var record in allRecords) {
          final idx = record.date.weekday - 1;
          if (idx >= 0 && idx < 7) {
            dailyScores[idx] += record.score;
            dailyCounts[idx]++;
          }
        }

        final dataEntries = <RadarEntry>[];
        for (int i = 0; i < 7; i++) {
          final avg = dailyCounts[i] > 0
              ? (dailyScores[i] / dailyCounts[i])
              : 0.0;
          dataEntries.add(RadarEntry(value: avg));
        }

        if (dataEntries.every((e) => e.value == 0)) {
          return Center(
            child: Text(
              'Sem dados de humor',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        return RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            tickCount: 5,
            ticksTextStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 8,
            ),
            tickBorderData: BorderSide(
              color: colors.outlineVariant.withOpacity(0.3),
            ),
            gridBorderData: BorderSide(
              color: colors.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
            titleTextStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
            getTitle: (index, angle) => RadarChartTitle(text: dayNames[index]),
            dataSets: [
              RadarDataSet(
                fillColor: const Color(0xFFFFB703).withOpacity(0.2),
                borderColor: const Color(0xFFFFB703),
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: dataEntries,
              ),
            ],
          ),
        );
      },
    );
  }

  void refresh() {
    if (mounted) setState(() {});
  }
}

// Continuation of _HomeScreenState methods
extension _HomeScreenStateDataInsights on _HomeScreenState {
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
            final allTasks = taskBox.values.cast<TaskData>().toList();
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
                'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                'text':
                    '🔥 ${bestHabit?.name} está em alta com $bestStreak dias seguidos!',
                'badge': '$bestStreak dias',
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
              });
            } else if (consistentDays >= 4) {
              insights.add({
                'icon': Icons.trending_up_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    '📈 Boa consistência! Ativo em $consistentDays dias esta semana.',
                'badge': '$consistentDays/7',
              });
            }

            // Insight sobre humor
            if (allMoods.isNotEmpty) {
              String moodEmoji = '😊';
              String moodText = 'Bem';
              if (avgMoodScore >= 4.5) {
                moodEmoji = '😄';
                moodText = 'Excelente';
              } else if (avgMoodScore >= 3.5) {
                moodEmoji = '😊';
                moodText = 'Bem';
              } else if (avgMoodScore >= 2.5) {
                moodEmoji = '😐';
                moodText = 'Ok';
              } else {
                moodEmoji = '😔';
                moodText = 'Desafiador';
              }

              insights.add({
                'icon': Icons.mood_rounded,
                'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                'text':
                    '$moodEmoji Seu humor médio esta semana está $moodText (${avgMoodScore.toStringAsFixed(1)}/5).',
                'badge': '${allMoods.length} registros',
              });
            }

            // Insight sobre tarefas
            if (allTasks.length >= 5) {
              insights.add({
                'icon': Icons.check_circle_rounded,
                'gradient': [const Color(0xFF07E092), const Color(0xFF00B4D8)],
                'text':
                    '✅ Taxa de conclusão de tarefas: ${(taskCompletionRate * 100).round()}% ($completedTasks de ${allTasks.length}).',
                'badge': '${(taskCompletionRate * 100).round()}%',
              });
            }

            // Insight sobre foco
            if (totalMinutes >= 60) {
              final hours = (totalMinutes / 60).toStringAsFixed(1);
              insights.add({
                'icon': Icons.timer_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    '⏱️ Você focou por ${hours}h esta semana. Mantendo o ritmo!',
                'badge': '${hours}h',
              });
            }

            // Insight sobre notas
            if (recentNotes > 0) {
              insights.add({
                'icon': Icons.lightbulb_rounded,
                'gradient': [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                'text':
                    '💡 $recentNotes nota${recentNotes > 1 ? 's' : ''} criada${recentNotes > 1 ? 's' : ''} esta semana. Capturando ideias!',
                'badge': '$recentNotes nota${recentNotes > 1 ? 's' : ''}',
              });
            }

            // Insight sobre horário matinal
            if (morningHabits > 0) {
              insights.add({
                'icon': Icons.wb_sunny_rounded,
                'gradient': [const Color(0xFFFFA556), const Color(0xFFFF6B6B)],
                'text':
                    '🌅 Você tem $morningHabits hábito(s) matinal(is). Ótimo para produtividade!',
                'badge': '$morningHabits matinais',
              });
            }

            // Fallback
            if (insights.isEmpty) {
              insights.add({
                'icon': Icons.rocket_launch_rounded,
                'gradient': [const Color(0xFF5E60CE), const Color(0xFF7209B7)],
                'text':
                    '🚀 Continue assim! Cada pequeno passo conta na sua jornada.',
                'badge': 'Vamos lá!',
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
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com gradiente
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights Inteligentes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Análise do seu progresso',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Insights cards
                  ...topInsights.map((insight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outline.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (insight['gradient'] as List<Color>).first
                                  .withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ícone com gradiente
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: insight['gradient'] as List<Color>,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (insight['gradient'] as List<Color>)
                                        .first
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
                                  color: colors.onSurface.withOpacity(0.9),
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (insight['gradient'] as List<Color>).first
                                        .withOpacity(0.2),
                                    (insight['gradient'] as List<Color>).last
                                        .withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (insight['gradient'] as List<Color>)
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
                                  color: (insight['gradient'] as List<Color>)
                                      .first,
                                ),
                              ),
                            ),
                          ],
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

  // Helper method to create quick task
  Future<void> _createQuickTask(TaskRepository taskRepo) async {
    final text = _quickTaskController.text.trim();
    if (text.isEmpty) return;

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
    refresh(); // Refresh UI
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
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
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
                  boxShadow: [
                    BoxShadow(
                      color: WellnessColors.success.withOpacity(
                        0.5 * _animation.value,
                      ),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
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

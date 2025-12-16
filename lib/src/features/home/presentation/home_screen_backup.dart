import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/glass_card.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/utils/services/insights_engine.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

// Insights céticos - frases que tiram o peso da realidade
const List<String> _skepticInsights = [
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
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabController;
  late AnimationController _quoteAnimController;
  late Animation<double> _quoteFadeAnim;
  late Animation<Offset> _quoteSlideAnim;
  
  bool _isFabOpen = false;
  String _currentQuote = '';
  String? _currentQuoteAuthor;
  InsightData? _currentInsight;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  Box? _quotesBox;
  List<Map<dynamic, dynamic>> _userQuotes = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Animação para transição de quotes
    _quoteAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _quoteFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _quoteAnimController, curve: Curves.easeInOut),
    );
    _quoteSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _quoteAnimController, curve: Curves.easeOutCubic));
    
    _initQuotes();
  }
  
  Future<void> _initQuotes() async {
    _quotesBox = await Hive.openBox('quotes');
    _loadUserQuotes();
    _refreshInsight();
    _setNextQuote();
    _quoteAnimController.forward();
    
    // Troca de quote a cada 15 segundos
    _quoteTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _animateQuoteChange();
    });
  }
  
  void _loadUserQuotes() {
    if (_quotesBox != null) {
      _userQuotes = _quotesBox!.values
          .map((e) => Map<dynamic, dynamic>.from(e as Map))
          .toList();
    }
  }
  
  void _refreshInsight() {
    try {
      final engine = ref.read(insightsEngineProvider);
      _currentInsight = engine.generateInsight();
    } catch (e) {
      // Fallback para insight padrão se houver erro
      _currentInsight = InsightData(
        type: InsightType.motivation,
        icon: Icons.auto_awesome,
        title: 'Bem-vindo ao Odyssey',
        message: 'Seu companheiro de jornada pessoal.',
        priority: 1,
      );
    }
  }
  
  void _setNextQuote() {
    _loadUserQuotes(); // Atualiza lista de quotes do usuário
    
    if (_userQuotes.isNotEmpty) {
      _quoteIndex = (_quoteIndex + 1) % _userQuotes.length;
      final quote = _userQuotes[_quoteIndex];
      _currentQuote = quote['text'] ?? '';
      _currentQuoteAuthor = quote['author'];
    } else {
      // Fallback para quotes padrão
      final defaultQuotes = [
        'Cada momento é uma nova oportunidade.',
        'Você é mais forte do que imagina.',
        'Pequenos passos levam a grandes conquistas.',
        'Cuide de você, você merece.',
        'Hoje é um bom dia para ser feliz.',
      ];
      _quoteIndex = (_quoteIndex + 1) % defaultQuotes.length;
      _currentQuote = defaultQuotes[_quoteIndex];
      _currentQuoteAuthor = null;
    }
    setState(() {});
  }
  
  void _animateQuoteChange() async {
    await _quoteAnimController.reverse();
    _setNextQuote();
    _refreshInsight();
    await _quoteAnimController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _quoteAnimController.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 18) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Color _getInsightColor(InsightType? type) {
    switch (type) {
      case InsightType.achievement:
        return UltravioletColors.accentGreen;
      case InsightType.warning:
        return const Color(0xFFFF9800);
      case InsightType.support:
        return UltravioletColors.moodGood;
      case InsightType.suggestion:
        return UltravioletColors.primary;
      case InsightType.motivation:
      default:
        return UltravioletColors.tertiary;
    }
  }

  void _handleInsightAction(InsightData? insight) {
    if (insight?.actionType == null) return;
    
    HapticFeedback.lightImpact();
    
    switch (insight!.actionType!) {
      case InsightAction.recordMood:
        showModalBottomSheet(
          useSafeArea: true,
          isScrollControlled: true,
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => const AddMoodRecordForm(recordToEdit: null),
          ),
        );
        break;
      case InsightAction.startTimer:
        ref.read(navigationProvider.notifier).goToTimer();
        break;
      case InsightAction.viewAnalytics:
        // Navigate to analytics
        break;
      case InsightAction.createTask:
        _showQuickTaskDialog(context);
        break;
      case InsightAction.createNote:
        _showQuickNoteDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM', 'pt_BR');
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildExpandableFAB(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header com saudação e insight cético
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Ícone animado de brilho
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(seconds: 2),
                                      builder: (context, value, child) {
                                        return Transform.rotate(
                                          angle: value * 0.5,
                                          child: Opacity(
                                            opacity: 0.5 + (0.5 * (1 + sin(value * 6.28)) / 2),
                                            child: const Icon(Icons.auto_awesome, 
                                              color: UltravioletColors.secondary, 
                                              size: 20,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(now),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: UltravioletColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Avatar/Profile button - clicável
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Navega para aba Perfil (índice 4)
                              ref.read(navigationProvider.notifier).goToProfile();
                            },
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: 1.0),
                              duration: const Duration(milliseconds: 150),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: UltravioletColors.accentGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: UltravioletColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Insight dinâmico animado
                      SlideTransition(
                        position: _quoteSlideAnim,
                        child: FadeTransition(
                          opacity: _quoteFadeAnim,
                          child: GestureDetector(
                            onTap: () => _handleInsightAction(_currentInsight),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getInsightColor(_currentInsight?.type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getInsightColor(_currentInsight?.type).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _getInsightColor(_currentInsight?.type).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _currentInsight?.icon ?? Icons.lightbulb_outline, 
                                      color: _getInsightColor(_currentInsight?.type), 
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currentInsight?.title ?? 'Bem-vindo',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: _getInsightColor(_currentInsight?.type),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _currentInsight?.message ?? 'Como você está hoje?',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: UltravioletColors.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_currentInsight?.actionLabel != null)
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: _getInsightColor(_currentInsight?.type).withValues(alpha: 0.5),
                                      size: 14,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quote do dia com animação
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: _animateQuoteChange,
                    child: SlideTransition(
                      position: _quoteSlideAnim,
                      child: FadeTransition(
                        opacity: _quoteFadeAnim,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                UltravioletColors.primaryContainer.withValues(alpha: 0.2),
                                UltravioletColors.secondaryContainer.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: UltravioletColors.primary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: UltravioletColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.format_quote_rounded,
                                  color: UltravioletColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentQuote.isNotEmpty ? _currentQuote : 'Toque para ver uma frase...',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: UltravioletColors.onSurface,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (_currentQuoteAuthor != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '— $_currentQuoteAuthor',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: UltravioletColors.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.touch_app_rounded,
                                color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.3),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Como você está se sentindo?
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.howAreYouFeeling,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMoodButton(
                            context,
                            'assets/mood_icons/smile.svg',
                            'Great',
                            UltravioletColors.moodGreat,
                          ),
                          _buildMoodButton(
                            context,
                            'assets/mood_icons/calm.svg',
                            'Positive',
                            UltravioletColors.moodGood,
                          ),
                          _buildMoodButton(
                            context,
                            'assets/mood_icons/neutral.svg',
                            'Alright',
                            UltravioletColors.moodOkay,
                          ),
                          _buildMoodButton(
                            context,
                            'assets/mood_icons/sad.svg',
                            'Bad',
                            UltravioletColors.moodBad,
                          ),
                          _buildMoodButton(
                            context,
                            'assets/mood_icons/loudly_crying.svg',
                            'Awful',
                            UltravioletColors.moodTerrible,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Ações Rápidas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ações Rápidas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.timer_outlined,
                              label: 'Pomodoro',
                              color: UltravioletColors.secondary,
                              onTap: () {
                                // Navega para aba Timer (índice 3)
                                ref.read(navigationProvider.notifier).goToTimer();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.note_add_outlined,
                              label: 'Nota Rápida',
                              color: UltravioletColors.tertiary,
                              onTap: () {
                                _showQuickNoteDialog(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.check_circle_outline,
                              label: AppLocalizations.of(context)!.newTask,
                              color: UltravioletColors.accentGreen,
                              onTap: () {
                                _showQuickTaskDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Biblioteca Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: UltravioletColors.tertiary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.library_books,
                                  color: UltravioletColors.tertiary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.library,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _navigateTo(const NotesScreen()),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(AppLocalizations.of(context)!.abrir),
                            style: TextButton.styleFrom(
                              foregroundColor: UltravioletColors.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLibraryCard(
                              icon: Icons.sticky_note_2,
                              label: AppLocalizations.of(context)!.notes,
                              color: UltravioletColors.primary,
                              onTap: () => _navigateTo(const NotesScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLibraryCard(
                              icon: Icons.menu_book,
                              label: 'Leituras',
                              color: UltravioletColors.accentGreen,
                              onTap: () => _navigateTo(const NotesScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLibraryCard(
                              icon: Icons.format_quote,
                              label: 'Frases',
                              color: UltravioletColors.secondary,
                              onTap: () => _navigateTo(const NotesScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Resumo do Dia
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resumo do Dia',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navega para a aba Log (índice 1) via provider
                              ref.read(navigationProvider.notifier).goToLog();
                            },
                            child: Text(
                              AppLocalizations.of(context)!.seeMore,
                              style: const TextStyle(
                                color: UltravioletColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats with live data
                      ValueListenableBuilder(
                        valueListenable: moodRepo.box.listenable(),
                        builder: (context, moodBox, _) {
                          return ValueListenableBuilder(
                            valueListenable: timeRepo.box.listenable(),
                            builder: (context, timeBox, _) {
                              final today = DateTime.now();
                              
                              // Count mood records for today
                              final moodCount = moodBox.values
                                  .cast<MoodRecord>()
                                  .where((r) => _isSameDay(r.date, today))
                                  .length;
                              
                              // Calculate total focus time today
                              final timeRecords = timeBox.values
                                  .cast<TimeTrackingRecord>()
                                  .where((r) => _isSameDay(r.startTime, today))
                                  .toList();
                              final totalSeconds = timeRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds);
                              final hours = totalSeconds ~/ 3600;
                              final minutes = (totalSeconds % 3600) ~/ 60;
                              final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(
                                          title: 'Registros de Humor',
                                          value: '$moodCount',
                                          icon: Icons.mood,
                                          iconColor: UltravioletColors.moodGood,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StatCard(
                                          title: 'Tempo Focado',
                                          value: timeStr,
                                          icon: Icons.timer,
                                          iconColor: UltravioletColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(
                                          title: 'Sessões de Foco',
                                          value: '${timeRecords.length}',
                                          icon: Icons.check_circle,
                                          iconColor: UltravioletColors.accentGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StatCard(
                                          title: 'Total Registros',
                                          value: '${moodCount + timeRecords.length}',
                                          icon: Icons.analytics,
                                          iconColor: UltravioletColors.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Atividades Recentes com dados dinâmicos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Atividades Recentes',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(navigationProvider.notifier).goToLog(),
                            child: const Text(
                              'Ver histórico',
                              style: TextStyle(
                                color: UltravioletColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dynamic recent activities
                      ValueListenableBuilder(
                        valueListenable: moodRepo.box.listenable(),
                        builder: (context, moodBox, _) {
                          return ValueListenableBuilder(
                            valueListenable: timeRepo.box.listenable(),
                            builder: (context, timeBox, _) {
                              final allMoods = moodBox.values.cast<MoodRecord>().toList();
                              final allTime = timeBox.values.cast<TimeTrackingRecord>().toList();
                              
                              // Combine and sort by date
                              final items = <Map<String, dynamic>>[];
                              for (final m in allMoods) {
                                items.add({'type': 'mood', 'date': m.date, 'data': m});
                              }
                              for (final t in allTime) {
                                items.add({'type': 'time', 'date': t.startTime, 'data': t});
                              }
                              items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                              
                              // Take last 5
                              final recent = items.take(5).toList();
                              
                              if (recent.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(
                                      'Nenhuma atividade ainda.\nComece registrando seu humor!',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: UltravioletColors.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              
                              return Column(
                                children: recent.map((item) {
                                  if (item['type'] == 'mood') {
                                    final m = item['data'] as MoodRecord;
                                    return _buildActivityItem(
                                      context,
                                      icon: Icons.mood,
                                      title: 'Registro de Humor',
                                      subtitle: m.label,
                                      time: _formatRelativeTime(m.date),
                                      color: Color(m.color),
                                    );
                                  } else {
                                    final t = item['data'] as TimeTrackingRecord;
                                    final mins = t.duration.inMinutes;
                                    return _buildActivityItem(
                                      context,
                                      icon: Icons.timer,
                                      title: 'Sessão de Foco',
                                      subtitle: '${t.activityName} - ${mins}min',
                                      time: _formatRelativeTime(t.startTime),
                                      color: UltravioletColors.secondary,
                                    );
                                  }
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs - só mostrar quando aberto
        if (_isFabOpen) ...[
          _buildSpeedDialItem(
            index: 3,
            icon: Icons.timer_rounded,
            label: 'Iniciar Timer',
            color: UltravioletColors.tertiary,
            onTap: () {
              _toggleFab();
              ref.read(navigationProvider.notifier).goToTimer();
            },
          ),
          _buildSpeedDialItem(
            index: 2,
            icon: Icons.check_circle_rounded,
            label: AppLocalizations.of(context)!.newTask,
            color: UltravioletColors.accentGreen,
            onTap: () {
              _toggleFab();
              _showQuickTaskDialog(context);
            },
          ),
          _buildSpeedDialItem(
            index: 1,
            icon: Icons.edit_note_rounded,
            label: 'Nota Rápida',
            color: UltravioletColors.primary,
            onTap: () {
              _toggleFab();
              _showQuickNoteDialog(context);
            },
          ),
          _buildSpeedDialItem(
            index: 0,
            icon: Icons.mood_rounded,
            label: 'Como você está?',
            color: UltravioletColors.moodGood,
            onTap: () {
              _toggleFab();
              showModalBottomSheet(
                useSafeArea: true,
                isScrollControlled: true,
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) => const AddMoodRecordForm(recordToEdit: null),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        // FAB principal
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: UltravioletColors.primary,
          elevation: 4,
          child: AnimatedRotation(
            turns: _isFabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 150 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label com chip estilizado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: UltravioletColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: UltravioletColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mini FAB com hover effect
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickQuoteDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote, color: UltravioletColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Nova Frase',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '"Escreva sua frase ou citação aqui..."',
                hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Autor (opcional)',
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.fraseSalvaComSucesso),
                      backgroundColor: UltravioletColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: UltravioletColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.salvarFrase, style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMoodButton(
    BuildContext context,
    String svgPath,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          useSafeArea: true,
          isScrollControlled: true,
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => const AddMoodRecordForm(recordToEdit: null),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                svgPath,
                width: 32,
                height: 32,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: UltravioletColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: UltravioletColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UltravioletColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UltravioletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: UltravioletColors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: UltravioletColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UltravioletColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.quickNote,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escreva sua nota aqui...',
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save note logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.notaSalvaComSucesso),
                      backgroundColor: UltravioletColors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.salvarNota),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQuickTaskDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.newTask,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome da tarefa...',
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save task logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.tarefaAdicionadaComSucesso),
                      backgroundColor: UltravioletColors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.adicionarTarefa),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

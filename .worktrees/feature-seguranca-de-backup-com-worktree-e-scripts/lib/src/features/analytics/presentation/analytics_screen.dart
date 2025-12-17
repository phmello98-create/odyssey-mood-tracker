import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/synced_mood_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/utils/icon_map.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/subscription/presentation/ad_banner_widget.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/utils/services/note_intelligence_service.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPeriod = 0; // 0 = Week, 1 = Month, 2 = Year
  late TabController _tabController;
  
  // Showcase keys
  final GlobalKey _showcasePeriod = GlobalKey();
  final GlobalKey _showcaseCharts = GlobalKey();
  final GlobalKey _showcaseInsights = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.analytics);
    _tabController.dispose();
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcasePeriod, _showcaseCharts, _showcaseInsights];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.analytics,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.analytics, keys);
  }

  void _startTour() {
    final keys = [_showcasePeriod, _showcaseCharts, _showcaseInsights];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.analytics, keys);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FirstTimeDetector(
      screenId: 'analytics_screen',
      category: FeatureCategory.analytics,
      tourId: null, // No tour defined yet for analytics
      child: Material(
        color: colors.surface,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(AppLocalizations.of(context)!.insights,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Botão de settings removido - era apenas decorativo
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.trackProgressPatterns,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Period Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildPeriodSelector(),
              ),
            ),

            // Quick Stats Cards
            SliverToBoxAdapter(
              child: _buildQuickStats(),
            ),

            // AI Insight Card
            SliverToBoxAdapter(
              child: _buildAIInsightCard(),
            ),

            // Note Sentiment Analysis
            SliverToBoxAdapter(
              child: _buildNoteSentimentAnalysis(),
            ),

            // Time Distribution Chart
            SliverToBoxAdapter(
              child: _buildTimeDistributionChart(),
            ),

            // Time Activity Chart (respeita período selecionado)
            SliverToBoxAdapter(
              child: _buildTimeActivityChart(),
            ),

            // Top Activities
            SliverToBoxAdapter(
              child: _buildTopActivities(),
            ),

            // Mood Correlation
            SliverToBoxAdapter(
              child: _buildMoodCorrelation(),
            ),

            // Productivity Heatmap
            SliverToBoxAdapter(
              child: _buildProductivityHeatmap(),
            ),

            // Activity Correlation Chart
            SliverToBoxAdapter(
              child: _buildActivityCorrelationChart(),
            ),

            // Trend Analysis Chart
            SliverToBoxAdapter(
              child: _buildTrendAnalysisChart(),
            ),

            // Category Radar Chart
            SliverToBoxAdapter(
              child: _buildCategoryRadarChart(),
            ),

            // Behavior Patterns Analysis
            SliverToBoxAdapter(
              child: _buildBehaviorPatternsChart(),
            ),

            // Streaks & Achievements
            SliverToBoxAdapter(
              child: _buildStreaksSection(),
            ),

            // Banner de anúncio (usuários free)
            const SliverToBoxAdapter(
              child: AdBannerWidget(
                margin: EdgeInsets.fromLTRB(20, 16, 20, 16),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context)!;
    final periods = [l10n.periodWeek, l10n.periodMonth, l10n.periodYear];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final records = box.values.cast<TimeTrackingRecord>().toList();
        
        // Calcular estatísticas baseadas no período selecionado
        final filteredRecords = _filterByPeriod(records, now);
        
        final totalMinutes = filteredRecords.fold<int>(
          0, (sum, r) => sum + r.durationInSeconds ~/ 60,
        );
        final totalHours = totalMinutes ~/ 60;
        final remainingMinutes = totalMinutes % 60;
        
        final totalSessions = filteredRecords.length;
        
        // Calcular dias ativos
        final activeDays = filteredRecords
            .map((r) => DateTime(r.startTime.year, r.startTime.month, r.startTime.day))
            .toSet()
            .length;
        
        // Média diária
        final avgMinutesPerDay = activeDays > 0 ? totalMinutes ~/ activeDays : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      label: AppLocalizations.of(context)!.totalTime,
                      value: '${totalHours}h ${remainingMinutes}m',
                      trend: '+12%',
                      trendUp: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.bolt,
                      iconColor: Theme.of(context).colorScheme.tertiary,
                      label: AppLocalizations.of(context)!.sessions,
                      value: '$totalSessions',
                      trend: '+5',
                      trendUp: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_today,
                      iconColor: const Color(0xFF07E092),
                      label: AppLocalizations.of(context)!.activeDays,
                      value: '$activeDays',
                      trend: null,
                      trendUp: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      label: AppLocalizations.of(context)!.avgPerDay,
                      value: '${avgMinutesPerDay}m',
                      trend: null,
                      trendUp: true,
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendUp 
                        ? const Color(0xFF07E092).withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final insight = _generateInsight(records);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.insightOfDay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  insight['title']!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight['description']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        insight['tip']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _generateInsight(List<TimeTrackingRecord> records) {
    final now = DateTime.now();
    final todayRecords = records.where((r) => _isSameDay(r.startTime, now)).toList();
    final yesterdayRecords = records.where((r) => 
        _isSameDay(r.startTime, now.subtract(const Duration(days: 1)))).toList();
    
    final todayMinutes = todayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60);
    final yesterdayMinutes = yesterdayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60);

    if (todayMinutes == 0) {
      return {
        'title': '🌅 Comece seu dia produtivo!',
        'description': 'Você ainda não registrou nenhuma atividade hoje. Que tal começar com uma sessão de foco?',
        'tip': 'Comece com 25 minutos de foco usando o Pomodoro',
      };
    }

    if (todayMinutes > yesterdayMinutes && yesterdayMinutes > 0) {
      final increase = ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100).round();
      return {
        'title': '🚀 Você está arrasando!',
        'description': 'Hoje você já trabalhou $increase% a mais que ontem. Continue assim!',
        'tip': 'Mantenha o ritmo, mas lembre de fazer pausas',
      };
    }

    if (todayMinutes >= 120) {
      return {
        'title': '⭐ Excelente produtividade!',
        'description': 'Você já acumulou ${todayMinutes ~/ 60}h ${todayMinutes % 60}m de foco hoje. Impressionante!',
        'tip': 'Considere fazer uma pausa maior para recarregar',
      };
    }

    // Encontrar atividade mais frequente
    final activityCount = <String, int>{};
    for (final record in records) {
      activityCount[record.activityName] = (activityCount[record.activityName] ?? 0) + 1;
    }
    
    if (activityCount.isNotEmpty) {
      final topActivity = activityCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      return {
        'title': '📊 Seu foco principal',
        'description': 'Você tem dedicado mais tempo a "${topActivity.key}" com ${topActivity.value} sessões.',
        'tip': 'Diversifique suas atividades para um desenvolvimento equilibrado',
      };
    }

    return {
      'title': '💪 Continue focado!',
      'description': 'Cada minuto de foco te aproxima dos seus objetivos.',
      'tip': 'Defina metas claras para o dia',
    };
  }

  /// Widget de análise de sentimento das notas usando HuggingFace
  Widget _buildNoteSentimentAnalysis() {
    final sentimentAsync = ref.watch(sentimentSummaryProvider);
    
    return sentimentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.totalNotes == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9B51E0).withValues(alpha: 0.15),
                  const Color(0xFFE91E63).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF9B51E0).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9B51E0).withValues(alpha: 0.3),
                            const Color(0xFFE91E63).withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_alt,
                        color: Color(0xFF9B51E0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Análise de Sentimento',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Baseado em ${summary.totalNotes} notas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSentimentColor(summary.overallMood).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        summary.overallMood,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSentimentColor(summary.overallMood),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Sentiment bars
                Row(
                  children: [
                    Expanded(
                      child: _buildSentimentBar(
                        emoji: '😊',
                        label: 'Positivo',
                        percent: summary.positivePercentage,
                        color: const Color(0xFF07E092),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSentimentBar(
                        emoji: '😐',
                        label: 'Neutro',
                        percent: summary.neutralPercentage,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSentimentBar(
                        emoji: '😔',
                        label: 'Negativo',
                        percent: summary.negativePercentage,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                
                if (summary.topicsFrequency.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tópicos mais mencionados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.topicsFrequency.entries.take(5).map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B51E0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${topic.key} (${topic.value})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9B51E0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF9B51E0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Análise feita com IA (HuggingFace)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentimentBar({
    required String emoji,
    required String label,
    required double percent,
    required Color color,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 6,
              width: (percent / 100) * 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${percent.round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
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

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Positivo':
        return const Color(0xFF07E092);
      case 'Negativo':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFFFFA726);
    }
  }

  Widget _buildTimeDistributionChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        
        // Agrupar por atividade
        final activityTime = <String, int>{};
        for (final record in filteredRecords) {
          activityTime[record.activityName] = 
              (activityTime[record.activityName] ?? 0) + record.durationInSeconds ~/ 60;
        }

        final sortedActivities = activityTime.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final topActivities = sortedActivities.take(5).toList();
        final totalMinutes = activityTime.values.fold<int>(0, (a, b) => a + b);

        if (topActivities.isEmpty) {
          return const SizedBox.shrink();
        }

        final colors = [
          const Color(0xFF9B51E0),
          const Color(0xFFFFA556),
          const Color(0xFFFD5B71),
          const Color(0xFF07E092),
          Theme.of(context).colorScheme.secondary,
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.timeDistribution,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.pie_chart,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Donut Chart
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        data: topActivities.map((e) => e.value.toDouble()).toList(),
                        colors: colors,
                        total: totalMinutes.toDouble(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${totalMinutes ~/ 60}h',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${totalMinutes % 60}m',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Legend
                ...topActivities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final percentage = totalMinutes > 0 
                      ? (activity.value / totalMinutes * 100).round() 
                      : 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activity.key,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${activity.value}m',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors[index % colors.length].withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors[index % colors.length],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeActivityChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final now = DateTime.now();
        
        // Configuração baseada no período selecionado
        int daysCount;
        String chartTitle;
        List<String> labels;
        
        switch (_selectedPeriod) {
          case 0: // Semana
            daysCount = 7;
            chartTitle = l10n.atividadeSemanal;
            labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
            break;
          case 1: // Mês
            daysCount = 30;
            chartTitle = l10n.monthlyActivity;
            labels = List.generate(30, (i) => (i + 1).toString());
            break;
          case 2: // Ano
            daysCount = 12; // Mostrar por meses
            chartTitle = l10n.yearlyActivity;
            labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
            break;
          default:
            daysCount = 7;
            chartTitle = l10n.atividadeSemanal;
            labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
        }
        
        // Calcular dados baseados no período
        List<double> chartData;
        
        if (_selectedPeriod == 2) {
          // Para ano, agrupa por mês
          chartData = List.generate(12, (i) {
            final monthRecords = records.where((r) {
              return r.startTime.year == now.year && r.startTime.month == (i + 1);
            });
            return monthRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60) / 60;
          });
        } else {
          // Para semana e mês, mostra por dia
          chartData = List<double>.generate(daysCount, (i) {
            final day = now.subtract(Duration(days: daysCount - 1 - i));
            final dayRecords = records.where((r) => _isSameDay(r.startTime, day));
            return dayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60) / 60;
          });
        }

        final maxValue = chartData.isNotEmpty ? chartData.reduce((a, b) => a > b ? a : b) : 0.0;
        final chartMax = maxValue > 0 ? maxValue : 4.0;
        
        // Calcular tendência
        double avgFirst = 0;
        double avgSecond = 0;
        if (chartData.length >= 2) {
          final half = chartData.length ~/ 2;
          avgFirst = chartData.sublist(0, half).fold<double>(0, (a, b) => a + b) / half;
          avgSecond = chartData.sublist(half).fold<double>(0, (a, b) => a + b) / (chartData.length - half);
        }
        final isRising = avgSecond > avgFirst;
        final trendPercent = avgFirst > 0 ? ((avgSecond - avgFirst) / avgFirst * 100).abs().round() : 0;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(chartTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isRising ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRising ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: isRising ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRising ? '+$trendPercent%' : '-$trendPercent%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isRising ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 200,
                  child: _selectedPeriod == 1 
                    // Para mês, usa linha em vez de barras
                    ? CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: _LineChartPainter(
                          data: chartData,
                          maxValue: chartMax,
                          color: Theme.of(context).colorScheme.primary,
                          gradientColors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(chartData.length, (index) {
                          final isToday = _selectedPeriod == 0 && index == chartData.length - 1;
                          final isCurrent = _selectedPeriod == 2 && index == now.month - 1;
                          final highlight = isToday || isCurrent;
                          final value = chartData[index];
                          final barHeight = chartMax > 0 ? (value / chartMax) * 150 : 0.0;
                          
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_selectedPeriod != 1) // Não mostra valores para mês (muitos dias)
                                  Text(
                                    value > 0 ? '${value.toStringAsFixed(1)}h' : '',
                                    style: TextStyle(
                                      fontSize: _selectedPeriod == 2 ? 10 : 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: _selectedPeriod == 2 ? 20 : 32,
                                  height: barHeight > 8 ? barHeight : 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: highlight
                                          ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]
                                          : [
                                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  labels[_selectedPeriod == 0 
                                    ? now.subtract(Duration(days: chartData.length - 1 - index)).weekday % 7
                                    : index],
                                  style: TextStyle(
                                    fontSize: _selectedPeriod == 2 ? 10 : 12,
                                    fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                                    color: highlight 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopActivities() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        
        // Agrupar por atividade
        final activityStats = <String, Map<String, dynamic>>{};
        for (final record in filteredRecords) {
          if (!activityStats.containsKey(record.activityName)) {
            activityStats[record.activityName] = {
              'minutes': 0,
              'sessions': 0,
              'iconCode': record.iconCode,
            };
          }
          activityStats[record.activityName]!['minutes'] += record.durationInSeconds ~/ 60;
          activityStats[record.activityName]!['sessions'] += 1;
        }

        final sortedActivities = activityStats.entries.toList()
          ..sort((a, b) => (b.value['minutes'] as int).compareTo(a.value['minutes'] as int));
        
        final topActivities = sortedActivities.take(4).toList();

        if (topActivities.isEmpty) {
          return const SizedBox.shrink();
        }

        final colors = [
          const Color(0xFF9B51E0),
          const Color(0xFFFFA556),
          const Color(0xFFFD5B71),
          const Color(0xFF07E092),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.topActivities,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...topActivities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                final minutes = activity.value['minutes'] as int;
                final sessions = activity.value['sessions'] as int;
                final hours = minutes ~/ 60;
                final remainingMinutes = minutes % 60;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          OdysseyIcons.fromCodePoint(activity.value['iconCode'] as int),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$sessions sessões',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hours > 0 ? '${hours}h ${remainingMinutes}m' : '${remainingMinutes}m',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: colors[index % colors.length],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 14,
                                color: index == 0 
                                    ? Theme.of(context).colorScheme.tertiary 
                                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodCorrelation() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
    final moodRepo = ref.watch(syncedMoodRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, timeBox, _) {
        return ValueListenableBuilder(
          valueListenable: moodRepo.box.listenable(),
          builder: (context, moodBox, _) {
            final records = timeBox.values.cast<TimeTrackingRecord>().toList();
            final moods = moodBox.values.cast<MoodRecord>().toList();
            final filteredRecords = _filterByPeriod(records, DateTime.now());
            
            // Agrupar produtividade por humor
            final happyMinutes = <int>[];
            final neutralMinutes = <int>[];
            final sadMinutes = <int>[];
            
            for (final mood in moods) {
              final moodDate = mood.date;
              final dayRecords = filteredRecords.where((r) => _isSameDay(r.startTime, moodDate));
              final totalMinutes = dayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60);
              
              if (mood.score >= 4) {
                happyMinutes.add(totalMinutes);
              } else if (mood.score >= 2) {
                neutralMinutes.add(totalMinutes);
              } else {
                sadMinutes.add(totalMinutes);
              }
            }
            
            final avgHappy = happyMinutes.isNotEmpty ? happyMinutes.reduce((a, b) => a + b) ~/ happyMinutes.length : 0;
            final avgNeutral = neutralMinutes.isNotEmpty ? neutralMinutes.reduce((a, b) => a + b) ~/ neutralMinutes.length : 0;
            final avgSad = sadMinutes.isNotEmpty ? sadMinutes.reduce((a, b) => a + b) ~/ sadMinutes.length : 0;
            
            final productivityDiff = avgHappy > 0 && avgSad > 0 ? ((avgHappy - avgSad) / avgSad * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                          Text(
                            AppLocalizations.of(context)!.moodVsProductivity,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCorrelationItem(
                    emoji: '😊',
                            label: AppLocalizations.of(context)!.happyDays,
                            value: '${avgHappy ~/ 60}.${(avgHappy % 60).toString().padLeft(2, '0')}h média',
                    color: const Color(0xFF07E092),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCorrelationItem(
                    emoji: '😐',
                            label: AppLocalizations.of(context)!.neutralDays,
                            value: '${avgNeutral ~/ 60}.${(avgNeutral % 60).toString().padLeft(2, '0')}h média',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCorrelationItem(
                    emoji: '😔',
                            label: AppLocalizations.of(context)!.difficultDays,
                            value: '${avgSad ~/ 60}.${(avgSad % 60).toString().padLeft(2, '0')}h média',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                              productivityDiff > 0
                                  ? AppLocalizations.of(context)!.moreProductiveOnGoodDays(productivityDiff)
                                  : AppLocalizations.of(context)!.notEnoughData,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
          },
        );
      },
    );
  }

  Widget _buildCorrelationItem({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.achievements,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  value: '7',
                  label: AppLocalizations.of(context)!.consecutiveDays,
                  subtitle: AppLocalizations.of(context)!.yourRecord(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  icon: Icons.stars,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  value: '12',
                  label: AppLocalizations.of(context)!.totalHours,
                  subtitle: AppLocalizations.of(context)!.thisWeekLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.nextAchievement,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.focusMaster,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '20h de foco total • Faltam 8h',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: 0.6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.tertiary),
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<TimeTrackingRecord> _filterByPeriod(List<TimeTrackingRecord> records, DateTime now) {
    switch (_selectedPeriod) {
      case 0: // Week
        final weekAgo = now.subtract(const Duration(days: 7));
        return records.where((r) => r.startTime.isAfter(weekAgo)).toList();
      case 1: // Month
        final monthAgo = now.subtract(const Duration(days: 30));
        return records.where((r) => r.startTime.isAfter(monthAgo)).toList();
      case 2: // Year
        final yearAgo = now.subtract(const Duration(days: 365));
        return records.where((r) => r.startTime.isAfter(yearAgo)).toList();
      default:
        return records;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Gráfico de calor (heatmap) de produtividade por hora/dia
  Widget _buildProductivityHeatmap() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        
        // Criar matriz 7x24 (dias x horas)
        final heatmapData = List.generate(7, (_) => List.filled(24, 0));
        
        for (final record in filteredRecords) {
          final dayOfWeek = record.startTime.weekday % 7;
          final hour = record.startTime.hour;
          heatmapData[dayOfWeek][hour] += record.durationInSeconds ~/ 60;
        }
        
        final maxValue = heatmapData.expand((row) => row).reduce((a, b) => a > b ? a : b);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
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
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.heatMap,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.hourByDay,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Heatmap grid
                SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      // Labels dos dias
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                            .map((d) => SizedBox(
                                  width: 20,
                                  height: 18,
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(width: 4),
                      // Grid
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(24, (hour) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(7, (day) {
                                  final value = heatmapData[day][hour];
                                  final intensity = maxValue > 0 ? value / maxValue : 0.0;
                                  
                                  return Tooltip(
                                    message: '${_getDayName(day, context)} ${hour}h: ${value}min',
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 14,
                                      height: 18,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: _getHeatmapColor(intensity, context),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Labels das horas
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Row(
                      children: [0, 6, 12, 18, 23].map((h) => SizedBox(
                        width: 60,
                        child: Text(
                          '${h}h',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Legenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.less, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(i / 4, context),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.more, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDayName(int day, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = [
      l10n.weekdaySun,
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
    ];
    return days[day];
  }

  Color _getHeatmapColor(double intensity, BuildContext context) {
    if (intensity <= 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
    
    final baseColor = Theme.of(context).colorScheme.primary;
    return Color.lerp(
      baseColor.withValues(alpha: 0.1),
      baseColor,
      intensity,
    )!;
  }

  /// Gráfico de correlação entre atividades e humor
  Widget _buildActivityCorrelationChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
    final moodRepo = ref.watch(syncedMoodRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, timeBox, _) {
        return ValueListenableBuilder(
          valueListenable: moodRepo.box.listenable(),
          builder: (context, moodBox, _) {
            final records = timeBox.values.cast<TimeTrackingRecord>().toList();
            final moods = moodBox.values.cast<MoodRecord>().toList();
            final filteredRecords = _filterByPeriod(records, DateTime.now());
            
            // Agrupar atividades por humor
            final activityMoodScore = <String, List<int>>{};
            
            for (final record in filteredRecords) {
              final dayMoods = moods.where((m) => _isSameDay(m.date, record.startTime));
              if (dayMoods.isNotEmpty) {
                activityMoodScore.putIfAbsent(record.activityName, () => []);
                activityMoodScore[record.activityName]!.add(dayMoods.first.score);
              }
            }
            
            // Calcular média de humor por atividade
            final activityAvgMood = activityMoodScore.entries.map((e) {
              final avg = e.value.isNotEmpty ? e.value.reduce((a, b) => a + b) / e.value.length : 0.0;
              return MapEntry(e.key, avg);
            }).toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            final topActivities = activityAvgMood.take(5).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF9B51E0).withValues(alpha: 0.2),
                                const Color(0xFFE91E63).withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.scatter_plot,
                            color: Color(0xFF9B51E0),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.activityMoodCorrelation,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.whichActivitiesImproveYourMood,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    if (topActivities.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            AppLocalizations.of(context)!.notEnoughData,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ...topActivities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        final moodScore = activity.value;
                        final moodPercent = (moodScore / 5 * 100).round();
                        final colors = [
                          const Color(0xFF07E092),
                          const Color(0xFF00BCD4),
                          const Color(0xFF9B51E0),
                          const Color(0xFFFFA726),
                          const Color(0xFFE91E63),
                        ];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _getMoodEmoji(moodScore),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$moodPercent%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors[index % colors.length],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length].withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: 8,
                                    width: MediaQuery.of(context).size.width * 0.7 * (moodScore / 5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [colors[index % colors.length], colors[index % colors.length].withValues(alpha: 0.7)],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMoodEmoji(double score) {
    if (score >= 4.5) return '😄';
    if (score >= 3.5) return '😊';
    if (score >= 2.5) return '😐';
    if (score >= 1.5) return '😔';
    return '😢';
  }

  /// Análise de tendências temporais com linhas de tendência
  Widget _buildTrendAnalysisChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        final now = DateTime.now();
        
        // Calcular tendência dos últimos dias baseado no período
        final daysToShow = _selectedPeriod == 0 ? 7 : (_selectedPeriod == 1 ? 30 : 90);
        
        final dailyData = List.generate(daysToShow, (i) {
          final day = now.subtract(Duration(days: daysToShow - 1 - i));
          final dayRecords = filteredRecords.where((r) => _isSameDay(r.startTime, day));
          return dayRecords.fold<int>(0, (sum, r) => sum + r.durationInSeconds ~/ 60) / 60.0;
        });
        
        // Calcular linha de tendência (regressão linear simples)
        double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        for (int i = 0; i < dailyData.length; i++) {
          sumX += i;
          sumY += dailyData[i];
          sumXY += i * dailyData[i];
          sumX2 += i * i;
        }
        final n = dailyData.length.toDouble();
        final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        final intercept = (sumY - slope * sumX) / n;
        
        final trendData = List.generate(dailyData.length, (i) => slope * i + intercept);
        
        final isPositiveTrend = slope > 0;
        final trendPercent = (slope * 100).abs().toStringAsFixed(1);
        
        final maxValue = [...dailyData, ...trendData].reduce((a, b) => a > b ? a : b);
        final chartMax = maxValue > 0 ? maxValue * 1.2 : 4.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
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
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00BCD4).withValues(alpha: 0.2),
                                const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.show_chart,
                            color: Color(0xFF00BCD4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.trendAnalysis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.predictionBasedOnHistory,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPositiveTrend ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: isPositiveTrend ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositiveTrend ? '+' : '-'}$trendPercent%/dia',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPositiveTrend ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _TrendChartPainter(
                      data: dailyData,
                      trendData: trendData,
                      maxValue: chartMax,
                      dataColor: Theme.of(context).colorScheme.primary,
                      trendColor: isPositiveTrend ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Legenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 20, height: 3, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.realData, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Container(width: 20, height: 3, decoration: BoxDecoration(color: isPositiveTrend ? const Color(0xFF07E092) : Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.trend, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Gráfico de radar para comparação de categorias de atividades
  Widget _buildCategoryRadarChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        
        // Agrupar por categoria (simplificado - usar nome da atividade como categoria)
        final categoryMinutes = <String, int>{};
        for (final record in filteredRecords) {
          final category = _getCategoryFromActivity(record.activityName, context);
          categoryMinutes[category] = (categoryMinutes[category] ?? 0) + record.durationInSeconds ~/ 60;
        }
        
        // Pegar top 6 categorias
        final sortedCategories = categoryMinutes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sortedCategories.take(6).toList();
        
        if (topCategories.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final maxMinutes = topCategories.isNotEmpty ? topCategories.first.value : 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B35).withValues(alpha: 0.2),
                            const Color(0xFFFFD93D).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hexagon_outlined,
                        color: Color(0xFFFF6B35),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.categoriesRadar,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _RadarChartPainter(
                        data: topCategories.map((e) => e.value / maxMinutes).toList(),
                        labels: topCategories.map((e) => e.key).toList(),
                        color: Theme.of(context).colorScheme.primary,
                        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de categorias com tempo
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final hours = category.value ~/ 60;
                    final mins = category.value % 60;
                    final colors = [
                      const Color(0xFF9B51E0),
                      const Color(0xFF00BCD4),
                      const Color(0xFF07E092),
                      const Color(0xFFFFA726),
                      const Color(0xFFE91E63),
                      const Color(0xFF3F51B5),
                    ];
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors[index % colors.length].withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${category.key}: ${hours > 0 ? '${hours}h ' : ''}${mins}m',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors[index % colors.length],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCategoryFromActivity(String activityName, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = activityName.toLowerCase();
    if (name.contains('estud') || name.contains('study') || name.contains('learn')) return l10n.categoryStudyLabel;
    if (name.contains('trabalh') || name.contains('work') || name.contains('meeting')) return l10n.categoryWorkLabel;
    if (name.contains('exerc') || name.contains('gym') || name.contains('sport')) return l10n.categoryExerciseLabel;
    if (name.contains('leit') || name.contains('read') || name.contains('book')) return l10n.categoryReadingLabel;
    if (name.contains('medit') || name.contains('yoga') || name.contains('relax')) return l10n.categoryWellnessLabel;
    if (name.contains('cod') || name.contains('program') || name.contains('dev')) return l10n.categoryProgrammingLabel;
    return l10n.categoryOtherLabel;
  }

  /// Análise de ciclos e padrões de comportamento
  Widget _buildBehaviorPatternsChart() {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final filteredRecords = _filterByPeriod(records, DateTime.now());
        
        // Analisar padrões por período do dia
        int morningMinutes = 0; // 6-12
        int afternoonMinutes = 0; // 12-18
        int eveningMinutes = 0; // 18-24
        int nightMinutes = 0; // 0-6
        
        for (final record in filteredRecords) {
          final hour = record.startTime.hour;
          final duration = record.durationInSeconds ~/ 60;
          
          if (hour >= 6 && hour < 12) {
            morningMinutes += duration;
          } else if (hour >= 12 && hour < 18) {
            afternoonMinutes += duration;
          } else if (hour >= 18 && hour < 24) {
            eveningMinutes += duration;
          } else {
            nightMinutes += duration;
          }
        }
        
        final totalMinutes = morningMinutes + afternoonMinutes + eveningMinutes + nightMinutes;
        
        final l10n = AppLocalizations.of(context)!;
        
        // Encontrar melhor período
        String bestPeriod = l10n.periodMorning;
        int bestMinutes = morningMinutes;
        if (afternoonMinutes > bestMinutes) {
          bestPeriod = l10n.periodAfternoon;
          bestMinutes = afternoonMinutes;
        }
        if (eveningMinutes > bestMinutes) {
          bestPeriod = l10n.periodEvening;
          bestMinutes = eveningMinutes;
        }
        if (nightMinutes > bestMinutes) {
          bestPeriod = l10n.periodNight;
          bestMinutes = nightMinutes;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.behaviorPatterns,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.analysisByTimeOfDay,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Gráfico circular de períodos
                Row(
                  children: [
                    // Gráfico
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _PeriodDonutPainter(
                          morning: morningMinutes.toDouble(),
                          afternoon: afternoonMinutes.toDouble(),
                          evening: eveningMinutes.toDouble(),
                          night: nightMinutes.toDouble(),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bestPeriod,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.mostActive,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Legendas
                    Expanded(
                      child: Column(
                        children: [
                          _buildPeriodItem('🌅 ${l10n.periodMorning}', morningMinutes, totalMinutes, const Color(0xFFFFA726)),
                          const SizedBox(height: 8),
                          _buildPeriodItem('☀️ ${l10n.periodAfternoon}', afternoonMinutes, totalMinutes, const Color(0xFF00BCD4)),
                          const SizedBox(height: 8),
                          _buildPeriodItem('🌙 ${l10n.periodEvening}', eveningMinutes, totalMinutes, const Color(0xFF9B51E0)),
                          const SizedBox(height: 8),
                          _buildPeriodItem('🌃 ${l10n.periodNight}', nightMinutes, totalMinutes, const Color(0xFF3F51B5)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Insight
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          totalMinutes > 0
                              ? AppLocalizations.of(context)!.moreProductiveDuringPeriod((bestMinutes / totalMinutes * 100).round().toString(), bestPeriod)
                              : AppLocalizations.of(context)!.notEnoughData,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodItem(String label, int minutes, int total, Color color) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final percent = total > 0 ? (minutes / total * 100).round() : 0;
    
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          hours > 0 ? '${hours}h ${mins}m' : '${mins}m',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final double total;

  _DonutChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = total > 0 ? (data[i] / total) * 2 * math.pi : 0.0;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.05, // Small gap between segments
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

// Line Chart Painter para visualização de dados ao longo do mês
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;
  final List<Color> gradientColors;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxValue * size.height * 0.85);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    // Draw gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw dots on data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < data.length; i += (data.length ~/ 6).clamp(1, data.length)) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxValue * size.height * 0.85);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

// Trend Chart Painter com linha de tendência
class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final List<double> trendData;
  final double maxValue;
  final Color dataColor;
  final Color trendColor;

  _TrendChartPainter({
    required this.data,
    required this.trendData,
    required this.maxValue,
    required this.dataColor,
    required this.trendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = dataColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw data line
    final dataPaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final dataPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - (data[i] / maxValue * size.height * 0.9);
      
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    canvas.drawPath(dataPath, dataPaint);
    
    // Draw trend line
    final trendPaint = Paint()
      ..color = trendColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final trendPath = Path();
    for (int i = 0; i < trendData.length; i++) {
      final x = i * size.width / (trendData.length - 1);
      final y = size.height - (trendData[i].clamp(0, maxValue) / maxValue * size.height * 0.9);
      
      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }
    }
    canvas.drawPath(trendPath, trendPaint);
    
    // Draw dots on trend endpoints
    final dotPaint = Paint()
      ..color = trendColor
      ..style = PaintingStyle.fill;
    
    final startY = size.height - (trendData.first.clamp(0, maxValue) / maxValue * size.height * 0.9);
    final endY = size.height - (trendData.last.clamp(0, maxValue) / maxValue * size.height * 0.9);
    
    canvas.drawCircle(Offset(0, startY), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, endY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.trendData != trendData;
  }
}

// Radar Chart Painter
class _RadarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final Color labelColor;

  _RadarChartPainter({
    required this.data,
    required this.labels,
    required this.color,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    final sides = data.length;
    final angle = 2 * math.pi / sides;

    // Draw background circles
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      final path = Path();
      for (int j = 0; j <= sides; j++) {
        final x = center.dx + r * math.cos(angle * j - math.pi / 2);
        final y = center.dy + r * math.sin(angle * j - math.pi / 2);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i <= sides; i++) {
      final index = i % sides;
      final value = data[index].clamp(0, 1);
      final r = radius * value;
      final x = center.dx + r * math.cos(angle * index - math.pi / 2);
      final y = center.dy + r * math.sin(angle * index - math.pi / 2);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    
    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);
    
    // Stroke
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, strokePaint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < sides; i++) {
      final value = data[i].clamp(0, 1);
      final r = radius * value;
      final x = center.dx + r * math.cos(angle * i - math.pi / 2);
      final y = center.dy + r * math.sin(angle * i - math.pi / 2);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i < sides; i++) {
      final labelRadius = radius + 25;
      final x = center.dx + labelRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + labelRadius * math.sin(angle * i - math.pi / 2);
      
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          color: labelColor,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      
      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// Period Donut Painter para análise de padrões
class _PeriodDonutPainter extends CustomPainter {
  final double morning;
  final double afternoon;
  final double evening;
  final double night;

  _PeriodDonutPainter({
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    
    final total = morning + afternoon + evening + night;
    if (total <= 0) return;
    
    final data = [morning, afternoon, evening, night];
    final colors = [
      const Color(0xFFFFA726),
      const Color(0xFF00BCD4),
      const Color(0xFF9B51E0),
      const Color(0xFF3F51B5),
    ];
    
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PeriodDonutPainter oldDelegate) {
    return oldDelegate.morning != morning ||
           oldDelegate.afternoon != afternoon ||
           oldDelegate.evening != evening ||
           oldDelegate.night != night;
  }
}

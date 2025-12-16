import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/analytics/presentation/analytics_screen.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/language_learning/presentation/language_learning_screen.dart';
import 'package:odyssey/src/features/news/presentation/news_screen.dart';
import 'package:odyssey/src/features/diary/presentation/pages/diary_page.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/subscription/presentation/ad_banner_widget.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import '../data/gamification_repository.dart';
import '../domain/user_stats.dart';
import '../domain/user_skills.dart';
import 'dart:math' as math;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Box? _gamificationBox;
  UserStats? _stats;
  bool _isLoading = true;
  String _userName = 'Praticante';
  late List<SkillCategory> _skillCategories;
  int _selectedTabIndex = 0;

  // Showcase keys
  final GlobalKey _showcaseStats = GlobalKey();
  final GlobalKey _showcaseSkills = GlobalKey();
  final GlobalKey _showcaseProgress = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _skillCategories = getDefaultSkillCategories();
    _loadStats();
  }

  Future<void> _loadStats() async {
    _gamificationBox = await Hive.openBox('gamification');
    final repo = GamificationRepository(_gamificationBox!);

    // Carregar categorias com progresso salvo do repositório
    _skillCategories = repo.getSkillCategories();

    setState(() {
      _stats = repo.getStats();
      _userName =
          _gamificationBox?.get('userName', defaultValue: 'Praticante') ??
          'Praticante';
      _isLoading = false;
    });
    _animController.forward();
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.profile);
    _animController.dispose();
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcaseStats, _showcaseSkills, _showcaseProgress];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.profile,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.profile, keys);
  }

  void _startTour() {
    final keys = [_showcaseStats, _showcaseSkills, _showcaseProgress];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.profile, keys);
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats!;
    final colors = Theme.of(context).colorScheme;

    return FirstTimeDetector(
      screenId: 'profile_screen',
      category: FeatureCategory.gamification,
      tourId: null, // No tour defined yet for profile
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header minimalista
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      // Avatar compacto
                      _buildCompactAvatar(stats, colors),
                      const SizedBox(width: 14),
                      // Nome e título
                      Expanded(child: _buildUserInfo(stats, colors)),
                      // Ações
                      _buildHeaderAction(
                        Icons.bar_chart_rounded,
                        () => _navigateToScreen(const AnalyticsScreen()),
                        colors,
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderAction(
                        Icons.settings_rounded,
                        () => _navigateToScreen(const SettingsScreen()),
                        colors,
                      ),
                    ],
                  ),
                ),
              ),

              // XP Card compacto
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildXPCard(stats, colors),
                ),
              ),

              // Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildStatsGrid(stats, colors),
                ),
              ),

              // Tab Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: _buildModernTabSelector(colors),
                ),
              ),

              // Tab Content
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildTabContent(stats, colors),
                ),
              ),

              // Banner de anúncio (usuários free)
              const SliverToBoxAdapter(
                child: AdBannerWidget(
                  margin: EdgeInsets.fromLTRB(20, 16, 20, 16),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAvatar(UserStats stats, ColorScheme colors) {
    final settings = ref.watch(settingsProvider);
    final avatarPath = settings.avatarPath;
    final displayName = settings.userName.isNotEmpty
        ? settings.userName
        : _userName;
    final currentTitle = UserTitles.getTitleForXP(stats.totalXP);

    return GestureDetector(
      onTap: () => _navigateToScreen(const SettingsScreen()),
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              image: avatarPath != null
                  ? DecorationImage(
                      image: FileImage(File(avatarPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarPath == null
                ? Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
          // Badge de nível
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '${stats.level}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          // Emoji do título
          Positioned(
            top: -4,
            right: -4,
            child: Text(
              currentTitle.emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(UserStats stats, ColorScheme colors) {
    final settings = ref.watch(settingsProvider);
    final displayName = settings.userName.isNotEmpty
        ? settings.userName
        : _userName;
    final currentTitle = UserTitles.getTitleForXP(stats.totalXP);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          currentTitle.name,
          style: TextStyle(
            fontSize: 13,
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(
    IconData icon,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
      ),
    );
  }

  double _calculateTitleProgress(int currentXP, int nextTitleXP) {
    int previousTitleXP = 0;
    for (final title in UserTitles.titles) {
      if (title.xpRequired >= nextTitleXP) break;
      previousTitleXP = title.xpRequired;
    }
    final range = nextTitleXP - previousTitleXP;
    final progress = currentXP - previousTitleXP;
    return range > 0 ? (progress / range).clamp(0.0, 1.0) : 0.0;
  }

  Widget _buildXPCard(UserStats stats, ColorScheme colors) {
    final currentTitle = UserTitles.getTitleForXP(stats.totalXP);
    final nextTitle = UserTitles.getNextTitle(stats.totalXP);
    final progress = nextTitle != null
        ? _calculateTitleProgress(stats.totalXP, nextTitle.xpRequired)
        : 1.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animProgress = Curves.easeOutCubic.transform(
          _animController.value,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.12),
                colors.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${(stats.totalXP * animProgress).round()}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                            Text(
                              ' XP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        if (nextTitle != null)
                          Text(
                            '${nextTitle.xpRequired - stats.totalXP} para ${nextTitle.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            'Nível máximo! 🎉',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Streak
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.currentStreak}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (nextTitle != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress * animProgress,
                    backgroundColor: colors.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(UserStats stats, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.mood_rounded,
            value: '${stats.moodRecordsCount}',
            label: 'Registros',
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.check_circle_rounded,
            value: '${stats.tasksCompleted}',
            label: 'Tarefas',
            color: const Color(0xFF07E092),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.timer_rounded,
            value: '${stats.pomodoroSessions}',
            label: 'Focos',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.emoji_events_rounded,
            value: '${stats.unlockedBadges.length}',
            label: 'Badges',
            color: colors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabSelector(ColorScheme colors) {
    final tabs = [
      (AppLocalizations.of(context)!.overview, Icons.dashboard_rounded),
      (AppLocalizations.of(context)!.development, Icons.trending_up_rounded),
      (AppLocalizations.of(context)!.achievements, Icons.emoji_events_rounded),
      (AppLocalizations.of(context)!.tools, Icons.apps_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final (title, icon) = entry.value;
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedTabIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(UserStats stats, ColorScheme colors) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(stats, colors);
      case 1:
        return _buildDevelopmentTab(colors);
      case 2:
        return _buildAchievementsTab(stats, colors);
      case 3:
        return _buildToolsTab(colors);
      default:
        return _buildOverviewTab(stats, colors);
    }
  }

  // ============= TAB 0: VISÃO GERAL =============
  Widget _buildOverviewTab(UserStats stats, ColorScheme colors) {
    return Padding(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Activity Chart
          _buildWeeklyActivityChart(colors),
          const SizedBox(height: 16),

          // Maslow Quote
          _buildMaslowQuote(colors),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart(ColorScheme colors) {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values.cast<TimeTrackingRecord>().toList();
        final weekData = _getWeeklyData(records);
        final maxValue = weekData.reduce((a, b) => a > b ? a : b);
        final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final now = DateTime.now();
        final todayIndex = now.weekday - 1;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.atividadeSemanal,
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
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final value = weekData[index];
                    final heightPercent = maxValue > 0
                        ? (value / maxValue)
                        : 0.0;
                    final isToday = index == todayIndex;

                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final animProgress = Curves.easeOutCubic.transform(
                          _animController.value,
                        );
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (value > 0)
                              Text(
                                '${value.round()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: Duration(
                                milliseconds: 400 + (index * 60),
                              ),
                              width: 28,
                              height: math.max(
                                4,
                                60 * heightPercent * animProgress,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isToday
                                      ? [
                                          colors.primary,
                                          colors.primary.withValues(alpha: 0.7),
                                        ]
                                      : [
                                          colors.primary.withValues(alpha: 0.4),
                                          colors.primary.withValues(alpha: 0.2),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? colors.primary
                                    : colors.onSurfaceVariant.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<double> _getWeeklyData(List<TimeTrackingRecord> records) {
    final now = DateTime.now();
    final weekData = List<double>.filled(7, 0);

    for (final record in records) {
      final diff = now.difference(record.startTime).inDays;
      if (diff >= 0 && diff < 7) {
        final dayIndex = 6 - diff;
        weekData[dayIndex] += record.durationInSeconds / 60;
      }
    }
    return weekData;
  }

  Widget _buildMaslowQuote(ColorScheme colors) {
    final randomCategory =
        _skillCategories[DateTime.now().day % _skillCategories.length];
    final quote = MaslowQuotes.getQuoteByCategory(randomCategory.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            randomCategory.color.withValues(alpha: 0.12),
            randomCategory.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: randomCategory.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: randomCategory.color,
                size: 22,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: randomCategory.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  randomCategory.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: randomCategory.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.inspiradoEmMaslow,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ============= TAB 1: DESENVOLVIMENTO =============
  Widget _buildDevelopmentTab(ColorScheme colors) {
    // Calcular progresso total
    final totalSkills = _skillCategories.fold<int>(
      0,
      (sum, c) => sum + c.skills.length,
    );
    final totalXP = _skillCategories.fold<int>(
      0,
      (sum, c) =>
          sum +
          c.skills.fold<int>(
            0,
            (s, skill) =>
                s + skill.currentXP + ((skill.currentLevel - 1) * 100),
          ),
    );
    final avgLevel =
        _skillCategories.fold<double>(
          0,
          (sum, c) =>
              sum +
              c.skills.fold<double>(0, (s, skill) => s + skill.currentLevel),
        ) /
        totalSkills;

    return Padding(
      key: const ValueKey('development'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          _buildDevelopmentOverview(colors, totalXP, avgLevel, totalSkills),
          const SizedBox(height: 16),

          // Pirâmide de Maslow Visual
          _buildMaslowPyramid(colors),
          const SizedBox(height: 20),

          // Skill Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.areasDeDesenvolvimento,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_skillCategories.length} áreas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._skillCategories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSkillCategoryCard(category, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentOverview(
    ColorScheme colors,
    int totalXP,
    double avgLevel,
    int totalSkills,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yourDevelopmentProgress,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Baseado na Psicologia Humanista de Maslow',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  icon: Icons.auto_awesome,
                  label: 'XP Total',
                  value: '$totalXP',
                  color: colors.primary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewStat(
                  icon: Icons.trending_up_rounded,
                  label: 'Nível Médio',
                  value: avgLevel.toStringAsFixed(1),
                  color: colors.tertiary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewStat(
                  icon: Icons.stars_rounded,
                  label: 'Skills',
                  value: '$totalSkills',
                  color: colors.secondary,
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMaslowPyramid(ColorScheme colors) {
    final levels = [
      ('Auto-realização', const Color(0xFFFF9800), 0.35),
      ('Estima', const Color(0xFF9C27B0), 0.5),
      ('Amor/Pertencimento', const Color(0xFFE91E63), 0.65),
      ('Segurança', const Color(0xFF2196F3), 0.8),
      ('Fisiológico', const Color(0xFF4CAF50), 1.0),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.08),
            colors.tertiary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.hierarquiaDeMaslow,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...levels.asMap().entries.map((entry) {
            final index = entry.key;
            final (name, color, widthFactor) = entry.value;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: widthFactor),
              duration: Duration(milliseconds: 400 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillCategoryCard(SkillCategory category, ColorScheme colors) {
    final avgLevel =
        category.skills.fold<int>(0, (sum, s) => sum + s.currentLevel) ~/
        category.skills.length;
    final totalXP = category.skills.fold<int>(0, (sum, s) => sum + s.currentXP);
    final avgProgress =
        category.skills.fold<double>(0, (sum, s) => sum + s.progress) /
        category.skills.length;

    return GestureDetector(
      onTap: () => _showSkillCategoryDetail(category),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.levelAbbrev(avgLevel.toString()),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: category.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
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
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: avgProgress,
                backgroundColor: category.color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(category.color),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 10),
            // Skills preview
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: category.skills.take(4).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: category.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkillCategoryDetail(SkillCategory category) {
    HapticFeedback.lightImpact();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(category.icon, color: category.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.habilidades,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...category.skills.map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSkillDetailItem(skill, category.color, colors),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: category.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.maslowInsight.isNotEmpty
                            ? category.maslowInsight
                            : MaslowQuotes.getQuoteByCategory(category.id),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface,
                          fontStyle: FontStyle.italic,
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
  }

  Widget _buildSkillDetailItem(Skill skill, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  skill.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.levelAbbrev(skill.currentLevel.toString()),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            skill.description,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: skill.progress,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${skill.currentXP}/${skill.xpForNextLevel}',
                style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= TAB 2: CONQUISTAS =============
  Widget _buildAchievementsTab(UserStats stats, ColorScheme colors) {
    final unlockedCount = stats.unlockedBadges.length;
    final totalCount = allBadges.length;

    // Group badges by type
    final streakBadges = allBadges
        .where((b) => b.type == BadgeType.streak)
        .toList();
    final moodBadges = allBadges
        .where((b) => b.type == BadgeType.mood)
        .toList();
    final taskBadges = allBadges
        .where((b) => b.type == BadgeType.tasks)
        .toList();
    final timeBadges = allBadges
        .where((b) => b.type == BadgeType.time)
        .toList();
    final pomoBadges = allBadges
        .where((b) => b.type == BadgeType.pomodoro)
        .toList();
    final specialBadges = allBadges
        .where((b) => b.type == BadgeType.special)
        .toList();

    return Padding(
      key: const ValueKey('achievements'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.tertiary.withValues(alpha: 0.15),
                  colors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: colors.tertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlockedCount de $totalCount',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.conquistasDesbloqueadas,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalCount > 0
                              ? unlockedCount / totalCount
                              : 0,
                          backgroundColor: colors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(colors.tertiary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Badge sections
          _buildBadgeSection('🔥 Sequência', streakBadges, stats, colors),
          _buildBadgeSection('😊 Humor', moodBadges, stats, colors),
          _buildBadgeSection('✅ Tarefas', taskBadges, stats, colors),
          _buildBadgeSection('⏱️ Tempo', timeBadges, stats, colors),
          _buildBadgeSection('🍅 Pomodoro', pomoBadges, stats, colors),
          _buildBadgeSection('⭐ Especiais', specialBadges, stats, colors),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(
    String title,
    List<GameBadge> badges,
    UserStats stats,
    ColorScheme colors,
  ) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges.map((badge) {
            final isUnlocked = stats.unlockedBadges.contains(badge.id);
            return _buildBadgeItem(badge, isUnlocked, colors);
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBadgeItem(GameBadge badge, bool isUnlocked, ColorScheme colors) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, isUnlocked),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnlocked
              ? colors.tertiary.withValues(alpha: 0.1)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: isUnlocked
              ? Border.all(color: colors.tertiary.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Text(
              badge.icon,
              style: TextStyle(
                fontSize: 24,
                color: isUnlocked
                    ? null
                    : colors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
                color: isUnlocked
                    ? colors.onSurface
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked)
              Icon(
                Icons.lock_outline,
                size: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(GameBadge badge, bool isUnlocked) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? colors.tertiary.withValues(alpha: 0.15)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(badge.icon, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF07E092).withValues(alpha: 0.1)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock,
                    size: 16,
                    color: isUnlocked
                        ? const Color(0xFF07E092)
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked
                        ? AppLocalizations.of(context)!.unlocked
                        : AppLocalizations.of(context)!.locked,
                    style: TextStyle(
                      color: isUnlocked
                          ? const Color(0xFF07E092)
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============= TAB 3: FERRAMENTAS =============
  Widget _buildToolsTab(ColorScheme colors) {
    return Padding(
      key: const ValueKey('tools'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildToolCard(
            Icons.book_rounded,
            'Diário',
            'Escreva seus pensamentos',
            const Color(0xFF8B5CF6),
            () => _navigateToScreen(const DiaryPage()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.translate_rounded,
            'Idiomas',
            'Aprenda idiomas',
            const Color(0xFF14B8A6),
            () => _navigateToScreen(const LanguageLearningScreen()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.menu_book_rounded,
            AppLocalizations.of(context)!.library,
            AppLocalizations.of(context)!.booksAndReading,
            const Color(0xFF9B51E0),
            () => _navigateToScreen(const LibraryScreen()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.sticky_note_2_rounded,
            AppLocalizations.of(context)!.notes,
            AppLocalizations.of(context)!.notesAndIdeas,
            const Color(0xFFFFA556),
            () => _navigateToScreen(const NotesScreen()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.check_circle_outline_rounded,
            AppLocalizations.of(context)!.tasks,
            AppLocalizations.of(context)!.todoList,
            const Color(0xFF07E092),
            () => _navigateToScreen(const TasksScreen()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.analytics_rounded,
            AppLocalizations.of(context)!.analytics,
            AppLocalizations.of(context)!.detailedStatistics,
            const Color(0xFF00B4D8),
            () => _navigateToScreen(const AnalyticsScreen()),
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            Icons.newspaper_rounded,
            AppLocalizations.of(context)!.news,
            AppLocalizations.of(context)!.articlesAndNews,
            const Color(0xFFFF6B6B),
            () => _navigateToScreen(const NewsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  _LevelRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

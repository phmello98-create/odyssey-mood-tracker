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
// import 'package:odyssey/src/features/subscription/presentation/ad_banner_widget.dart'; // Desabilitado no Linux
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;
import '../data/gamification_repository.dart';
import '../domain/user_stats.dart';
import '../domain/user_skills.dart';
import '../domain/goal_suggestions.dart';
import 'widgets/profile_widgets.dart';
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
  bool _showCompletedGoals = false;
  bool _showGoalSuggestions = false;

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
              // Header elegante
              SliverToBoxAdapter(child: _buildProfileHeader(stats, colors)),

              // Stats Carousel horizontal
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildStatsCarousel(stats),
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

              // Banner de anúncio (desabilitado no Linux)
              // const SliverToBoxAdapter(
              //   child: AdBannerWidget(
              //     margin: EdgeInsets.fromLTRB(20, 16, 20, 16),
              //   ),
              // ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  /// Header elegante do perfil
  Widget _buildProfileHeader(UserStats stats, ColorScheme colors) {
    final settings = ref.watch(settingsProvider);
    final displayName = settings.userName.isNotEmpty
        ? settings.userName
        : _userName;

    // Título: usar o selecionado ou baseado em XP
    String titleName;
    String titleEmoji;
    if (settings.selectedTitleIndex >= 0 &&
        settings.selectedTitleIndex < UserTitles.titles.length) {
      final selected = UserTitles.titles[settings.selectedTitleIndex];
      if (selected.xpRequired <= stats.totalXP) {
        titleName = selected.name;
        titleEmoji = selected.emoji;
      } else {
        final auto = UserTitles.getTitleForXP(stats.totalXP);
        titleName = auto.name;
        titleEmoji = auto.emoji;
      }
    } else {
      final auto = UserTitles.getTitleForXP(stats.totalXP);
      titleName = auto.name;
      titleEmoji = auto.emoji;
    }

    // Calcular XP para níveis
    final xpForCurrentLevel = UserStats.totalXPForLevel(stats.level);
    final xpForNextLevel = UserStats.totalXPForLevel(stats.level + 1);

    // Calcular mana (baseado na energia/foco disponível)
    final mana = (stats.wellnessScore * 1.5).clamp(0, 150).round();
    const maxMana = 150;

    return ProfileHeader(
      userName: displayName,
      avatarPath: settings.avatarPath,
      bannerPath: settings.bannerPath,
      title: titleName,
      titleEmoji: titleEmoji,
      bio: stats.bio,
      currentMood: stats.currentMoodEmoji,
      level: stats.level,
      currentXP: stats.totalXP,
      xpForCurrentLevel: xpForCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      currentMana: mana,
      maxMana: maxMana,
      daysSinceJoined: stats.daysSinceJoined,
      streak: stats.currentStreak,
      onEditProfile: () => _showEditProfileDialog(colors),
      onSettings: () => _navigateToScreen(const SettingsScreen()),
      onAvatarTap: () => _showEditProfileDialog(colors),
      onBannerTap: () => _showBannerOptions(colors),
    );
  }

  /// Stats carousel horizontal
  Widget _buildStatsCarousel(UserStats stats) {
    return StatsCarousel(
      moodRecords: stats.moodRecordsCount,
      tasksCompleted: stats.tasksCompleted,
      pomodoroSessions: stats.pomodoroSessions,
      timeTrackedMinutes: stats.timeTrackedMinutes,
      habitsCompleted: stats.habitsCompleted,
      notesCreated: stats.notesCreated,
    );
  }

  /// Dialog para editar o perfil (foto, nome, bio, título)
  void _showEditProfileDialog(ColorScheme colors) {
    final settings = ref.read(settingsProvider);
    final bioController = TextEditingController(text: _stats?.bio ?? '');
    final nameController = TextEditingController(text: settings.userName);

    // Obter títulos desbloqueados baseado no XP
    final totalXP = _stats?.totalXP ?? 0;
    final unlockedTitles = UserTitles.titles
        .where((t) => t.xpRequired <= totalXP)
        .toList();

    int selectedTitleIdx = settings.selectedTitleIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  '✏️ Editar Perfil',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),

                // === FOTO E BANNER ===
                Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () => _showAvatarOptions(colors),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: settings.avatarPath != null
                                ? FileImage(File(settings.avatarPath!))
                                : null,
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: settings.avatarPath == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: colors.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Banner button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showBannerOptions(colors),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            image: settings.bannerPath != null
                                ? DecorationImage(
                                    image: FileImage(
                                      File(settings.bannerPath!),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: settings.bannerPath == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.panorama,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      Text(
                                        'Adicionar Banner',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // === NOME ===
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // === BIO ===
                TextField(
                  controller: bioController,
                  maxLines: 2,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: const Icon(Icons.edit_note),
                    hintText: 'Conte um pouco sobre você...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // === TÍTULO ===
                Text(
                  'Título',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        unlockedTitles.length + 1, // +1 para opção "Auto"
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Opção Auto (usa XP)
                        final isSelected = selectedTitleIdx == -1;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedTitleIdx = -1);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.2)
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: colors.primary)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🎯',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Auto',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final title = unlockedTitles[index - 1];
                      final titleIndex = UserTitles.titles.indexOf(title);
                      final isSelected = selectedTitleIdx == titleIndex;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedTitleIdx = titleIndex);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.2)
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: colors.primary)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                title.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                title.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // === SALVAR ===
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      // Salvar nome
                      if (nameController.text.isNotEmpty) {
                        await ref
                            .read(settingsProvider.notifier)
                            .setUserName(nameController.text);
                      }

                      // Salvar bio
                      final repo = GamificationRepository(_gamificationBox!);
                      await repo.updateBio(bioController.text);

                      // Salvar título selecionado
                      await ref
                          .read(settingsProvider.notifier)
                          .setSelectedTitleIndex(selectedTitleIdx);

                      setState(() {
                        _stats = repo.getStats();
                      });

                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opções de avatar
  void _showAvatarOptions(ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.primary),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(settingsProvider.notifier)
                    .setAvatarFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.secondary),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(settingsProvider.notifier).setAvatarFromCamera();
              },
            ),
            if (ref.read(settingsProvider).avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(settingsProvider.notifier).removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Opções de banner
  void _showBannerOptions(ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.primary),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(settingsProvider.notifier)
                    .setBannerFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.secondary),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(settingsProvider.notifier).setBannerFromCamera();
              },
            ),
            if (ref.read(settingsProvider).bannerPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(settingsProvider.notifier).removeBanner();
                },
              ),
          ],
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

  /// Tab selector responsivo - scroll horizontal no mobile
  /// Seguindo @ui-specialist: MediaQuery para responsividade
  Widget _buildModernTabSelector(ColorScheme colors) {
    final tabs = [
      (AppLocalizations.of(context)!.overview, Icons.dashboard_rounded),
      (AppLocalizations.of(context)!.development, Icons.trending_up_rounded),
      (AppLocalizations.of(context)!.achievements, Icons.emoji_events_rounded),
      (AppLocalizations.of(context)!.tools, Icons.apps_rounded),
      ('Metas', Icons.flag_rounded),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400; // Mobile estreito

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isNarrow
          // Mobile: Scroll horizontal
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: tabs.asMap().entries.map((entry) {
                  return _buildTabItem(
                    entry.key,
                    entry.value.$1,
                    entry.value.$2,
                    colors,
                    minWidth: 72,
                  );
                }).toList(),
              ),
            )
          // Desktop/Tablet: Expandido
          : Row(
              children: tabs.asMap().entries.map((entry) {
                return Expanded(
                  child: _buildTabItem(
                    entry.key,
                    entry.value.$1,
                    entry.value.$2,
                    colors,
                  ),
                );
              }).toList(),
            ),
    );
  }

  /// Item individual do tab selector
  Widget _buildTabItem(
    int index,
    String title,
    IconData icon,
    ColorScheme colors, {
    double? minWidth,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: minWidth != null
            ? BoxConstraints(minWidth: minWidth)
            : null,
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: minWidth != null ? 12 : 0,
        ),
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
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
      case 4:
        return _buildGoalsTab(stats, colors);
      default:
        return _buildOverviewTab(stats, colors);
    }
  }

  // ============= TAB 4: METAS =============
  Widget _buildGoalsTab(UserStats stats, ColorScheme colors) {
    final activeGoals = stats.personalGoals
        .where((g) => !g.isCompleted)
        .toList();
    final completedGoals = stats.personalGoals
        .where((g) => g.isCompleted)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com resumo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primaryContainer,
                  colors.primaryContainer.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suas Metas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeGoals.length} ativas • ${completedGoals.length} concluídas',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (stats.personalGoals.isNotEmpty)
                      IconButton(
                        onPressed: _clearAllGoals,
                        icon: Icon(Icons.delete_sweep, color: colors.error),
                        tooltip: 'Limpar Todas',
                      ),
                    FilledButton.icon(
                      onPressed: () => _showAddGoalDialog(colors),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nova'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metas Ativas
          if (activeGoals.isEmpty)
            _buildEmptyGoalsState(colors)
          else ...[
            Text(
              'Metas Ativas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...activeGoals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExcludeSemantics(
                  child: goal.hasBanner
                      ? PremiumGoalCardWithBanner(
                          goal: goal,
                          onIncrement: () => _incrementGoal(
                            goal,
                            delta: goal.trackingType == 'percentage' ? 10 : 1,
                          ),
                          onDelete: () => _deleteGoal(goal.id),
                          showActions: true,
                          onTap: () => _showGoalPopup(goal, colors),
                        )
                      : PremiumGoalCard(
                          goal: goal,
                          onIncrement: () => _incrementGoal(
                            goal,
                            delta: goal.trackingType == 'percentage' ? 10 : 1,
                          ),
                          onDelete: () => _deleteGoal(goal.id),
                          showActions: true,
                          onTap: () => _showGoalPopup(goal, colors),
                        ),
                ),
              ),
            ),
          ],

          // Toggle para metas concluídas
          if (completedGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () =>
                  setState(() => _showCompletedGoals = !_showCompletedGoals),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF51CF66),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Metas Concluídas (${completedGoals.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showCompletedGoals ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  ...completedGoals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCompletedGoalCard(goal, colors),
                    ),
                  ),
                ],
              ),
              crossFadeState: _showCompletedGoals
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Estado vazio de metas - expandido com sugestões
  /// Seguindo @ui-specialist: Layout responsivo e atraente
  Widget _buildEmptyGoalsState(ColorScheme colors) {
    return Column(
      children: [
        // Card principal expandido
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryContainer.withValues(alpha: 0.4),
                colors.secondaryContainer.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Ícone animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Comece Sua Jornada!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Defina metas pessoais para acompanhar seu progresso e alcançar seus sonhos! 🚀',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showAddGoalDialog(colors),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar Meta'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(
                        () => _showGoalSuggestions = !_showGoalSuggestions,
                      );
                    },
                    icon: Icon(
                      _showGoalSuggestions
                          ? Icons.keyboard_arrow_up
                          : Icons.lightbulb_outline,
                    ),
                    label: Text(_showGoalSuggestions ? 'Fechar' : 'Sugestões'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Toggle de sugestões
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildGoalSuggestions(colors),
          crossFadeState: _showGoalSuggestions
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  /// Grid de sugestões de metas
  Widget _buildGoalSuggestions(ColorScheme colors) {
    final suggestions = getRandomSuggestions(6);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sugestões de Metas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSuggestionCard(suggestion, colors),
            ),
          ),
        ],
      ),
    );
  }

  /// Card de sugestão de meta com banner
  Widget _buildSuggestionCard(GoalSuggestion suggestion, ColorScheme colors) {
    return GestureDetector(
      onTap: () => _addSuggestedGoal(suggestion),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (suggestion.bannerUrl != null)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      suggestion.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.primaryContainer,
                        child: Center(
                          child: Text(
                            suggestion.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colors.surfaceContainerHighest,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colors.surface.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getCategoryEmoji(suggestion.category),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getCategoryName(suggestion.category),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Emoji
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        suggestion.emoji,
                        style: const TextStyle(fontSize: 22),
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
                          suggestion.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Add button
                  IconButton(
                    onPressed: () => _addSuggestedGoal(suggestion),
                    icon: const Icon(Icons.add_circle_outline),
                    color: colors.primary,
                    tooltip: 'Adicionar Meta',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Adiciona uma meta sugerida
  void _addSuggestedGoal(GoalSuggestion suggestion) {
    HapticFeedback.mediumImpact();

    final goal = suggestion.toPersonalGoal();
    final repo = ref.read(gamificationRepositoryProvider);
    repo.addPersonalGoal(goal);

    setState(() {
      _stats = repo.getStats();
      _showGoalSuggestions = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(suggestion.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Meta "${suggestion.title}" adicionada!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF51CF66),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Retorna emoji da categoria
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'financial':
        return '💰';
      case 'travel':
        return '✈️';
      case 'education':
        return '📚';
      case 'health':
        return '💪';
      case 'career':
        return '💼';
      case 'personal':
        return '⭐';
      default:
        return '🎯';
    }
  }

  /// Retorna nome da categoria
  String _getCategoryName(String category) {
    switch (category) {
      case 'financial':
        return 'Financeiro';
      case 'travel':
        return 'Viagem';
      case 'education':
        return 'Educação';
      case 'health':
        return 'Saúde';
      case 'career':
        return 'Carreira';
      case 'personal':
        return 'Pessoal';
      default:
        return 'Meta';
    }
  }

  Widget _buildCompletedGoalCard(PersonalGoal goal, ColorScheme colors) {
    final goalColor = _getGoalColorForType(goal.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF51CF66).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getGoalEmojiForType(goal.type),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF51CF66),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.targetValue}/${goal.targetValue} • Concluída',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteGoal(goal.id),
            icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colors.error.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  // ============= TAB 0: VISÃO GERAL =============
  Widget _buildOverviewTab(UserStats stats, ColorScheme colors) {
    // Calcular scores para breakdown
    final streakScore = ((stats.currentStreak / 30) * 100)
        .clamp(0, 100)
        .round();
    final moodScore = (stats.averageMoodScore * 20).clamp(0, 100).round();
    final activityScore = stats.recentMoods.isNotEmpty ? 80 : 30;
    final engagementScore = (stats.unlockedBadges.length / 10 * 100)
        .clamp(0, 100)
        .round();

    // Calcular comparações temporais (simulado por enquanto)
    final dailyChange = stats.currentStreak > 0 ? 15.0 : -5.0;
    final weeklyChange = stats.wellnessScore > 50 ? 8.0 : -3.0;
    final monthlyChange = stats.moodRecordsCount > 10 ? 12.0 : 0.0;

    // Gerar atividades recentes (baseado em dados reais)
    final recentActivities = _getRecentActivities(stats);

    return Padding(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wellness Score elegante com breakdown
          WellnessScoreCard(
            score: stats.wellnessScore,
            emoji: stats.wellnessEmoji,
            description: stats.wellnessDescription,
            animation: _animController,
            streakScore: streakScore,
            moodScore: moodScore,
            activityScore: activityScore,
            engagementScore: engagementScore,
          ),
          const SizedBox(height: 20),

          // Comparação temporal
          TemporalComparisonCard(
            dailyChange: dailyChange,
            weeklyChange: weeklyChange,
            monthlyChange: monthlyChange,
          ),
          const SizedBox(height: 20),

          // Timeline de atividades recentes
          ActivityTimeline(activities: recentActivities),
          const SizedBox(height: 20),

          // Metas pessoais
          ExcludeSemantics(
            child: PersonalGoalsCard(
              goals: stats.personalGoals,
              colors: colors,
              onAddGoal: () => _showAddGoalDialog(colors),
              onGoalTap: (goal) => _showGoalPopup(goal, colors),
              onIncrementGoal: (goal) => _incrementGoal(
                goal,
                delta: goal.trackingType == 'percentage' ? 10 : 1,
              ),
              onDeleteGoal: (goal) => _deleteGoal(goal.id),
              onViewAll: () => setState(() => _selectedTabIndex = 4),
            ),
          ),
          const SizedBox(height: 20),

          // Weekly Activity Chart
          _buildWeeklyActivityChart(colors),
          const SizedBox(height: 16),

          // Quote inspiracional
          _buildMaslowQuote(colors),
        ],
      ),
    );
  }

  /// Gera lista de atividades recentes baseado nas estatísticas
  List<ActivityItem> _getRecentActivities(UserStats stats) {
    final activities = <ActivityItem>[];
    final now = DateTime.now();

    // Adicionar atividades baseado nos dados
    if (stats.moodRecordsCount > 0) {
      activities.add(
        ActivityItem(
          emoji: stats.currentMoodEmoji ?? '😊',
          title: 'Check-in de Humor',
          subtitle: 'Total: ${stats.moodRecordsCount}',
          timestamp: now.subtract(const Duration(hours: 2)),
          color: const Color(0xFFFFA94D),
          type: 'mood',
        ),
      );
    }

    if (stats.tasksCompleted > 0) {
      activities.add(
        ActivityItem(
          emoji: '✅',
          title: 'Tarefa Concluída',
          subtitle: 'Total: ${stats.tasksCompleted}',
          timestamp: now.subtract(const Duration(hours: 4)),
          color: const Color(0xFF51CF66),
          type: 'task',
        ),
      );
    }

    if (stats.pomodoroSessions > 0) {
      activities.add(
        ActivityItem(
          emoji: '🍅',
          title: 'Pomodoro',
          subtitle: '${stats.pomodoroSessions} sessões',
          timestamp: now.subtract(const Duration(hours: 6)),
          color: const Color(0xFFFF6B6B),
          type: 'pomodoro',
        ),
      );
    }

    if (stats.habitsCompleted > 0) {
      activities.add(
        ActivityItem(
          emoji: '🎯',
          title: 'Hábito Completo',
          subtitle: 'Total: ${stats.habitsCompleted}',
          timestamp: now.subtract(const Duration(hours: 8)),
          color: const Color(0xFFB197FC),
          type: 'habit',
        ),
      );
    }

    if (stats.notesCreated > 0) {
      activities.add(
        ActivityItem(
          emoji: '📝',
          title: 'Nota Criada',
          subtitle: 'Total: ${stats.notesCreated}',
          timestamp: now.subtract(const Duration(days: 1)),
          color: const Color(0xFF339AF0),
          type: 'note',
        ),
      );
    }

    return activities;
  }

  /// Dialog para adicionar nova meta pessoal
  void _showAddGoalDialog(ColorScheme colors) {
    final titleController = TextEditingController();
    String selectedType = 'tasks';
    int targetValue = 10;
    String trackingType = 'counter';

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                '🎯 Nova Meta',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título da meta',
                  hintText: 'Ex: Completar 10 tarefas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo de meta:',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _goalTypeChip(
                    'tasks',
                    '✅ Tarefas',
                    selectedType,
                    (v) => setModalState(() => selectedType = v),
                    colors,
                  ),
                  _goalTypeChip(
                    'mood',
                    '😊 Humor',
                    selectedType,
                    (v) => setModalState(() => selectedType = v),
                    colors,
                  ),
                  _goalTypeChip(
                    'focus',
                    '⏱️ Foco',
                    selectedType,
                    (v) => setModalState(() => selectedType = v),
                    colors,
                  ),
                  _goalTypeChip(
                    'habits',
                    '🎯 Hábitos',
                    selectedType,
                    (v) => setModalState(() => selectedType = v),
                    colors,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Técnica de Acompanhamento:',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildTrackingTypeSelector(
                (newType) => setModalState(() {
                  trackingType = newType;
                  if (trackingType == 'percentage') targetValue = 100;
                  if (trackingType == 'checklist') targetValue = 1;
                }),
                trackingType,
                colors,
              ),

              if (trackingType != 'checklist') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      trackingType == 'percentage'
                          ? 'Progresso: '
                          : 'Quantidade: ',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Slider(
                        value: targetValue.toDouble(),
                        min: trackingType == 'percentage' ? 100 : 1,
                        max: trackingType == 'percentage' ? 100 : 100,
                        divisions: trackingType == 'percentage' ? 1 : 99,
                        label: '$targetValue',
                        onChanged: trackingType == 'percentage'
                            ? null
                            : (v) =>
                                  setModalState(() => targetValue = v.round()),
                      ),
                    ),
                    Text(
                      '$targetValue${trackingType == 'percentage' ? '%' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final goal = PersonalGoal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      targetValue: trackingType == 'checklist'
                          ? 1
                          : targetValue,
                      type: selectedType,
                      trackingType: trackingType,
                      createdAt: DateTime.now(),
                    );

                    final repo = GamificationRepository(_gamificationBox!);
                    await repo.addPersonalGoal(goal);

                    if (mounted) {
                      Navigator.pop(context);
                      // Adiar o setState para evitar conflito com a animação de fechar semantics
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _stats = repo.getStats();
                          });
                        }
                      });
                    }
                  },
                  child: const Text('Criar Meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingTypeSelector(
    Function(String) onSelect,
    String currentType,
    ColorScheme colors,
  ) {
    final types = [
      ('counter', 'Contagem', Icons.add_rounded),
      ('checklist', 'Checklist', Icons.check_box_rounded),
      ('percentage', 'Porcentagem', Icons.percent_rounded),
    ];

    return Row(
      children: types.map((type) {
        final isSelected = currentType == type.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(type.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type.$3,
                    size: 20,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _goalTypeChip(
    String type,
    String label,
    String selected,
    Function(String) onSelect,
    ColorScheme colors,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : colors.onSurfaceVariant,
          ),
        ),
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
    return _SwipeableQuoteWidget(categories: _skillCategories, colors: colors);
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
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    // Categorias organizadas
    final categories = [
      _BadgeCategory(
        '🔥',
        'Sequência',
        allBadges.where((b) => b.type == BadgeType.streak).toList(),
        const Color(0xFFFF6B35),
      ),
      _BadgeCategory(
        '😊',
        'Humor',
        allBadges.where((b) => b.type == BadgeType.mood).toList(),
        const Color(0xFFFFA94D),
      ),
      _BadgeCategory(
        '✅',
        'Tarefas',
        allBadges.where((b) => b.type == BadgeType.tasks).toList(),
        const Color(0xFF51CF66),
      ),
      _BadgeCategory(
        '⏱️',
        'Foco',
        allBadges.where((b) => b.type == BadgeType.time).toList(),
        const Color(0xFF339AF0),
      ),
      _BadgeCategory(
        '🍅',
        'Pomodoro',
        allBadges.where((b) => b.type == BadgeType.pomodoro).toList(),
        const Color(0xFFFF6B6B),
      ),
      _BadgeCategory(
        '⭐',
        'Especiais',
        allBadges.where((b) => b.type == BadgeType.special).toList(),
        const Color(0xFFB197FC),
      ),
    ];

    return Padding(
      key: const ValueKey('achievements'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header elegante
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.12),
                  colors.tertiary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Ícone grande
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coleção de Conquistas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$unlockedCount de $totalCount desbloqueadas',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Porcentagem
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de progresso
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categorias de badges
          ...categories.map(
            (category) => _buildBadgeCategorySection(category, stats, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCategorySection(
    _BadgeCategory category,
    UserStats stats,
    ColorScheme colors,
  ) {
    if (category.badges.isEmpty) return const SizedBox.shrink();

    final unlockedInCategory = category.badges
        .where((b) => stats.unlockedBadges.contains(b.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da categoria
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(category.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    '$unlockedInCategory/${category.badges.length}',
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
        // Grid de badges
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: category.badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = category.badges[index];
              final isUnlocked = stats.unlockedBadges.contains(badge.id);
              return _buildBadgeCard(badge, isUnlocked, category.color, colors);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBadgeCard(
    GameBadge badge,
    bool isUnlocked,
    Color categoryColor,
    ColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showBadgeDetails(badge, isUnlocked);
      },
      child: Container(
        width: 95,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnlocked
              ? categoryColor.withValues(alpha: 0.12)
              : colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? categoryColor.withValues(alpha: 0.3)
                : colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? categoryColor.withValues(alpha: 0.2)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 20,
                      color: isUnlocked
                          ? null
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Nome
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
                  color: isUnlocked
                      ? colors.onSurface
                      : colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Lock icon
              if (!isUnlocked) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 10,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
        ),
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

  // ========================================
  // GOAL POPUP FUNCTIONALITY
  // ========================================

  void _showGoalPopup(PersonalGoal goal, ColorScheme colors) {
    final goalColor = _getGoalColorForType(goal.type);
    final safeProgress = goal.targetValue > 0
        ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0)
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: goalColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getGoalEmojiForType(goal.type),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getGoalTypeName(goal.type),
                          style: TextStyle(fontSize: 12, color: goalColor),
                        ),
                      ],
                    ),
                  ),
                  if (goal.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 20),

              // Progress
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: safeProgress,
                            strokeWidth: 5,
                            backgroundColor: goalColor.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation(goalColor),
                          ),
                          Text(
                            '${(safeProgress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: goalColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${goal.currentValue} / ${goal.targetValue}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            goal.trackingType == 'percentage'
                                ? 'porcentagem'
                                : 'concluídos',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🪙 +50', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),

              // Controls
              if (!goal.isCompleted) ...[
                const SizedBox(height: 16),
                _buildSimpleControls(goal, goalColor, colors, ctx),
              ],

              const SizedBox(height: 12),

              // Delete button
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteGoal(goal.id);
                },
                icon: Icon(Icons.delete_outline, color: colors.error, size: 18),
                label: Text(
                  'Excluir Meta',
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleControls(
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext ctx,
  ) {
    if (goal.trackingType == 'checklist') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _incrementGoal(goal, delta: 1);
            });
          },
          icon: const Icon(Icons.check),
          label: const Text('Marcar como Concluída'),
          style: FilledButton.styleFrom(backgroundColor: goalColor),
        ),
      );
    }

    // Counter or Percentage controls
    final buttons = goal.trackingType == 'percentage'
        ? ['+5%', '+10%', '+25%']
        : ['+1', '+5', '+10'];
    final deltas = goal.trackingType == 'percentage' ? [5, 10, 25] : [1, 5, 10];

    return Row(
      children: List.generate(
        buttons.length,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _incrementGoal(goal, delta: deltas[i]);
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: goalColor,
                side: BorderSide(color: goalColor.withAlpha(100)),
              ),
              child: Text(buttons[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBtn(
    String label,
    int delta,
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext ctx,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          Navigator.pop(ctx);

          // Pequeno atraso para estabilizar a árvore de widgets após o pop
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;

          await _incrementGoal(goal, delta: delta);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: goalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: goalColor.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: goalColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistControl(
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext ctx,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        Navigator.pop(ctx);
        // Pequeno atraso para o Navigator fechar semântica
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _incrementGoal(goal, delta: 1);
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [goalColor, goalColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: goalColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Marcar como Concluída',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageControls(
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext ctx,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _buildQuickBtn('+5%', 5, goal, goalColor, colors, ctx),
            const SizedBox(width: 8),
            _buildQuickBtn('+10%', 10, goal, goalColor, colors, ctx),
            const SizedBox(width: 8),
            _buildQuickBtn('+25%', 25, goal, goalColor, colors, ctx),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickBtn(
          'Definir como 100%',
          100 - goal.currentValue,
          goal,
          goalColor,
          colors,
          ctx,
        ),
      ],
    );
  }

  Widget _buildCounterControls(
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext ctx,
  ) {
    return Row(
      children: [
        _buildQuickBtn('+1', 1, goal, goalColor, colors, ctx),
        const SizedBox(width: 10),
        _buildQuickBtn('+5', 5, goal, goalColor, colors, ctx),
        const SizedBox(width: 10),
        _buildQuickBtn('+10', 10, goal, goalColor, colors, ctx),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                _showCustomIncrementDialog(goal, goalColor, colors, ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goalColor, goalColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: goalColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomIncrementDialog(
    PersonalGoal goal,
    Color goalColor,
    ColorScheme colors,
    BuildContext popupCtx,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Adicionar Progresso'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade',
            hintText: 'Ex: 3',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(controller.text) ?? 0;
              if (value > 0) {
                Navigator.pop(dialogCtx);
                Navigator.pop(popupCtx);
                await Future.delayed(const Duration(milliseconds: 100));
                if (!mounted) return;
                await _incrementGoal(goal, delta: value);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementGoal(PersonalGoal goal, {int delta = 1}) async {
    if (_gamificationBox == null) return;
    final repo = GamificationRepository(_gamificationBox!);
    await repo.incrementGoalProgress(goal.id, delta: delta);
    HapticFeedback.mediumImpact();
    final updatedStats = repo.getStats();

    if (mounted) {
      setState(() => _stats = updatedStats);
    }

    // Mostrar feedback visual
    final updatedGoal = updatedStats.personalGoals.firstWhere(
      (g) => g.id == goal.id,
      orElse: () => goal,
    );

    if (mounted) {
      final emoji = _getGoalEmojiForType(goal.type);
      final colors = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  updatedGoal.isCompleted
                      ? '🎉 Meta concluída! +50 tokens'
                      : '+$delta • ${_getFormattedProgress(updatedGoal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: updatedGoal.isCompleted
              ? const Color(0xFF51CF66)
              : colors.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(
            milliseconds: updatedGoal.isCompleted ? 3000 : 1500,
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _getFormattedProgress(PersonalGoal goal) {
    if (goal.trackingType == 'percentage') {
      return '${goal.currentValue}% de ${goal.targetValue}%';
    }
    return '${goal.currentValue}/${goal.targetValue}';
  }

  Future<void> _deleteGoal(String goalId) async {
    if (_gamificationBox == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Meta'),
        content: const Text('Tem certeza que deseja excluir esta meta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (result == true) {
      final repo = GamificationRepository(_gamificationBox!);
      await repo.removePersonalGoal(goalId);
      setState(() => _stats = repo.getStats());
    }
  }

  Future<void> _clearAllGoals() async {
    if (_gamificationBox == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Todas as Metas'),
        content: const Text(
          'Tem certeza que deseja excluir TODAS as suas metas? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );
    if (result == true) {
      final repo = GamificationRepository(_gamificationBox!);
      await repo.clearAllGoals();
      setState(() => _stats = repo.getStats());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas as metas foram removidas')),
        );
      }
    }
  }

  Color _getGoalColorForType(String type) {
    switch (type) {
      case 'mood':
        return const Color(0xFFFFA94D);
      case 'tasks':
        return const Color(0xFF51CF66);
      case 'focus':
        return const Color(0xFF339AF0);
      case 'habits':
        return const Color(0xFFB197FC);
      default:
        return const Color(0xFF868E96);
    }
  }

  String _getGoalEmojiForType(String type) {
    switch (type) {
      case 'mood':
        return '😊';
      case 'tasks':
        return '✅';
      case 'focus':
        return '⏱️';
      case 'habits':
        return '🎯';
      default:
        return '🌟';
    }
  }

  String _getGoalTypeName(String type) {
    switch (type) {
      case 'mood':
        return 'Humor';
      case 'tasks':
        return 'Tarefas';
      case 'focus':
        return 'Foco';
      case 'habits':
        return 'Hábitos';
      default:
        return 'Geral';
    }
  }
}

// ============================================================
// SWIPEABLE QUOTE WIDGET - Frases com swipe e setas
// ============================================================

class _SwipeableQuoteWidget extends StatefulWidget {
  final List<dynamic> categories;
  final ColorScheme colors;

  const _SwipeableQuoteWidget({required this.categories, required this.colors});

  @override
  State<_SwipeableQuoteWidget> createState() => _SwipeableQuoteWidgetState();
}

class _SwipeableQuoteWidgetState extends State<_SwipeableQuoteWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Começa em uma página aleatória
    _currentPage = DateTime.now().minute % widget.categories.length;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNext() {
    if (_currentPage < widget.categories.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final quote = MaslowQuotes.getQuoteByCategory(category.id);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withValues(alpha: 0.12),
                      category.color.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: category.color,
                          size: 20,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        quote,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Navigation arrows and dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left arrow
            GestureDetector(
              onTap: _currentPage > 0 ? _goToPrevious : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _currentPage > 0
                      ? colors.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: _currentPage > 0
                      ? colors.onSurfaceVariant
                      : colors.outlineVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.categories.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPage ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? colors.primary
                        : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right arrow
            GestureDetector(
              onTap: _currentPage < widget.categories.length - 1
                  ? _goToNext
                  : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _currentPage < widget.categories.length - 1
                      ? colors.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _currentPage < widget.categories.length - 1
                      ? colors.onSurfaceVariant
                      : colors.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Classe auxiliar para categorias de badges
class _BadgeCategory {
  final String emoji;
  final String name;
  final List<GameBadge> badges;
  final Color color;

  _BadgeCategory(this.emoji, this.name, this.badges, this.color);
}

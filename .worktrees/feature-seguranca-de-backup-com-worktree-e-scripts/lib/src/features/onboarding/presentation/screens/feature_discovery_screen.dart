import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import 'package:odyssey/src/features/analytics/presentation/analytics_screen.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import '../onboarding_providers.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';

/// Tela de Feed de Discovery com dicas e truques
class FeatureDiscoveryScreen extends ConsumerStatefulWidget {
  const FeatureDiscoveryScreen({super.key});

  @override
  ConsumerState<FeatureDiscoveryScreen> createState() => _FeatureDiscoveryScreenState();
}

class _FeatureDiscoveryScreenState extends ConsumerState<FeatureDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FeatureCategory? _selectedCategory;

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Navega para a tela correspondente à rota
  void _navigateToRoute(String route) {
    Widget? screen;
    
    switch (route) {
      case '/mood':
        // Navega para aba de mood na home (índice 2)
        Navigator.pop(context);
        return;
      case '/analytics':
        screen = const AnalyticsScreen();
        break;
      case '/settings':
        screen = const SettingsScreen();
        break;
      case '/tasks':
        screen = const TasksScreen();
        break;
      case '/notes':
        screen = const NotesScreen();
        break;
      case '/library':
        screen = const LibraryScreen();
        break;
      case '/habits':
        screen = const HabitsCalendarScreen();
        break;
      default:
        // Rota desconhecida, apenas fecha o modal
        Navigator.pop(context);
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interactiveOnboardingProvider);
    final unviewedTips = FeatureTips.unviewed(state.progress.viewedTips);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: colors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(unviewedTips.length),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildCategoryFilter(),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildTipsList(unviewedTips),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int unviewedCount) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                ),
                const Spacer(),
                if (unviewedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: colors.onPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$unviewedCount ${_isPortuguese ? 'novas' : 'new'}',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isPortuguese ? 'Descubra o Odyssey' : 'Discover Odyssey',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isPortuguese
                  ? 'Dicas, atalhos e features ocultas'
                  : 'Tips, shortcuts and hidden features',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      (null, _isPortuguese ? 'Todas' : 'All', Icons.apps_rounded),
      (FeatureCategory.mood, _isPortuguese ? 'Humor' : 'Mood', Icons.mood_rounded),
      (FeatureCategory.timer, 'Timer', Icons.timer_rounded),
      (FeatureCategory.tasks, _isPortuguese ? 'Tarefas' : 'Tasks', Icons.check_circle_rounded),
      (FeatureCategory.notes, _isPortuguese ? 'Notas' : 'Notes', Icons.note_rounded),
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (category, label, icon) = categories[index];
          final isSelected = _selectedCategory == category;
          final colors = Theme.of(context).colorScheme;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        },
      ),
    );
  }

  Widget _buildTipsList(List<FeatureTip> unviewedTips) {
    final state = ref.watch(interactiveOnboardingProvider);
    
    // Filter tips by category
    var tips = _selectedCategory == null
        ? FeatureTips.all
        : FeatureTips.byCategory(_selectedCategory!);

    if (tips.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tip = tips[index];
          final isViewed = state.progress.hasTipBeenViewed(tip.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TipCard(
              tip: tip,
              isViewed: isViewed,
              isPortuguese: _isPortuguese,
              onTap: () => _showTipDetail(tip),
            ),
          );
        },
        childCount: tips.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isPortuguese ? 'Tudo descoberto!' : 'All discovered!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPortuguese
                ? 'Você já viu todas as dicas desta categoria'
                : 'You\'ve seen all tips in this category',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showTipDetail(FeatureTip tip) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TipDetailSheet(
        tip: tip,
        isPortuguese: _isPortuguese,
        onDismiss: () {
          ref.read(interactiveOnboardingProvider.notifier).dismissTip();
          Navigator.pop(context);
        },
      ),
    );

    // Mark as viewed
    ref.read(interactiveOnboardingProvider.notifier).showTip(tip);
  }
}

/// Card individual de dica
class _TipCard extends StatelessWidget {
  final FeatureTip tip;
  final bool isViewed;
  final bool isPortuguese;
  final VoidCallback onTap;

  const _TipCard({
    required this.tip,
    required this.isViewed,
    required this.isPortuguese,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isViewed
                ? colors.outline.withValues(alpha: 0.1)
                : tip.typeColor.withValues(alpha: 0.3),
            width: isViewed ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tip.typeColor.withValues(alpha: isViewed ? 0.1 : 0.2),
                    tip.typeColor.withValues(alpha: isViewed ? 0.05 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                tip.icon,
                color: isViewed
                    ? tip.typeColor.withValues(alpha: 0.5)
                    : tip.typeColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tip.typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tip.typeIcon,
                              size: 12,
                              color: tip.typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPortuguese ? tip.typeLabelPt : tip.typeLabelEn,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tip.typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      if (!isViewed)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tip.typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    tip.getTitle(isPortuguese),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isViewed
                          ? colors.onSurface.withValues(alpha: 0.7)
                          : colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    tip.getDescription(isPortuguese),
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.chevron_right_rounded,
              color: colors.outline,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet com detalhes da dica
class _TipDetailSheet extends StatelessWidget {
  final FeatureTip tip;
  final bool isPortuguese;
  final VoidCallback onDismiss;

  const _TipDetailSheet({
    required this.tip,
    required this.isPortuguese,
    required this.onDismiss,
  });

  /// Navega para a tela correspondente à rota
  void _navigateToRoute(BuildContext context, String route) {
    Widget? screen;
    
    switch (route) {
      case '/mood':
        // Navega para aba de mood na home (índice 2)
        Navigator.pop(context);
        return;
      case '/analytics':
        screen = const AnalyticsScreen();
        break;
      case '/settings':
        screen = const SettingsScreen();
        break;
      case '/tasks':
        screen = const TasksScreen();
        break;
      case '/notes':
        screen = const NotesScreen();
        break;
      case '/library':
        screen = const LibraryScreen();
        break;
      case '/habits':
        screen = const HabitsCalendarScreen();
        break;
      default:
        // Rota desconhecida, apenas fecha o modal
        Navigator.pop(context);
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colors.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tip.typeColor,
                            tip.typeColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: tip.typeColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        tip.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tip.typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tip.typeIcon,
                                  size: 14,
                                  color: tip.typeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPortuguese ? tip.typeLabelPt : tip.typeLabelEn,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tip.typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tip.getTitle(isPortuguese),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  tip.getDescription(isPortuguese),
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // Action button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onDismiss();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tip.typeColor,
                          tip.typeColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: tip.typeColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isPortuguese ? 'Entendi!' : 'Got it!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Try feature button (if has action route)
                if (tip.actionRoute != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // Fecha o modal
                      _navigateToRoute(context, tip.actionRoute!);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isPortuguese ? 'Experimentar' : 'Try it',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colors.onSurface,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

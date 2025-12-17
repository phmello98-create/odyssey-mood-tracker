import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import '../onboarding_providers.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';
import 'feature_discovery_screen.dart';
import 'interactive_onboarding_screen.dart';

/// Formata duração em segundos para string legível
String _formatDuration(int seconds, bool isPortuguese) {
  if (seconds < 60) {
    return '$seconds ${isPortuguese ? 'seg' : 'sec'}';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) {
    return '$minutes ${isPortuguese ? 'min' : 'min'}';
  }
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} ${isPortuguese ? 'min' : 'min'}';
}

/// Tela de configurações do sistema de onboarding e dicas
class OnboardingSettingsScreen extends ConsumerWidget {
  const OnboardingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final state = ref.watch(interactiveOnboardingProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          isPortuguese ? 'Tutoriais e Dicas' : 'Tutorials & Tips',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress card
          _ProgressCard(
            viewedTips: state.progress.viewedTips.length,
            totalTips: FeatureTips.all.length,
            completedTours: state.progress.completedTours.length,
            totalTours: FeatureTours.all.length,
            isPortuguese: isPortuguese,
          ),

          const SizedBox(height: 24),

          // Settings section
          Text(
            isPortuguese ? 'Configurações' : 'Settings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: isPortuguese ? 'Dicas Contextuais' : 'Contextual Tips',
            subtitle: isPortuguese
                ? 'Mostrar dicas enquanto usa o app'
                : 'Show tips while using the app',
            value: state.progress.tipsEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(interactiveOnboardingProvider.notifier).setTipsEnabled(value);
            },
          ),

          _SettingsTile(
            icon: Icons.touch_app_rounded,
            iconColor: const Color(0xFF6366F1),
            title: isPortuguese ? 'Guias Interativos' : 'Interactive Guides',
            subtitle: isPortuguese
                ? 'Tooltips que destacam elementos'
                : 'Tooltips that highlight elements',
            value: state.progress.coachMarksEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(interactiveOnboardingProvider.notifier).setCoachMarksEnabled(value);
            },
          ),

          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFEC4899),
            title: isPortuguese ? 'Destaques de Features' : 'Feature Highlights',
            subtitle: isPortuguese
                ? 'Banners de novas funcionalidades'
                : 'New feature banners',
            value: state.progress.featureHighlightsEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(interactiveOnboardingProvider.notifier).setFeatureHighlightsEnabled(value);
            },
          ),

          const SizedBox(height: 24),

          // Actions section
          Text(
            isPortuguese ? 'Ações' : 'Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.replay_rounded,
            iconColor: colors.primary,
            title: isPortuguese ? 'Rever Onboarding Inicial' : 'Replay Initial Onboarding',
            subtitle: isPortuguese
                ? 'Assista novamente a apresentação do app'
                : 'Watch the app introduction again',
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navega para a tela de onboarding diretamente
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => InteractiveOnboardingScreen(
                    onComplete: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),

          _ActionTile(
            icon: Icons.explore_rounded,
            iconColor: const Color(0xFF10B981),
            title: isPortuguese ? 'Descobrir Funcionalidades' : 'Discover Features',
            subtitle: isPortuguese
                ? 'Veja todas as dicas e truques'
                : 'See all tips and tricks',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeatureDiscoveryScreen()),
              );
            },
          ),

          _ActionTile(
            icon: Icons.refresh_rounded,
            iconColor: const Color(0xFFFF6B6B),
            title: isPortuguese ? 'Resetar Dicas Vistas' : 'Reset Viewed Tips',
            subtitle: isPortuguese
                ? 'Marca todas as dicas como não vistas'
                : 'Mark all tips as not viewed',
            onTap: () {
              HapticFeedback.lightImpact();
              _showResetConfirmation(context, ref, isPortuguese);
            },
          ),

          const SizedBox(height: 24),

          // Tours section
          Text(
            isPortuguese ? 'Tours Disponíveis' : 'Available Tours',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          ...FeatureTours.all.map((tour) => _TourTile(
            tour: tour,
            isCompleted: state.progress.hasTourBeenCompleted(tour.id),
            isPortuguese: isPortuguese,
            onStart: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ref.read(interactiveOnboardingProvider.notifier).startTour(tour.id);
            },
          )),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref, bool isPortuguese) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPortuguese ? 'Resetar Dicas?' : 'Reset Tips?'),
        content: Text(
          isPortuguese
              ? 'Isso irá marcar todas as dicas como não vistas. Você poderá ver todas elas novamente.'
              : 'This will mark all tips as not viewed. You\'ll be able to see them all again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isPortuguese ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(interactiveOnboardingProvider.notifier).resetAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPortuguese ? 'Dicas resetadas!' : 'Tips reset!'),
                ),
              );
            },
            child: Text(isPortuguese ? 'Resetar' : 'Reset'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int viewedTips;
  final int totalTips;
  final int completedTours;
  final int totalTours;
  final bool isPortuguese;

  const _ProgressCard({
    required this.viewedTips,
    required this.totalTips,
    required this.completedTours,
    required this.totalTours,
    required this.isPortuguese,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tipsProgress = viewedTips / totalTips;
    final toursProgress = totalTours > 0 ? completedTours / totalTours : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.school_rounded,
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
                      isPortuguese ? 'Seu Progresso' : 'Your Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      isPortuguese
                          ? 'Continue explorando o Odyssey'
                          : 'Keep exploring Odyssey',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProgressBar(
            label: isPortuguese ? 'Dicas descobertas' : 'Tips discovered',
            value: viewedTips,
            total: totalTips,
            progress: tipsProgress,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            label: isPortuguese ? 'Tours completados' : 'Tours completed',
            value: completedTours,
            total: totalTours,
            progress: toursProgress,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final double progress;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              '$value / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colors.outline,
        ),
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  final FeatureTour tour;
  final bool isCompleted;
  final bool isPortuguese;
  final VoidCallback onStart;

  const _TourTile({
    required this.tour,
    required this.isCompleted,
    required this.isPortuguese,
    required this.onStart,
  });

  Color get _categoryColor {
    switch (tour.category) {
      case FeatureCategory.mood:
        return const Color(0xFFEC4899);
      case FeatureCategory.timer:
        return const Color(0xFFFF6B6B);
      case FeatureCategory.habits:
        return const Color(0xFF10B981);
      case FeatureCategory.tasks:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        onTap: onStart,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
            color: isCompleted ? const Color(0xFF10B981) : _categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          tour.getSectionName(isPortuguese),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          '${tour.steps.length} ${isPortuguese ? 'passos' : 'steps'} • ~${_formatDuration(tour.estimatedSeconds, isPortuguese)}',
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : _categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isCompleted
                ? (isPortuguese ? 'Refazer' : 'Redo')
                : (isPortuguese ? 'Iniciar' : 'Start'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF10B981) : _categoryColor,
            ),
          ),
        ),
      ),
    );
  }
}

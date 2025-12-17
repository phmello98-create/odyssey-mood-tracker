import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import '../onboarding_providers.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';

/// Widget flutuante para mostrar dicas contextuais
class ContextualTipWidget extends ConsumerStatefulWidget {
  final Widget child;
  final FeatureCategory? category;
  final bool autoShow;
  final Duration showDelay;

  const ContextualTipWidget({
    super.key,
    required this.child,
    this.category,
    this.autoShow = false,
    this.showDelay = const Duration(seconds: 3),
  });

  @override
  ConsumerState<ContextualTipWidget> createState() => _ContextualTipWidgetState();
}

class _ContextualTipWidgetState extends ConsumerState<ContextualTipWidget> {
  bool _hasShownTip = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoShow) {
      _scheduleAutoTip();
    }
  }

  void _scheduleAutoTip() {
    Future.delayed(widget.showDelay, () {
      if (!mounted || _hasShownTip) return;
      
      final state = ref.read(interactiveOnboardingProvider);
      if (!state.progress.tipsEnabled) return;
      if (state.isShowingTip || state.isShowingTour) return;
      
      final notifier = ref.read(interactiveOnboardingProvider.notifier);
      
      if (widget.category != null) {
        notifier.showTipForCategory(widget.category!);
      } else {
        notifier.showRandomTip();
      }
      
      _hasShownTip = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Card flutuante de "Você sabia?"
class DidYouKnowCard extends ConsumerWidget {
  final FeatureTip? tip;
  final VoidCallback? onDismiss;
  final VoidCallback? onTryIt;

  const DidYouKnowCard({
    super.key,
    this.tip,
    this.onDismiss,
    this.onTryIt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final state = ref.watch(interactiveOnboardingProvider);
    final displayTip = tip ?? state.currentTip;
    
    if (displayTip == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: displayTip.typeColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.surface.withValues(alpha: 0.95),
                  colors.surface.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: displayTip.typeColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: displayTip.typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 14,
                            color: displayTip.typeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPortuguese ? 'Você sabia?' : 'Did you know?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: displayTip.typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (onDismiss != null) {
                          onDismiss!();
                        } else {
                          ref.read(interactiveOnboardingProvider.notifier).dismissTip();
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: displayTip.typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        displayTip.icon,
                        color: displayTip.typeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTip.getTitle(isPortuguese),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayTip.getDescription(isPortuguese),
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
                  ],
                ),
                if (displayTip.actionRoute != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onTryIt != null) onTryIt!();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: displayTip.typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: displayTip.typeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPortuguese ? 'Experimentar' : 'Try it',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: displayTip.typeColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: displayTip.typeColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de mini-dica inline
class InlineTipBadge extends ConsumerWidget {
  final String tipId;
  final bool showOnlyOnce;

  const InlineTipBadge({
    super.key,
    required this.tipId,
    this.showOnlyOnce = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interactiveOnboardingProvider);
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    
    // Find the tip
    final tip = FeatureTips.all.firstWhere(
      (t) => t.id == tipId,
      orElse: () => FeatureTips.all.first,
    );

    // Don't show if already viewed and showOnlyOnce is true
    if (showOnlyOnce && state.progress.hasTipBeenViewed(tipId)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(interactiveOnboardingProvider.notifier).showTip(tip);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tip.typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tip.typeColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 14,
              color: tip.typeColor,
            ),
            const SizedBox(width: 6),
            Text(
              isPortuguese ? 'Dica' : 'Tip',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tip.typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar progresso de descoberta
class DiscoveryProgressCard extends ConsumerWidget {
  const DiscoveryProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interactiveOnboardingProvider);
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final colors = Theme.of(context).colorScheme;

    final totalTips = FeatureTips.all.length;
    final viewedTips = state.progress.viewedTips.length;
    final progress = viewedTips / totalTips;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.1),
            colors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPortuguese ? 'Descobertas' : 'Discoveries',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '$viewedTips / $totalTips ${isPortuguese ? 'dicas vistas' : 'tips viewed'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de notificação de nova feature
class NewFeatureBanner extends ConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback? onDismiss;
  final VoidCallback? onLearnMore;

  const NewFeatureBanner({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.onDismiss,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final colors = Theme.of(context).colorScheme;
    final bannerColor = color ?? colors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bannerColor.withValues(alpha: 0.15),
            bannerColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        bannerColor,
                        bannerColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bannerColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPortuguese ? 'NOVO' : 'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: bannerColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (onLearnMore != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onLearnMore,
                          child: Text(
                            isPortuguese ? 'Saiba mais →' : 'Learn more →',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: bannerColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// ANIMATED WIDGETS FOR ENHANCED UX
// ==========================================

/// Card de dica com animação "breathing" (pulsante suave)
class AnimatedBreathingTipCard extends ConsumerStatefulWidget {
  final FeatureTip tip;
  final VoidCallback? onDismiss;
  final VoidCallback? onTryIt;

  const AnimatedBreathingTipCard({
    super.key,
    required this.tip,
    this.onDismiss,
    this.onTryIt,
  });

  @override
  ConsumerState<AnimatedBreathingTipCard> createState() => _AnimatedBreathingTipCardState();
}

class _AnimatedBreathingTipCardState extends ConsumerState<AnimatedBreathingTipCard>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _entryController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation (continuous glow pulsing)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    // Entry animation (spring effect)
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const SpringCurve(),
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const SpringCurve(),
      ),
    );
    
    _entryController.forward();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _breathingController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.tip.typeColor.withValues(alpha: _breathingAnimation.value),
                      blurRadius: 25 + (_breathingAnimation.value * 15),
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: widget.tip.typeColor.withValues(alpha: _breathingAnimation.value * 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.surface.withValues(alpha: 0.95),
                            colors.surface.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.tip.typeColor.withValues(alpha: 0.3 + _breathingAnimation.value * 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: _buildContent(context, isPortuguese, colors),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isPortuguese, ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Animated icon with glow
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.tip.typeColor,
                        widget.tip.typeColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.tip.typeColor.withValues(alpha: _breathingAnimation.value),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.tip.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.tip.typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmeringIcon(
                          icon: Icons.lightbulb_rounded,
                          size: 14,
                          color: widget.tip.typeColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPortuguese ? 'Dica Pro' : 'Pro Tip',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.tip.typeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.tip.getTitle(isPortuguese),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Close button with micro-animation
            _AnimatedCloseButton(onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onDismiss != null) {
                widget.onDismiss!();
              } else {
                ref.read(interactiveOnboardingProvider.notifier).dismissTip();
              }
            }),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.tip.getDescription(isPortuguese),
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AnimatedDismissButton(
                label: isPortuguese ? 'Entendi!' : 'Got it!',
                color: widget.tip.typeColor,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (widget.onDismiss != null) {
                    widget.onDismiss!();
                  } else {
                    ref.read(interactiveOnboardingProvider.notifier).dismissTip();
                  }
                },
              ),
            ),
            if (widget.tip.actionRoute != null) ...[
              const SizedBox(width: 12),
              _AnimatedActionButton(
                label: isPortuguese ? 'Experimentar' : 'Try it',
                color: widget.tip.typeColor,
                onTap: widget.onTryIt,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Spring curve personalizada para animações mais naturais
class SpringCurve extends Curve {
  final double damping;
  final double stiffness;
  
  const SpringCurve({this.damping = 0.7, this.stiffness = 100});
  
  @override
  double transformInternal(double t) {
    final omega = math.sqrt(stiffness);
    final beta = damping / (2 * omega);
    final omegaD = omega * math.sqrt(1 - beta * beta);
    
    return 1 - math.exp(-beta * omega * t) * math.cos(omegaD * t);
  }
}

/// Ícone com efeito shimmer
class ShimmeringIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ShimmeringIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
  });

  @override
  State<ShimmeringIcon> createState() => _ShimmeringIconState();
}

class _ShimmeringIconState extends State<ShimmeringIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.5),
                Colors.white,
                baseColor.withValues(alpha: 0.5),
                baseColor,
              ],
              stops: [
                0.0,
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Icon(
            widget.icon,
            size: widget.size,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Botão de fechar animado
class _AnimatedCloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedCloseButton({required this.onTap});

  @override
  State<_AnimatedCloseButton> createState() => _AnimatedCloseButtonState();
}

class _AnimatedCloseButtonState extends State<_AnimatedCloseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.1),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 
                  0.8 + (_controller.value * 0.2),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botão "Entendi" animado
class _AnimatedDismissButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedDismissButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedDismissButton> createState() => _AnimatedDismissButtonState();
}

class _AnimatedDismissButtonState extends State<_AnimatedDismissButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.05),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4 - (_controller.value * 0.2)),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botão de ação secundário animado
class _AnimatedActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AnimatedActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.05),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12 + (_controller.value * 0.1)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: widget.color,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Decorative floating particles widget
class FloatingParticles extends StatefulWidget {
  final Color color;
  final int particleCount;
  final Widget child;

  const FloatingParticles({
    super.key,
    required this.color,
    this.particleCount = 8,
    required this.child,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _particles = List.generate(widget.particleCount, (_) => _Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double x = math.Random().nextDouble();
  final double startY = 1 + math.Random().nextDouble() * 0.3;
  final double speed = 0.3 + math.Random().nextDouble() * 0.4;
  final double size = 2 + math.Random().nextDouble() * 4;
  final double wobble = math.Random().nextDouble() * 0.1;
  final double wobbleSpeed = 1 + math.Random().nextDouble() * 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.startY - progress * particle.speed) % 1.3;
      final xOffset = math.sin(progress * math.pi * 2 * particle.wobbleSpeed) * particle.wobble;
      
      final opacity = y > 1 ? 0.0 : (y < 0.1 ? y * 10 : (y > 0.9 ? (1 - y) * 10 : 1.0));
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset((particle.x + xOffset) * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

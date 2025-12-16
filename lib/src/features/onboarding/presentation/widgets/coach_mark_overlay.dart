import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import '../onboarding_providers.dart';
import '../../domain/models/onboarding_models.dart';

/// Widget que renderiza um coach mark com overlay
class CoachMarkWidget extends ConsumerWidget {
  final CoachMark mark;
  final GlobalKey? targetKey;
  final double animationValue;
  final VoidCallback onDismiss;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const CoachMarkWidget({
    super.key,
    required this.mark,
    this.targetKey,
    required this.animationValue,
    required this.onDismiss,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPortuguese = ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';
    final state = ref.watch(interactiveOnboardingProvider);
    final isInTour = state.isShowingTour;
    final tour = state.currentTour;
    
    // Get target position
    Rect? targetRect;
    if (targetKey?.currentContext != null) {
      final renderBox = targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        targetRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
        debugPrint('[CoachMarkWidget] Target rect for ${mark.id}: $targetRect');
      }
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Semi-transparent background with hole
        Positioned.fill(
          child: GestureDetector(
            onTap: mark.requiresInteraction ? null : onDismiss,
            child: CustomPaint(
              painter: _HolePainter(
                targetRect: targetRect,
                opacity: animationValue * 0.85,
                holeRadius: 12,
              ),
            ),
          ),
        ),

        // Pulsing highlight around target
        if (targetRect != null)
          Positioned(
            left: targetRect.left - 8,
            top: targetRect.top - 8,
            child: IgnorePointer(
              child: _PulsingHighlight(
                width: targetRect.width + 16,
                height: targetRect.height + 16,
                color: _getCategoryColor(mark.category),
              ),
            ),
          ),

        // Tooltip
        _buildTooltip(context, ref, targetRect, screenSize, isPortuguese, isInTour, tour, state.currentTourStep),
      ],
    );
  }

  Color _getCategoryColor(FeatureCategory category) {
    switch (category) {
      case FeatureCategory.mood:
        return const Color(0xFFEC4899);
      case FeatureCategory.timer:
        return const Color(0xFFFF6B6B);
      case FeatureCategory.habits:
        return const Color(0xFF10B981);
      case FeatureCategory.tasks:
        return const Color(0xFF3B82F6);
      case FeatureCategory.gamification:
        return const Color(0xFFF59E0B);
      case FeatureCategory.notes:
        return const Color(0xFF8B5CF6);
      case FeatureCategory.library:
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildTooltip(
    BuildContext context,
    WidgetRef ref,
    Rect? targetRect,
    Size screenSize,
    bool isPortuguese,
    bool isInTour,
    FeatureTour? tour,
    int currentStep,
  ) {
    // Calculate tooltip position
    double? top, bottom, left, right;
    bool showArrowAbove = false;

    if (targetRect != null) {
      // Check if more space above or below
      final spaceAbove = targetRect.top;
      final spaceBelow = screenSize.height - targetRect.bottom;

      if (spaceBelow > 220) {
        top = targetRect.bottom + 20;
        showArrowAbove = true;
      } else if (spaceAbove > 220) {
        bottom = screenSize.height - targetRect.top + 20;
        showArrowAbove = false;
      } else {
        // Center vertically
        top = (screenSize.height - 200) / 2;
      }

      // Horizontal positioning - always full width with padding
      left = 20;
      right = 20;
    } else {
      // Center if no target
      left = 20;
      right = 20;
      top = (screenSize.height - 200) / 2;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: animationValue,
        child: Transform.translate(
          offset: Offset(0, (1 - animationValue) * (showArrowAbove ? -20 : 20)),
          child: _TooltipCard(
            mark: mark,
            isPortuguese: isPortuguese,
            showArrowAbove: showArrowAbove && targetRect != null,
            isInTour: isInTour,
            currentStep: currentStep,
            totalSteps: tour?.steps.length ?? 1,
            categoryColor: _getCategoryColor(mark.category),
            onNext: onNext,
            onSkip: onSkip,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }
}

/// Card do tooltip com conteúdo
class _TooltipCard extends StatelessWidget {
  final CoachMark mark;
  final bool isPortuguese;
  final bool showArrowAbove;
  final bool isInTour;
  final int currentStep;
  final int totalSteps;
  final Color categoryColor;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onDismiss;

  const _TooltipCard({
    required this.mark,
    required this.isPortuguese,
    required this.showArrowAbove,
    required this.isInTour,
    required this.currentStep,
    required this.totalSteps,
    required this.categoryColor,
    required this.onNext,
    required this.onSkip,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= totalSteps - 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and progress
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor,
                          categoryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isInTour)
                          Text(
                            isPortuguese 
                                ? 'Passo ${currentStep + 1} de $totalSteps'
                                : 'Step ${currentStep + 1} of $totalSteps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        Text(
                          mark.getTitle(isPortuguese),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button (if not in tour)
                  if (!isInTour)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDismiss();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                mark.getDescription(isPortuguese),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),

              // Progress indicator (for tours)
              if (isInTour) ...[
                const SizedBox(height: 16),
                Row(
                  children: List.generate(totalSteps, (index) {
                    final isActive = index <= currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? categoryColor
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (isInTour)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSkip();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              isPortuguese ? 'Pular' : 'Skip',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isInTour) const SizedBox(width: 12),
                  Expanded(
                    flex: isInTour ? 2 : 1,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (isInTour) {
                          onNext();
                        } else {
                          onDismiss();
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isInTour
                                    ? (isLastStep
                                        ? (isPortuguese ? 'Concluir' : 'Done')
                                        : (isPortuguese ? 'Próximo' : 'Next'))
                                    : (isPortuguese ? 'Entendi!' : 'Got it!'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (isInTour && !isLastStep) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter para o fundo escuro com buraco
class _HolePainter extends CustomPainter {
  final Rect? targetRect;
  final double opacity;
  final double holeRadius;

  _HolePainter({
    this.targetRect,
    required this.opacity,
    required this.holeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Add rounded hole
      path.addRRect(
        RRect.fromRectAndRadius(
          targetRect!.inflate(8),
          Radius.circular(holeRadius),
        ),
      );
      path.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || 
           oldDelegate.opacity != opacity;
  }
}

/// Widget para highlight pulsante
class _PulsingHighlight extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _PulsingHighlight({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<_PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<_PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5 + _controller.value * 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 + _controller.value * 0.2),
                blurRadius: 15 + _controller.value * 10,
                spreadRadius: 2 + _controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget helper para registrar elementos para coach marks
class CoachMarkTarget extends ConsumerStatefulWidget {
  final String id;
  final Widget child;
  final bool showOnFirstView;

  const CoachMarkTarget({
    super.key,
    required this.id,
    required this.child,
    this.showOnFirstView = false,
  });

  @override
  ConsumerState<CoachMarkTarget> createState() => _CoachMarkTargetState();
}

class _CoachMarkTargetState extends ConsumerState<CoachMarkTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _registerKey();
  }

  @override
  void didUpdateWidget(CoachMarkTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _registerKey();
    }
  }

  void _registerKey() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      debugPrint('[CoachMarkTarget] Registering key for: ${widget.id}');
      ref.read(interactiveOnboardingProvider.notifier).registerKey(widget.id, _key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

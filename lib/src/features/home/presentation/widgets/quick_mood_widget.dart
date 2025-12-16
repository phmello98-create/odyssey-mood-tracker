import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/add_mood_record/mood_configurations.dart';
import 'package:odyssey/src/features/mood_records/domain/add_mood_record/mood_option.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/gamification/data/synced_gamification_repository.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'modern_home_card.dart';

class QuickMoodWidget extends ConsumerWidget {
  const QuickMoodWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    const moodGreen = Color(0xFF34C759);

    return ModernHomeCard(
      accentColor: moodGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCardHeader(
            icon: Icons.mood_rounded,
            title: l10n.howAreYouFeeling,
            color: moodGreen,
          ),
          const SizedBox(height: 20),

          // Mood options com animação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: kMoodConfigurations.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;
              return _MoodButton(
                config: config,
                index: index,
                onTap: () => _quickRegisterMood(context, ref, config),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Botão "Adicionar mais detalhes"
          _AddDetailsButton(onTap: () => _openFullMoodForm(context)),
        ],
      ),
    );
  }

  void _quickRegisterMood(
      BuildContext context, WidgetRef ref, MoodConfiguration config) async {
    HapticFeedback.mediumImpact();
    soundService.playMoodSelect();

    try {
      final gamificationRepo = ref.read(syncedGamificationRepositoryProvider);
      await gamificationRepo.recordMood();

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        FeedbackService.showSuccessWithXP(
          context,
          l10n.youAreFeeling(config.label),
          10,
          title: l10n.moodRegistered,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        FeedbackService.showSuccess(
            context, l10n.moodRegisteredSuccess(config.label));
      }
    }
  }

  void _openFullMoodForm(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const AddMoodRecordForm(),
      ),
    );
  }
}

class _MoodButton extends StatefulWidget {
  final MoodConfiguration config;
  final int index;
  final VoidCallback onTap;

  const _MoodButton({
    required this.config,
    required this.index,
    required this.onTap,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
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
    final moodColor = widget.config.color;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (widget.index * 80)),
        curve: Curves.easeOutBack,
        builder: (context, appearValue, child) {
          return Transform.scale(
            scale: appearValue,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    children: [
                      // Container do emoji
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow quando pressionado
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: _isPressed
                                  ? [
                                      BoxShadow(
                                        color:
                                            moodColor.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          // Container principal
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  moodColor.withValues(alpha: _isPressed ? 0.25 : 0.12),
                                  moodColor.withValues(alpha: _isPressed ? 0.15 : 0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: moodColor.withValues(
                                    alpha: _isPressed ? 0.5 : 0.25),
                                width: _isPressed ? 2 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                widget.config.iconPath,
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: _isPressed ? 11 : 10,
                          fontWeight:
                              _isPressed ? FontWeight.w600 : FontWeight.w500,
                          color: _isPressed
                              ? moodColor
                              : colors.onSurfaceVariant,
                        ),
                        child: Text(widget.config.label),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AddDetailsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddDetailsButton({required this.onTap});

  @override
  State<_AddDetailsButton> createState() => _AddDetailsButtonState();
}

class _AddDetailsButtonState extends State<_AddDetailsButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.surfaceContainerHighest
                  .withValues(alpha: _isPressed ? 0.8 : 0.5),
              colors.surfaceContainerHighest
                  .withValues(alpha: _isPressed ? 0.6 : 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outline.withValues(alpha: _isPressed ? 0.15 : 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: _isPressed ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.add,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

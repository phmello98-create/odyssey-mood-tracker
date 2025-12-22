import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

/// Modelo de emoji para mood
class MoodEmoji {
  final String animatedSrc;
  final String staticSrc;
  final String label;
  final int value;
  final Color color;

  const MoodEmoji({
    required this.animatedSrc,
    required this.staticSrc,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Emojis de humor disponíveis
const List<MoodEmoji> moodEmojis = [
  MoodEmoji(
    animatedSrc: 'assets/emojis/animated_terrible.json',
    staticSrc: 'assets/emojis/noto_terrible.svg',
    label: 'Péssimo',
    value: 1,
    color: Color(0xFFE53935),
  ),
  MoodEmoji(
    animatedSrc: 'assets/emojis/animated_bad.json',
    staticSrc: 'assets/emojis/noto_bad.svg',
    label: 'Ruim',
    value: 2,
    color: Color(0xFFFF7043),
  ),
  MoodEmoji(
    animatedSrc: 'assets/emojis/animated_neutral.json',
    staticSrc: 'assets/emojis/noto_neutral.svg',
    label: 'Normal',
    value: 3,
    color: Color(0xFFFFCA28),
  ),
  MoodEmoji(
    animatedSrc: 'assets/emojis/animated_good.json',
    staticSrc: 'assets/emojis/noto_good.svg',
    label: 'Bem',
    value: 4,
    color: Color(0xFF66BB6A),
  ),
  MoodEmoji(
    animatedSrc: 'assets/emojis/animated_awesome.json',
    staticSrc: 'assets/emojis/noto_awesome.svg',
    label: 'Ótimo',
    value: 5,
    color: Color(0xFF42A5F5),
  ),
];

/// Widget de seleção de humor com emojis animados
class AnimatedMoodSelector extends StatefulWidget {
  const AnimatedMoodSelector({
    super.key,
    required this.onMoodSelected,
    this.initialMood,
    this.showLabels = true,
    this.labelStyle,
    this.inactiveScale = 0.7,
    this.activeScale = 1.0,
    this.animDuration = const Duration(milliseconds: 200),
    this.emojiSize = 60.0,
    this.spacing = 8.0,
    this.enableHaptic = true,
  });

  final ValueChanged<int> onMoodSelected;
  final int? initialMood;
  final bool showLabels;
  final TextStyle? labelStyle;
  final double inactiveScale;
  final double activeScale;
  final Duration animDuration;
  final double emojiSize;
  final double spacing;
  final bool enableHaptic;

  @override
  State<AnimatedMoodSelector> createState() => _AnimatedMoodSelectorState();
}

class _AnimatedMoodSelectorState extends State<AnimatedMoodSelector> {
  int? _selectedMood;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: moodEmojis.map((emoji) {
        final isSelected = _selectedMood == emoji.value;
        return _MoodEmojiItem(
          emoji: emoji,
          isSelected: isSelected,
          onTap: () {
            if (widget.enableHaptic) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              _selectedMood = emoji.value;
            });
            widget.onMoodSelected(emoji.value);
          },
          showLabel: widget.showLabels,
          labelStyle: widget.labelStyle,
          inactiveScale: widget.inactiveScale,
          activeScale: widget.activeScale,
          animDuration: widget.animDuration,
          size: widget.emojiSize,
        );
      }).toList(),
    );
  }
}

class _MoodEmojiItem extends StatefulWidget {
  const _MoodEmojiItem({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.showLabel,
    this.labelStyle,
    required this.inactiveScale,
    required this.activeScale,
    required this.animDuration,
    required this.size,
  });

  final MoodEmoji emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;
  final TextStyle? labelStyle;
  final double inactiveScale;
  final double activeScale;
  final Duration animDuration;
  final double size;

  @override
  State<_MoodEmojiItem> createState() => _MoodEmojiItemState();
}

class _MoodEmojiItemState extends State<_MoodEmojiItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MoodEmojiItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _playAnimation();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reset();
    }
  }

  Future<void> _playAnimation() async {
    try {
      final composition = await AssetLottie(widget.emoji.animatedSrc).load();
      _controller.duration = composition.duration;
      _controller.reset();
      await _controller.forward();
    } catch (e) {
      debugPrint('Error playing animation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.isSelected
        ? widget.activeScale
        : (_isTapped ? widget.inactiveScale * 0.9 : widget.inactiveScale);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: widget.animDuration,
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Container(
              width: widget.size,
              height: widget.size,
              decoration: widget.isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.emoji.color.withValues(alpha: 0.15),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ],
                    )
                  : null,
              child: widget.isSelected
                  ? Lottie.asset(
                      widget.emoji.animatedSrc,
                      controller: _controller,
                      width: widget.size,
                      height: widget.size,
                    )
                  : ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.5),
                        BlendMode.saturation,
                      ),
                      child: SvgPicture.asset(
                        widget.emoji.staticSrc,
                        width: widget.size,
                        height: widget.size,
                      ),
                    ),
            ),
            // Label
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: widget.animDuration,
                style: (widget.labelStyle ?? const TextStyle()).copyWith(
                  color: widget.isSelected
                      ? widget.emoji.color
                      : Colors.grey.shade500,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: widget.isSelected ? 13 : 11,
                ),
                child: Text(widget.emoji.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

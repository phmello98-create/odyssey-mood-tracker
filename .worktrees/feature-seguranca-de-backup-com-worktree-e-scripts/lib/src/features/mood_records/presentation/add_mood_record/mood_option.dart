import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:odyssey/src/features/mood_records/domain/add_mood_record/mood_option.dart';

/// Mapeamento de scores para emojis animados
const Map<int, String> _animatedEmojis = {
  1: 'assets/emojis/animated_terrible.json',
  2: 'assets/emojis/animated_bad.json',
  3: 'assets/emojis/animated_neutral.json',
  4: 'assets/emojis/animated_good.json',
  5: 'assets/emojis/animated_awesome.json',
};

const Map<int, String> _staticEmojis = {
  1: 'assets/emojis/noto_terrible.svg',
  2: 'assets/emojis/noto_bad.svg',
  3: 'assets/emojis/noto_neutral.svg',
  4: 'assets/emojis/noto_good.svg',
  5: 'assets/emojis/noto_awesome.svg',
};

class MoodOption extends StatefulWidget {
  const MoodOption({
    super.key,
    required this.moodConfiguration,
    required this.isSelected,
  });

  final MoodConfiguration moodConfiguration;
  final bool isSelected;

  @override
  State<MoodOption> createState() => _MoodOptionState();
}

class _MoodOptionState extends State<MoodOption> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
  void didUpdateWidget(covariant MoodOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _playAnimation();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reset();
    }
  }

  Future<void> _playAnimation() async {
    final animatedPath = _animatedEmojis[widget.moodConfiguration.score];
    if (animatedPath != null) {
      try {
        final composition = await AssetLottie(animatedPath).load();
        _controller.duration = composition.duration;
        _controller.reset();
        await _controller.forward();
      } catch (e) {
        debugPrint('Error playing mood animation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSelected ? 44.0 : 36.0;
    final score = widget.moodConfiguration.score;
    final animatedPath = _animatedEmojis[score];
    final staticPath = _staticEmojis[score];

    // Se tiver emoji animado disponível, usa ele
    if (animatedPath != null && staticPath != null) {
      if (widget.isSelected) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.moodConfiguration.color.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Lottie.asset(
            animatedPath,
            controller: _controller,
            width: size,
            height: size,
          ),
        );
      } else {
        // Emoji não selecionado - mostra em escala menor e com opacidade reduzida
        return Opacity(
          opacity: 0.5,
          child: SvgPicture.asset(
            staticPath,
            width: size,
            height: size,
          ),
        );
      }
    }

    // Fallback para o ícone SVG original
    return SvgPicture.asset(
      widget.moodConfiguration.iconPath,
      colorFilter: ColorFilter.mode(
        widget.moodConfiguration.color,
        BlendMode.srcIn,
      ),
      height: size,
      width: size,
    );
  }
}

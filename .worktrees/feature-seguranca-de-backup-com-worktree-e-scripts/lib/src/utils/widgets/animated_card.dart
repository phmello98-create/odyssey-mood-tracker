import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_theme.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool shouldAnimateOnTap;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.borderRadius = 16.0,
    this.color,
    this.onTap,
    this.margin = const EdgeInsets.all(8.0),
    this.shouldAnimateOnTap = true,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderRadiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _borderRadiusAnimation = Tween<double>(
      begin: widget.borderRadius,
      end: widget.borderRadius * 0.9,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      onTap: widget.onTap,
      onTapDown: widget.shouldAnimateOnTap ? (_) => _controller.forward() : null,
      onTapUp: widget.shouldAnimateOnTap ? (_) => _controller.reverse() : null,
      onTapCancel: widget.shouldAnimateOnTap ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: widget.margin,
              color: widget.color ?? UltravioletColors.cardBackground,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              ),
              elevation: 0,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

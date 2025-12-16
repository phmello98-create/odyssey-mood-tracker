import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const LoadingAnimation({
    Key? key,
    this.size = 40.0,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _scaleAnimation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_scaleAnimation1, color),
        const SizedBox(width: 8),
        _buildDot(_scaleAnimation2, color),
        const SizedBox(width: 8),
        _buildDot(_scaleAnimation3, color),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation, Color color) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        width: widget.size / 3,
        height: widget.size / 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class AnimatedToggleButtons extends StatefulWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedToggleButtons({
    Key? key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelectionChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  State<AnimatedToggleButtons> createState() => _AnimatedToggleButtonsState();
}

class _AnimatedToggleButtonsState extends State<AnimatedToggleButtons>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.labels.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = List.generate(
      widget.labels.length,
      (index) => Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedToggleButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Animate the newly selected button
      if (widget.selectedIndex >= 0 && widget.selectedIndex < _controllers.length) {
        _controllers[widget.selectedIndex].forward().then((_) {
          _controllers[widget.selectedIndex].reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? theme.colorScheme.onSurfaceVariant;

    return ToggleButtons(
      isSelected: List.generate(
        widget.labels.length,
        (index) => index == widget.selectedIndex,
      ),
      onPressed: (index) {
        widget.onSelectionChanged(index);
        if (index >= 0 && index < _controllers.length) {
          _controllers[index].forward().then((_) {
            _controllers[index].reverse();
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      selectedColor: activeColor,
      color: inactiveColor,
      fillColor: activeColor.withValues(alpha: 0.1),
      focusColor: activeColor.withValues(alpha: 0.1),
      highlightColor: activeColor.withValues(alpha: 0.1),
      splashColor: activeColor.withValues(alpha: 0.2),
      constraints: const BoxConstraints(
        minHeight: 40,
        minWidth: 80,
      ),
      children: List.generate(
        widget.labels.length,
        (index) {
          return AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.labels[index],
                    style: TextStyle(
                      fontWeight: index == widget.selectedIndex
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

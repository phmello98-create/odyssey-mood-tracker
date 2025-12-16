import 'package:flutter/material.dart';

class OdysseyFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const OdysseyFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip = '',
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<OdysseyFloatingActionButton> createState() => _OdysseyFloatingActionButtonState();
}

class _OdysseyFloatingActionButtonState extends State<OdysseyFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              tooltip: widget.tooltip,
              shape: const CircleBorder(),
              child: Icon(widget.icon),
            ),
          );
        },
      ),
    );
  }
}

class OdysseyAnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ShapeBorder? shape;

  const OdysseyAnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.shape,
  }) : super(key: key);

  @override
  State<OdysseyAnimatedButton> createState() => _OdysseyAnimatedButtonState();
}

class _OdysseyAnimatedButtonState extends State<OdysseyAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? theme.colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ).merge(widget.child is Text ? (widget.child as Text).style : null),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

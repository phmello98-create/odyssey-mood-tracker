import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

/// Widget de escala com animação spring
class MotionScale extends StatelessWidget {
  final Widget child;
  final double scale;
  final Motion motion;
  final Alignment alignment;

  const MotionScale({
    super.key,
    required this.child,
    required this.scale,
    this.motion = const CupertinoMotion.bouncy(),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: scale,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Widget de opacidade com animação spring
class MotionOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Motion motion;

  const MotionOpacity({
    super.key,
    required this.child,
    required this.opacity,
    this.motion = const CupertinoMotion.smooth(),
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: opacity,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Widget de translação com animação spring
class MotionTranslate extends StatelessWidget {
  final Widget child;
  final Offset offset;
  final Motion motion;

  const MotionTranslate({
    super.key,
    required this.child,
    required this.offset,
    this.motion = const CupertinoMotion.bouncy(),
  });

  @override
  Widget build(BuildContext context) {
    return MotionBuilder(
      motion: motion,
      value: offset,
      converter: const OffsetMotionConverter(),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Widget de rotação com animação spring
class MotionRotation extends StatelessWidget {
  final Widget child;
  final double angle;
  final Motion motion;
  final Alignment alignment;

  const MotionRotation({
    super.key,
    required this.child,
    required this.angle,
    this.motion = const CupertinoMotion.bouncy(),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: angle,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Botão com animação de pressionar
class MotionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Motion motion;
  final BorderRadius? borderRadius;
  final Color? splashColor;

  const MotionButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.motion = const CupertinoMotion.snappy(),
    this.borderRadius,
    this.splashColor,
  });

  @override
  State<MotionButton> createState() => _MotionButtonState();
}

class _MotionButtonState extends State<MotionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: MotionScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        motion: widget.motion,
        child: widget.child,
      ),
    );
  }
}

/// Card com animação de hover/toque
class MotionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;
  final double elevation;
  final double pressedScale;
  final double pressedElevation;

  const MotionCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.elevation = 2,
    this.pressedScale = 0.98,
    this.pressedElevation = 8,
  });

  @override
  State<MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends State<MotionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: SingleMotionBuilder(
        motion: const CupertinoMotion.snappy(),
        value: _isPressed ? widget.pressedScale : 1.0,
        builder: (context, scale, child) {
          return SingleMotionBuilder(
            motion: const CupertinoMotion.smooth(),
            value: _isPressed ? widget.pressedElevation : widget.elevation,
            builder: (context, elevation, child) {
              return Transform.scale(
                scale: scale,
                child: Material(
                  elevation: elevation,
                  color: widget.color ?? Theme.of(context).cardColor,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Checkbox animado com spring
class MotionCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final double size;
  final Motion motion;

  const MotionCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.checkColor,
    this.size = 24,
    this.motion = const CupertinoMotion.bouncy(),
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: SingleMotionBuilder(
        motion: motion,
        value: value ? 1.0 : 0.0,
        builder: (context, progress, _) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, color, progress),
              borderRadius: BorderRadius.circular(size * 0.25),
              border: Border.all(
                color: Color.lerp(Colors.grey, color, progress)!,
                width: 2,
              ),
            ),
            child: progress > 0.3
                ? Transform.scale(
                    scale: progress,
                    child: Icon(
                      Icons.check,
                      size: size * 0.7,
                      color: checkColor ?? Colors.white,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// Progresso circular animado com spring
class MotionCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final Motion motion;
  final Widget? child;

  const MotionCircularProgress({
    super.key,
    required this.value,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.valueColor,
    this.motion = const CupertinoMotion.smooth(),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: value.clamp(0.0, 1.0),
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _CircularProgressPainter(
                  value: animatedValue,
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
                  valueColor: valueColor ?? Theme.of(context).primaryColor,
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;

  _CircularProgressPainter({
    required this.value,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.valueColor != valueColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Lista animada com entrada em cascata
class MotionList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Motion motion;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const MotionList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.motion = const CupertinoMotion.bouncy(),
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: _buildAnimatedChildren(),
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(children.length, (index) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(
          milliseconds: 400 + (index * staggerDelay.inMilliseconds),
        ),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(
              direction == Axis.horizontal ? 30 * (1 - value) : 0,
              direction == Axis.vertical ? 20 * (1 - value) : 0,
            ),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: children[index],
      );
    });
  }
}

/// Contador animado com spring
class MotionCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final Motion motion;

  const MotionCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.motion = const CupertinoMotion.smooth(),
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: value.toDouble(),
      builder: (context, animatedValue, _) {
        return Text(
          '${prefix ?? ''}${animatedValue.round()}${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// Barra de progresso linear animada
class MotionLinearProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final BorderRadius? borderRadius;
  final Motion motion;

  const MotionLinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.borderRadius,
    this.motion = const CupertinoMotion.smooth(),
  });

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: motion,
      value: value.clamp(0.0, 1.0),
      builder: (context, animatedValue, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                color: valueColor ?? Theme.of(context).primaryColor,
                borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Switch animado com spring
class MotionSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Motion motion;

  const MotionSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.motion = const CupertinoMotion.bouncy(),
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Theme.of(context).primaryColor;
    final inactive = inactiveColor ?? Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: SingleMotionBuilder(
        motion: motion,
        value: value ? 1.0 : 0.0,
        builder: (context, progress, _) {
          return Container(
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              color: Color.lerp(inactive, active, progress),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(2),
            child: Align(
              alignment: Alignment.lerp(
                Alignment.centerLeft,
                Alignment.centerRight,
                progress,
              )!,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
}

/// FAB com animação de entrada
class MotionFAB extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double size;
  final bool extended;
  final String? label;

  const MotionFAB({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.size = 56,
    this.extended = false,
    this.label,
  });

  @override
  State<MotionFAB> createState() => _MotionFABState();
}

class _MotionFABState extends State<MotionFAB> {
  bool _isPressed = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Delay para animar entrada
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      motion: const CupertinoMotion.bouncy(),
      value: _isVisible ? 1.0 : 0.0,
      builder: (context, visibilityProgress, _) {
        return Transform.scale(
          scale: visibilityProgress,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: SingleMotionBuilder(
              motion: const CupertinoMotion.snappy(),
              value: _isPressed ? 0.9 : 1.0,
              builder: (context, scale, _) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: widget.size,
                    constraints: BoxConstraints(minWidth: widget.size),
                    padding: widget.extended
                        ? const EdgeInsets.symmetric(horizontal: 16)
                        : null,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.backgroundColor ??
                                  Theme.of(context).primaryColor)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: widget.extended && widget.label != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widget.child,
                              const SizedBox(width: 8),
                              Text(
                                widget.label!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Center(child: widget.child),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

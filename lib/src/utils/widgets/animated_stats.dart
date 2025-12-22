import 'package:flutter/material.dart';
import 'package:countup/countup.dart';
import 'package:odyssey/src/constants/app_theme.dart';

/// Widget de número animado com contagem
class AnimatedStatNumber extends StatelessWidget {
  final double value;
  final String? prefix;
  final String? suffix;
  final int decimals;
  final Duration duration;
  final TextStyle? style;
  final Curve curve;

  const AnimatedStatNumber({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return Countup(
      begin: 0,
      end: value,
      duration: duration,
      curve: curve,
      separator: '.',
      prefix: prefix ?? '',
      suffix: suffix ?? '',
      style:
          style ??
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: UltravioletColors.onSurface,
          ),
    );
  }
}

/// Card de estatística com animação de entrada e número animado
class AnimatedStatCard extends StatefulWidget {
  final String title;
  final double value;
  final String? suffix;
  final IconData icon;
  final Color color;
  final Duration delay;
  final VoidCallback? onTap;
  final Widget? customContent;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
    required this.color,
    this.delay = Duration.zero,
    this.onTap,
    this.customContent,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: UltravioletColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              widget.customContent ??
                  AnimatedStatNumber(
                    value: widget.value,
                    suffix: widget.suffix,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso animada
class AnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double height;
  final Duration duration;
  final Duration delay;
  final BorderRadius? borderRadius;
  final bool showPercentage;
  final String? label;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor,
    this.height = 8,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.borderRadius,
    this.showPercentage = false,
    this.label,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                  ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color:
                widget.backgroundColor ?? widget.color.withValues(alpha: 0.15),
            borderRadius: radius,
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Ring de progresso circular animado
class AnimatedCircularProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final Duration delay;
  final Widget? child;
  final bool showPercentage;

  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor,
    this.size = 80,
    this.strokeWidth = 8,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = Duration.zero,
    this.child,
    this.showPercentage = true,
  });

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background ring
              CircularProgressIndicator(
                value: 1,
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation(
                  widget.backgroundColor ??
                      widget.color.withValues(alpha: 0.15),
                ),
              ),
              // Progress ring
              CircularProgressIndicator(
                value: _progressAnimation.value.clamp(0.0, 1.0),
                strokeWidth: widget.strokeWidth,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(widget.color),
              ),
              // Center content
              Center(
                child:
                    widget.child ??
                    (widget.showPercentage
                        ? Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: widget.size * 0.22,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                            ),
                          )
                        : null),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mini gráfico de barras animado
class AnimatedMiniBarChart extends StatefulWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double barWidth;
  final double spacing;
  final Duration duration;
  final Duration delay;

  const AnimatedMiniBarChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
    this.barWidth = 6,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedMiniBarChart> createState() => _AnimatedMiniBarChartState();
}

class _AnimatedMiniBarChartState extends State<AnimatedMiniBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) return const SizedBox.shrink();

    final maxValue = widget.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.values.length, (index) {
          final normalizedValue = widget.values[index] / maxValue;
          final staggerDelay = index * 50;

          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.values.length - 1 ? widget.spacing : 0,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Staggered animation
                final progress =
                    ((_controller.value * widget.values.length) - index).clamp(
                      0.0,
                      1.0,
                    );
                final curvedProgress = Curves.elasticOut.transform(progress);

                return Container(
                  width: widget.barWidth,
                  height: widget.height * normalizedValue * curvedProgress,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: 0.3 + (0.7 * normalizedValue),
                    ),
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// Linha de sparkline animada
class AnimatedSparkline extends StatefulWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final Duration duration;
  final Duration delay;
  final bool showDots;
  final bool fillArea;

  const AnimatedSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
    this.strokeWidth = 2,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = Duration.zero,
    this.showDots = false,
    this.fillArea = true,
  });

  @override
  State<AnimatedSparkline> createState() => _AnimatedSparklineState();
}

class _AnimatedSparklineState extends State<AnimatedSparkline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty || widget.values.length < 2) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _SparklinePainter(
              values: widget.values,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              progress: Curves.easeOutCubic.transform(_controller.value),
              showDots: widget.showDots,
              fillArea: widget.fillArea,
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double progress;
  final bool showDots;
  final bool fillArea;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.progress,
    required this.showDots,
    required this.fillArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedY = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y =
          size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    // Animate the visible points
    final visiblePoints = (points.length * progress).ceil();
    final animatedPoints = points.take(visiblePoints).toList();

    if (animatedPoints.length < 2) return;

    // Draw fill area
    if (fillArea) {
      final fillPath = Path();
      fillPath.moveTo(animatedPoints.first.dx, size.height);
      for (final point in animatedPoints) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(animatedPoints.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePath = Path();
    linePath.moveTo(animatedPoints.first.dx, animatedPoints.first.dy);
    for (int i = 1; i < animatedPoints.length; i++) {
      linePath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw dots
    if (showDots) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in animatedPoints) {
        canvas.drawCircle(point, strokeWidth * 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.values != values;
  }
}

/// Widget de streak com animação de fogo
class AnimatedStreakWidget extends StatefulWidget {
  final int streak;
  final Duration delay;

  const AnimatedStreakWidget({
    super.key,
    required this.streak,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedStreakWidget> createState() => _AnimatedStreakWidgetState();
}

class _AnimatedStreakWidgetState extends State<AnimatedStreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(
                    alpha: 0.2 * _glowAnimation.value,
                  ),
                  blurRadius: 12 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedStatNumber(
                      value: widget.streak.toDouble(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      'dias seguidos',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

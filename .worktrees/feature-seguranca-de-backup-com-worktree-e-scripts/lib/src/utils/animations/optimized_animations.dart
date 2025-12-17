import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_sizes.dart';

/// Wrapper que adiciona RepaintBoundary automaticamente para isolar animações
/// Use em widgets com animações pesadas para evitar repintar a árvore inteira
class IsolatedAnimation extends StatelessWidget {
  final Widget child;
  
  const IsolatedAnimation({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Widget que desabilita animações em dispositivos de baixo desempenho
class AdaptiveAnimation extends StatelessWidget {
  final Widget animatedChild;
  final Widget staticChild;
  final bool? forceAnimate;

  const AdaptiveAnimation({
    super.key,
    required this.animatedChild,
    required this.staticChild,
    this.forceAnimate,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica se deve usar animações
    final shouldAnimate = forceAnimate ?? _shouldUseAnimations(context);
    
    return shouldAnimate ? animatedChild : staticChild;
  }

  bool _shouldUseAnimations(BuildContext context) {
    // Verifica configurações de acessibilidade
    final mediaQuery = MediaQuery.of(context);
    
    // Desabilita animações se o usuário preferir movimento reduzido
    if (mediaQuery.disableAnimations) return false;
    
    // Verifica se é um dispositivo de baixo desempenho (heurística simples)
    // Em produção, pode usar device_info_plus para mais precisão
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final screenSize = mediaQuery.size;
    final totalPixels = screenSize.width * screenSize.height * devicePixelRatio;
    
    // Se a tela tem muitos pixels, pode ser um dispositivo de alto desempenho
    return totalPixels > 500000;
  }
}

/// Fade In animado otimizado com RepaintBoundary
class OptimizedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset? slideOffset;

  const OptimizedFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.slideOffset,
  });

  @override
  State<OptimizedFadeIn> createState() => _OptimizedFadeInState();
}

class _OptimizedFadeInState extends State<OptimizedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset ?? Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Inicia animação após delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Lista com itens que aparecem em cascata otimizada
class OptimizedStaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Axis direction;
  final double slideDistance;

  const OptimizedStaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.direction = Axis.vertical,
    this.slideDistance = 20,
  });

  @override
  State<OptimizedStaggeredList> createState() => _OptimizedStaggeredListState();
}

class _OptimizedStaggeredListState extends State<OptimizedStaggeredList> {
  @override
  Widget build(BuildContext context) {
    // Usa RepaintBoundary para cada item
    final children = List.generate(widget.children.length, (index) {
      final slideOffset = widget.direction == Axis.vertical
          ? Offset(0, widget.slideDistance)
          : Offset(widget.slideDistance, 0);

      return OptimizedFadeIn(
        delay: Duration(milliseconds: index * widget.itemDelay.inMilliseconds),
        duration: widget.itemDuration,
        slideOffset: slideOffset,
        curve: Curves.easeOutCubic,
        child: widget.children[index],
      );
    });

    return widget.direction == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          )
        : Row(children: children);
  }
}

/// Wrapper para animações de pulse/heartbeat
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool enabled;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.0,
    this.enabled = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Shimmer effect otimizado
class OptimizedShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const OptimizedShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1C1C26),
    this.highlightColor = const Color(0xFF2D2D3A),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<OptimizedShimmer> createState() => _OptimizedShimmerState();
}

class _OptimizedShimmerState extends State<OptimizedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(OptimizedShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value, 0),
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Widget que mostra skeleton enquanto carrega
class SkeletonLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? skeleton;
  final Duration fadeDuration;

  const SkeletonLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
    this.fadeDuration = AppDuration.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: fadeDuration,
      child: isLoading
          ? (skeleton ?? _buildDefaultSkeleton())
          : child,
    );
  }

  Widget _buildDefaultSkeleton() {
    return RepaintBoundary(
      child: OptimizedShimmer(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Animação de rotação contínua otimizada
class SpinningAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const SpinningAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.enabled = true,
  });

  @override
  State<SpinningAnimation> createState() => _SpinningAnimationState();
}

class _SpinningAnimationState extends State<SpinningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SpinningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: RotationTransition(
        turns: _controller,
        child: widget.child,
      ),
    );
  }
}

/// Widget de contagem regressiva animada
class AnimatedCountdown extends StatefulWidget {
  final int seconds;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const AnimatedCountdown({
    super.key,
    required this.seconds,
    this.style,
    this.onComplete,
  });

  @override
  State<AnimatedCountdown> createState() => _AnimatedCountdownState();
}

class _AnimatedCountdownState extends State<AnimatedCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.seconds),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.seconds.toDouble(),
      end: 0.0,
    ).animate(_controller);

    _controller.forward().whenComplete(() {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final seconds = _animation.value.ceil();
          return Text(
            '$seconds',
            style: widget.style ?? Theme.of(context).textTheme.displayLarge,
          );
        },
      ),
    );
  }
}

/// Bounce animation para feedback visual
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double bounceScale;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.bounceScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.bounceScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

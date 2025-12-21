import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de Timer Gamificado com estilo Neumorphic 3D
/// Design moderno, interativo e com feedback visual rico
class GamifiedTimerWidget extends StatefulWidget {
  final Duration timeLeft;
  final Duration totalTime;
  final bool isRunning;
  final bool isBreak;
  final int completedSessions;
  final int totalSessions;
  final int currentXP;
  final int xpToGain;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback? onSkip;
  final Color accentColor;
  final String? taskName;

  const GamifiedTimerWidget({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.isRunning,
    this.isBreak = false,
    this.completedSessions = 0,
    this.totalSessions = 4,
    this.currentXP = 0,
    this.xpToGain = 25,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    this.onSkip,
    this.accentColor = const Color(0xFFFF6B6B),
    this.taskName,
  });

  @override
  State<GamifiedTimerWidget> createState() => _GamifiedTimerWidgetState();
}

class _GamifiedTimerWidgetState extends State<GamifiedTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 12; i++) {
      _particles.add(
        _Particle(
          angle: (i * 30) * math.pi / 180,
          speed: 0.3 + _random.nextDouble() * 0.4,
          size: 2 + _random.nextDouble() * 3,
          opacity: 0.3 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(GamifiedTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRunning && oldWidget.isRunning) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  double get progress {
    if (widget.totalTime.inSeconds == 0) return 0;
    return 1 - (widget.timeLeft.inSeconds / widget.totalTime.inSeconds);
  }

  String get timeString {
    final minutes = widget.timeLeft.inMinutes;
    final seconds = widget.timeLeft.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Use surface container colors for better depth in both modes
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surface;

    // Dynamic shadows based on theme
    final shadowDark = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.1);

    final shadowLight = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status da sessão (Break ou Focus)
        _buildSessionStatus(isDark, colorScheme),
        const SizedBox(height: 20),

        // Timer principal com efeito 3D
        _buildMainTimer(
          baseColor,
          shadowDark,
          shadowLight,
          isDark,
          colorScheme,
        ),
        const SizedBox(height: 24),

        // Barra de XP
        _buildXPBar(isDark, colorScheme),
        const SizedBox(height: 24),

        // Indicador de sessões (flames)
        _buildSessionIndicator(isDark, colorScheme),
        const SizedBox(height: 32),

        // Controles
        _buildControls(baseColor, shadowDark, shadowLight, isDark, colorScheme),
      ],
    );
  }

  Widget _buildSessionStatus(bool isDark, ColorScheme colorScheme) {
    // Determine colors based on state
    const breakColor = Color(
      0xFF4ECDC4,
    ); // Keep generic nice teal for break
    final activeColor = widget.accentColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(widget.isBreak),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isBreak
                ? [breakColor, breakColor.withValues(alpha: 0.8)]
                : [activeColor, activeColor.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.isBreak ? breakColor : activeColor).withValues(
                alpha: 0.4,
              ),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isBreak ? '☕' : '🎯',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isBreak ? 'INTERVALO' : 'FOCO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTimer(
    Color baseColor,
    Color shadowDark,
    Color shadowLight,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _glowAnimation,
        _particleController,
      ]),
      builder: (context, child) {
        final pulse = widget.isRunning ? _pulseAnimation.value : 1.0;
        final glow = _glowAnimation.value;

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Partículas orbitando (quando rodando)
                if (widget.isRunning) ..._buildParticles(),

                // Glow externo animado
                Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: glow * 0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

                // Anel externo neumorphic
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor,
                    boxShadow: [
                      // Sombra externa (profundidade)
                      BoxShadow(
                        color: shadowDark,
                        offset: const Offset(8, 8),
                        blurRadius: 20,
                      ),
                      // Luz interna (elevação)
                      BoxShadow(
                        color: shadowLight,
                        offset: const Offset(-8, -8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Anel de progresso
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _NeumorphicProgressPainter(
                      progress: progress,
                      color: widget.isBreak
                          ? const Color(0xFF4ECDC4)
                          : widget.accentColor,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 12,
                      glowIntensity: glow,
                    ),
                  ),
                ),

                // Centro com tempo (estilo 3D inset)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor,
                    boxShadow: [
                      // Sombra interna (pressed effect)
                      BoxShadow(
                        color: shadowDark,
                        offset: const Offset(-4, -4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: shadowLight,
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji animado
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Text(
                              widget.isBreak
                                  ? '☕'
                                  : (widget.isRunning ? '🔥' : '🍅'),
                              style: const TextStyle(fontSize: 36),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Tempo
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            widget.accentColor,
                            widget.accentColor.withValues(alpha: 0.7),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      // Task name
                      if (widget.taskName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.taskName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Combo indicator (se tiver múltiplas sessões)
                if (widget.completedSessions > 0)
                  Positioned(top: 20, right: 20, child: _buildComboIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      final animValue = _particleController.value;
      final angle = particle.angle + (animValue * 2 * math.pi * particle.speed);
      const radius = 135.0;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      return Positioned(
        left: 150 + x - particle.size / 2,
        top: 150 + y - particle.size / 2,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accentColor.withValues(alpha: particle.opacity),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildComboIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${widget.completedSessions}x',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(bool isDark, ColorScheme colorScheme) {
    final xpProgress = widget.isRunning ? progress : 0.0;
    final earnedXP = (widget.xpToGain * xpProgress).round();

    return Column(
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '+$earnedXP XP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.accentColor,
              ),
            ),
            if (widget.isRunning) ...[
              const SizedBox(width: 8),
              _buildPulsingDot(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Barra
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200 * xpProgress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingDot() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: _glowAnimation.value),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionIndicator(bool isDark, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalSessions, (index) {
        final isCompleted = index < widget.completedSessions;
        final isCurrent = index == widget.completedSessions;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                // Flame ou círculo
                AnimatedScale(
                  scale: isCurrent && widget.isRunning ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isCompleted ? '🔥' : (isCurrent ? '🍅' : '○'),
                    style: TextStyle(
                      fontSize: isCompleted ? 24 : (isCurrent ? 22 : 18),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Barra embaixo
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isCompleted
                        ? widget.accentColor
                        : (isCurrent
                              ? widget.accentColor.withValues(alpha: 0.5)
                              : (isDark ? Colors.white12 : Colors.black12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControls(
    Color baseColor,
    Color shadowDark,
    Color shadowLight,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botão Reset
        _buildNeumorphicButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onReset();
          },
          baseColor: baseColor,
          shadowDark: shadowDark,
          shadowLight: shadowLight,
          size: 50,
        ),
        const SizedBox(width: 24),

        // Botão Play/Pause (maior)
        _buildNeumorphicButton(
          icon: widget.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          onTap: () {
            HapticFeedback.heavyImpact();
            if (widget.isRunning) {
              widget.onPause();
            } else {
              widget.onStart();
            }
          },
          baseColor: baseColor,
          shadowDark: shadowDark,
          shadowLight: shadowLight,
          size: 80,
          isPrimary: true,
          accentColor: widget.accentColor,
        ),
        const SizedBox(width: 24),

        // Botão Skip
        _buildNeumorphicButton(
          icon: Icons.skip_next_rounded,
          onTap: widget.onSkip != null
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onSkip!();
                }
              : null,
          baseColor: baseColor,
          shadowDark: shadowDark,
          shadowLight: shadowLight,
          size: 50,
        ),
      ],
    );
  }

  Widget _buildNeumorphicButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color baseColor,
    required Color shadowDark,
    required Color shadowLight,
    required double size,
    bool isPrimary = false,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPrimary && accentColor != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                )
              : null,
          color: isPrimary ? null : baseColor,
          boxShadow: [
            BoxShadow(
              color: isPrimary && accentColor != null
                  ? accentColor.withValues(alpha: 0.4)
                  : shadowDark,
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
            if (!isPrimary)
              BoxShadow(
                color: shadowLight,
                offset: const Offset(-4, -4),
                blurRadius: 10,
              ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: isPrimary
              ? Colors.white
              : (onTap != null
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54)
                    : Colors.grey),
        ),
      ),
    );
  }
}

// Painter para o anel de progresso neumorphic
class _NeumorphicProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double glowIntensity;

  _NeumorphicProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc com glow
    if (progress > 0) {
      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: glowIntensity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );

      // Progress arc
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * progress,
          colors: [color, color.withValues(alpha: 0.7), color],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      // Dot no final do progresso
      final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      // Glow do dot
      final dotGlowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 4, dotGlowPaint);

      // Dot
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 - 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeumorphicProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

// Classe para partículas
class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double opacity;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

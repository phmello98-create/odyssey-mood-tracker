import 'package:odyssey/src/localization/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Timer Pomodoro com visual de Tomate
/// Design baseado no timer de cozinha clássico
class TomatoTimerWidget extends StatefulWidget {
  final Duration timeLeft;
  final Duration totalTime;
  final bool isRunning;
  final bool isBreak;
  final int completedSessions;
  final int totalSessions;
  final int xpToGain;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback? onSkip;
  final String? taskName;

  const TomatoTimerWidget({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.isRunning,
    this.isBreak = false,
    this.completedSessions = 0,
    this.totalSessions = 4,
    this.xpToGain = 25,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    this.onSkip,
    this.taskName,
  });

  @override
  State<TomatoTimerWidget> createState() => _TomatoTimerWidgetState();
}

class _TomatoTimerWidgetState extends State<TomatoTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  // Cores do tomate (públicas para o painter)
  static const Color tomatoRed = Color(0xFFE74C3C);
  static const Color tomatoDarkRed = Color(0xFFC0392B);
  static const Color tomatoLightRed = Color(0xFFFF6B6B);
  static const Color leafGreen = Color(0xFF27AE60);
  static const Color leafDarkGreen = Color(0xFF1E8449);
  static const Color breakBlue = Color(0xFF3498DB);
  static const Color breakDarkBlue = Color(0xFF2980B9);
  static const Color breakLightBlue = Color(0xFF5DADE2);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TomatoTimerWidget oldWidget) {
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
    _bounceController.dispose();
    super.dispose();
  }

  double get progress {
    if (widget.totalTime.inSeconds == 0) return 0;
    return 1 - (widget.timeLeft.inSeconds / widget.totalTime.inSeconds);
  }

  String get timeString {
    final minutes = widget.timeLeft.inMinutes;
    final seconds = widget.timeLeft.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get currentColor => widget.isBreak ? breakBlue : tomatoRed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nome da tarefa com animação PRO - espaçamento reduzido
        if (widget.taskName != null) ...[
          _RandomTextReveal(
            text: widget.taskName!.toUpperCase(),
            isBreak: widget.isBreak,
            color: currentColor,
          ),
          const SizedBox(height: 4), // Espaço mínimo
        ] else ...[
          // Fallback minimalista
          Text(
            widget.isBreak ? 'PAUSA' : 'FOCO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: currentColor.withValues(alpha: 0.8),
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4), // Espaço mínimo
        ],

        // Tomate Timer
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _bounceController.forward().then(
              (_) => _bounceController.reverse(),
            );
            if (widget.isRunning) {
              widget.onPause();
            } else {
              widget.onStart();
            }
          }, // Added comma
          // Performance: RepaintBoundary isola a animação do timer
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * _bounceAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 280,
                height: 320,
                child: CustomPaint(
                  painter: _TomatoPainter(
                    progress: progress,
                    isBreak: widget.isBreak,
                    isRunning: widget.isRunning,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tempo
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.min,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Session indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalSessions, (index) {
            final isCompleted = index < widget.completedSessions;
            final isCurrent = index == widget.completedSessions;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 12 : 10,
              height: isCurrent ? 12 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? currentColor
                    : isCurrent
                    ? currentColor.withValues(alpha: 0.5)
                    : colors.surfaceContainerHighest,
                border: isCurrent
                    ? Border.all(color: currentColor, width: 2)
                    : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        Text(
          '${widget.completedSessions}/${widget.totalSessions} sessões',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),

        const SizedBox(height: 24),

        // XP Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentColor.withValues(alpha: 0.2),
                currentColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: currentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '+${widget.xpToGain} XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset button
            _buildControlButton(
              icon: Icons.refresh_rounded,
              onTap: widget.onReset,
              color: colors.surfaceContainerHighest,
              iconColor: colors.onSurfaceVariant,
            ),

            const SizedBox(width: 20),

            // Play/Pause button
            _buildPlayButton(colors),

            const SizedBox(width: 20),

            // Skip button
            if (widget.onSkip != null)
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                onTap: widget.onSkip!,
                color: colors.surfaceContainerHighest,
                iconColor: colors.onSurfaceVariant,
              )
            else
              const SizedBox(width: 56),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton(ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (widget.isRunning) {
          widget.onPause();
        } else {
          widget.onStart();
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [currentColor, currentColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: currentColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          widget.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}

class _TomatoPainter extends CustomPainter {
  final double progress;
  final bool isBreak;
  final bool isRunning;

  _TomatoPainter({
    required this.progress,
    required this.isBreak,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final tomatoRadius = size.width * 0.42;

    // Cores
    final baseColor = isBreak
        ? _TomatoTimerWidgetState.breakBlue
        : _TomatoTimerWidgetState.tomatoRed;
    final lightColor = isBreak
        ? _TomatoTimerWidgetState.breakLightBlue
        : _TomatoTimerWidgetState.tomatoLightRed;
    final darkColor = isBreak
        ? _TomatoTimerWidgetState.breakDarkBlue
        : _TomatoTimerWidgetState.tomatoDarkRed;
    const leafColor = _TomatoTimerWidgetState.leafGreen;
    const leafDarkColor = _TomatoTimerWidgetState.leafDarkGreen;

    // Sombra do tomate
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + tomatoRadius * 0.9),
        width: tomatoRadius * 1.4,
        height: tomatoRadius * 0.3,
      ),
      shadowPaint,
    );

    // Corpo do tomate (base)
    final tomatoPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.2,
        colors: [lightColor, baseColor, darkColor],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: tomatoRadius));

    // Desenha o tomate com forma levemente achatada
    final tomatoRect = Rect.fromCenter(
      center: center,
      width: tomatoRadius * 2,
      height: tomatoRadius * 1.85,
    );
    canvas.drawOval(tomatoRect, tomatoPaint);

    // Highlight (brilho)
    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            center: const Alignment(-0.5, -0.5),
            radius: 0.8,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                center.dx - tomatoRadius * 0.3,
                center.dy - tomatoRadius * 0.3,
              ),
              radius: tomatoRadius * 0.5,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx - tomatoRadius * 0.3,
          center.dy - tomatoRadius * 0.3,
        ),
        width: tomatoRadius * 0.6,
        height: tomatoRadius * 0.4,
      ),
      highlightPaint,
    );

    // Indicador de progresso (fatia)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      final progressPath = Path();
      progressPath.moveTo(center.dx, center.dy);

      // Desenha a fatia do progresso (como uma pizza)
      final sweepAngle = progress * 2 * math.pi;
      progressPath.arcTo(
        Rect.fromCircle(center: center, radius: tomatoRadius * 0.75),
        -math.pi / 2, // Começa do topo
        sweepAngle,
        false,
      );
      progressPath.close();

      canvas.save();
      canvas.clipPath(Path()..addOval(tomatoRect));
      canvas.drawPath(progressPath, progressPaint);
      canvas.restore();

      // Borda da fatia
      final borderPaint = Paint()
        ..color = darkColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(progressPath, borderPaint);
    }

    // Folhas (caule)
    _drawLeaves(
      canvas,
      Offset(center.dx, center.dy - tomatoRadius * 0.85),
      leafColor,
      leafDarkColor,
    );

    // Ponteiro do relógio
    _drawClockHand(canvas, center, tomatoRadius * 0.65, progress, darkColor);

    // Marcadores de minutos ao redor
    _drawMinuteMarkers(canvas, center, tomatoRadius);
  }

  void _drawClockHand(
    Canvas canvas,
    Offset center,
    double length,
    double progress,
    Color color,
  ) {
    // Ângulo do ponteiro baseado no progresso (-90° = topo, progride no sentido horário)
    final angle = -math.pi / 2 + (progress * 2 * math.pi);

    final endPoint = Offset(
      center.dx + math.cos(angle) * length,
      center.dy + math.sin(angle) * length,
    );

    // Sombra do ponteiro
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(endPoint.dx + 2, endPoint.dy + 2),
      shadowPaint,
    );

    // Ponteiro principal
    final handPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, endPoint, handPaint);

    // Centro do ponteiro (pino)
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);

    // Borda branca do pino
    final centerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, centerBorderPaint);
  }

  void _drawLeaves(
    Canvas canvas,
    Offset stemBase,
    Color leafColor,
    Color leafDarkColor,
  ) {
    final leafPaint = Paint()..style = PaintingStyle.fill;

    // Caule central
    final stemPaint = Paint()
      ..color = leafDarkColor
      ..style = PaintingStyle.fill;

    final stemPath = Path();
    stemPath.moveTo(stemBase.dx - 4, stemBase.dy);
    stemPath.quadraticBezierTo(
      stemBase.dx,
      stemBase.dy - 15,
      stemBase.dx + 4,
      stemBase.dy,
    );
    stemPath.close();
    canvas.drawPath(stemPath, stemPaint);

    // Folhas
    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.5 - math.pi / 2;
      final leafLength = 25.0 + (i % 2) * 8;

      leafPaint.shader = LinearGradient(
        colors: [leafColor, leafDarkColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(stemBase.dx - 20, stemBase.dy - 30, 40, 30));

      final leafPath = Path();
      final leafTip = Offset(
        stemBase.dx + math.cos(angle) * leafLength,
        stemBase.dy + math.sin(angle) * leafLength,
      );

      leafPath.moveTo(stemBase.dx, stemBase.dy - 5);
      leafPath.quadraticBezierTo(
        stemBase.dx + math.cos(angle + 0.3) * leafLength * 0.5,
        stemBase.dy + math.sin(angle + 0.3) * leafLength * 0.5,
        leafTip.dx,
        leafTip.dy,
      );
      leafPath.quadraticBezierTo(
        stemBase.dx + math.cos(angle - 0.3) * leafLength * 0.5,
        stemBase.dy + math.sin(angle - 0.3) * leafLength * 0.5,
        stemBase.dx,
        stemBase.dy - 5,
      );

      canvas.drawPath(leafPath, leafPaint);
    }
  }

  void _drawMinuteMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Marcadores a cada 5 minutos (12 marcadores)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final innerRadius = radius * 0.82;
      final outerRadius = radius * 0.88;

      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * outerRadius * 0.92,
      );
      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius * 0.92,
      );

      canvas.drawLine(start, end, markerPaint);
    }
  }

  @override
  bool shouldRepaint(_TomatoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isBreak != isBreak ||
        oldDelegate.isRunning != isRunning;
  }
}

// Widget elegante para exibir o nome da tarefa com animação sutil
class _RandomTextReveal extends StatelessWidget {
  final String text;
  final bool isBreak;
  final Color color;

  const _RandomTextReveal({
    required this.text,
    required this.isBreak,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.length > 20 ? '${text.substring(0, 18)}...' : text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de status pulsante simples
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Texto
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

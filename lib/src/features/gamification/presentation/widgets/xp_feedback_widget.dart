import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import '../../data/gamification_repository.dart';

/// Widget overlay para mostrar feedback de XP ganho
class XPFeedbackOverlay extends StatefulWidget {
  final int xpAmount;
  final List<({String skillName, int xpGained, bool leveledUp})> skillUpdates;
  final bool leveledUp;
  final int? newLevel;
  final VoidCallback? onComplete;

  const XPFeedbackOverlay({
    super.key,
    required this.xpAmount,
    this.skillUpdates = const [],
    this.leveledUp = false,
    this.newLevel,
    this.onComplete,
  });

  @override
  State<XPFeedbackOverlay> createState() => _XPFeedbackOverlayState();
}

class _XPFeedbackOverlayState extends State<XPFeedbackOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _skillsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _skillsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainController);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    HapticFeedback.mediumImpact();
    _mainController.forward().then((_) {
      if (widget.skillUpdates.isNotEmpty) {
        _skillsController.forward().then((_) {
          widget.onComplete?.call();
        });
      } else {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _skillsController]),
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // XP Principal
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.leveledUp
                              ? [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ]
                              : [
                                  UltravioletColors.primary,
                                  UltravioletColors.secondary,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (widget.leveledUp
                                        ? const Color(0xFFFFD700)
                                        : UltravioletColors.primary)
                                    .withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.leveledUp ? Icons.celebration : Icons.bolt,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.leveledUp
                                ? 'LEVEL UP! ${widget.newLevel}'
                                : '+${widget.xpAmount} XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Skills updates
              if (widget.skillUpdates.isNotEmpty && _skillsController.value > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Opacity(
                    opacity: _skillsController.value,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.skillUpdates.map((update) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: update.leveledUp
                                ? const Color(0xFFFFD700).withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (update.leveledUp)
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.black87,
                                ),
                              Text(
                                '${update.skillName} +${update.xpGained}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Serviço para mostrar feedbacks de gamificação
class GamificationFeedbackService {
  static OverlayEntry? _currentOverlay;

  static void showXPGained(
    BuildContext context, {
    required int xpAmount,
    List<({String skillName, int xpGained, bool leveledUp})> skillUpdates =
        const [],
    bool leveledUp = false,
    int? newLevel,
  }) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => XPFeedbackOverlay(
        xpAmount: xpAmount,
        skillUpdates: skillUpdates,
        leveledUp: leveledUp,
        newLevel: newLevel,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Mostra feedback completo a partir de um GamificationResult
  static void showFromResult(
    BuildContext context,
    GamificationResult result,
    int xpGained,
  ) {
    final skillUpdates = result.skillUpdates
        .map(
          (u) => (
            skillName: u.skillName,
            xpGained: u.xpGained,
            leveledUp: u.leveledUp,
          ),
        )
        .toList();

    // Se houve level up, mostra celebração completa
    if (result.leveledUp) {
      showLevelUpCelebration(context, newLevel: result.stats.level);
    } else {
      showXPGained(
        context,
        xpAmount: xpGained,
        skillUpdates: skillUpdates,
        leveledUp: false,
      );
    }
  }

  /// Mostra a celebração de Level Up com confetes
  static void showLevelUpCelebration(
    BuildContext context, {
    required int newLevel,
    String? unlockedTitle,
  }) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        unlockedTitle: unlockedTitle,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }
}

/// Widget de tela cheia para celebrar Level Up com confetes
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String? unlockedTitle;
  final VoidCallback? onComplete;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    this.unlockedTitle,
    this.onComplete,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _shineController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  final List<_ConfettiPiece> _confetti = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_mainController);

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -20.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    // Gerar confetes
    _generateConfetti();

    // Feedback háptico forte
    HapticFeedback.heavyImpact();

    // Iniciar animações
    _mainController.forward();
    _confettiController.forward();
    _shineController.repeat(reverse: true);

    // Completar após a animação
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _generateConfetti() {
    final colors = [
      const Color(0xFFFFD700), // Dourado
      const Color(0xFFFFA500), // Laranja
      const Color(0xFFFF6B6B), // Vermelho
      const Color(0xFF4ECDC4), // Verde água
      const Color(0xFF9B51E0), // Roxo
      const Color(0xFF00B4D8), // Azul
      const Color(0xFF07E092), // Verde
      const Color(0xFFFF69B4), // Rosa
    ];

    for (int i = 0; i < 100; i++) {
      _confetti.add(
        _ConfettiPiece(
          x: _random.nextDouble(),
          y: -_random.nextDouble() * 0.3,
          size: 6 + _random.nextDouble() * 8,
          color: colors[_random.nextInt(colors.length)],
          speed: 0.3 + _random.nextDouble() * 0.7,
          angle: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          isCircle: _random.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _confettiController,
          _shineController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Fundo escurecido
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.7 * _fadeAnimation.value,
                  ),
                ),
              ),

              // Confetes
              ..._confetti.map((piece) {
                final progress = _confettiController.value;
                final y = piece.y + progress * piece.speed * 1.5;
                final rotation = piece.angle + progress * piece.rotationSpeed;

                if (y > 1.2) return const SizedBox.shrink();

                return Positioned(
                  left:
                      piece.x * size.width +
                      math.sin(progress * 3 + piece.angle) * 30,
                  top: y * size.height,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Opacity(
                      opacity: (1 - progress * 0.5).clamp(0.0, 1.0),
                      child: Container(
                        width: piece.size,
                        height: piece.isCircle ? piece.size : piece.size * 0.4,
                        decoration: BoxDecoration(
                          color: piece.color,
                          borderRadius: piece.isCircle
                              ? BorderRadius.circular(piece.size / 2)
                              : BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Conteúdo central
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brilho atrás
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow animado
                                Container(
                                  width: 180 + _shineController.value * 40,
                                  height: 180 + _shineController.value * 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFFFD700).withValues(
                                          alpha: 0.4 * _shineController.value,
                                        ),
                                        const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                // Badge principal
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                        Text(
                                          '${widget.newLevel}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Texto LEVEL UP
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                  Color(0xFFFFD700),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'LEVEL UP!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Subtítulo
                            Text(
                              'Você alcançou o nível ${widget.newLevel}!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.unlockedTitle != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.military_tech_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Novo título desbloqueado!',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          widget.unlockedTitle!,
                                          style: const TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

/// Widget para mostrar um pequeno "+XP" flutuante perto de um elemento
class FloatingXPIndicator extends StatefulWidget {
  final int xp;
  final Offset position;

  const FloatingXPIndicator({
    super.key,
    required this.xp,
    required this.position,
  });

  @override
  State<FloatingXPIndicator> createState() => _FloatingXPIndicatorState();
}

class _FloatingXPIndicatorState extends State<FloatingXPIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _slideAnimation = Tween<double>(
      begin: 0,
      end: -50,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
        return Positioned(
          left: widget.position.dx,
          top: widget.position.dy + _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: UltravioletColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${widget.xp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

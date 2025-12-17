import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import '../../domain/models/first_steps_content.dart';
import '../onboarding_providers.dart';

/// Widget de checklist de primeiros passos para a Home Screen
/// Mostra uma lista compacta de passos para novos usuários
class FirstStepsChecklist extends ConsumerStatefulWidget {
  /// Callback quando um passo com rota é clicado
  final void Function(String route)? onNavigate;

  const FirstStepsChecklist({
    super.key,
    this.onNavigate,
  });

  @override
  ConsumerState<FirstStepsChecklist> createState() => _FirstStepsChecklistState();
}

class _FirstStepsChecklistState extends ConsumerState<FirstStepsChecklist>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = true;
  bool _showingCelebration = false;
  int _previousCompletedCount = 0;

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _dismissChecklist() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      ref.read(interactiveOnboardingProvider.notifier).dismissFirstSteps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedSteps = ref.watch(completedFirstStepsProvider);
    final progress = ref.watch(firstStepsProgressProvider);
    final xpEarned = ref.watch(firstStepsXpEarnedProvider);
    final totalSteps = FirstStepsContent.all.length;
    
    // Detecta quando todos os passos são completados para mostrar celebração
    if (completedSteps.length >= totalSteps && !_showingCelebration && _previousCompletedCount < totalSteps) {
      _showingCelebration = true;
      // Agenda a exibição da celebração após o build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionCelebration();
      });
    }
    _previousCompletedCount = completedSteps.length;

    // Não mostra se todos os passos foram completados (após celebração)
    if (completedSteps.length >= totalSteps && !_showingCelebration) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E2E).withValues(alpha: 0.95),
              const Color(0xFF2A2A3E).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(progress, xpEarned, completedSteps.length),
            
            // Steps list (collapsible)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded 
                  ? CrossFadeState.showFirst 
                  : CrossFadeState.showSecond,
              firstChild: _buildStepsList(completedSteps),
              secondChild: const SizedBox(height: 8),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra celebração quando todos os passos são completados
  void _showCompletionCelebration() {
    final totalXp = FirstStepsContent.all.fold<int>(0, (sum, step) => sum + step.xpReward);
    
    // Toca som de celebração
    SoundService().playSndCelebration();
    HapticFeedback.heavyImpact();
    
    // Mostra overlay de celebração
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _FirstStepsCompletionDialog(
        totalXp: totalXp,
        isPortuguese: _isPortuguese,
        onDismiss: () {
          Navigator.pop(context);
          // Esconde o checklist após a celebração
          _controller.reverse().then((_) {
            ref.read(interactiveOnboardingProvider.notifier).dismissFirstSteps();
          });
        },
      ),
    );
  }

  Widget _buildHeader(double progress, int xpEarned, int completedCount) {
    final totalSteps = FirstStepsContent.all.length;
    
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPortuguese ? 'Primeiros Passos' : 'First Steps',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPortuguese 
                            ? '$completedCount de $totalSteps completados'
                            : '$completedCount of $totalSteps completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$xpEarned XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Expand/collapse button
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(Set<String> completedSteps) {
    const steps = FirstStepsContent.all;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          ...steps.map((step) => _buildStepItem(step, completedSteps.contains(step.id))),
          const SizedBox(height: 8),
          // Dismiss button
          TextButton(
            onPressed: _dismissChecklist,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              _isPortuguese ? 'Esconder checklist' : 'Hide checklist',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(FirstStep step, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => _onStepTap(step),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? step.color.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted 
                    ? step.color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? step.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted 
                          ? step.color 
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isCompleted 
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Icon
                Icon(
                  step.icon,
                  color: isCompleted 
                      ? step.color 
                      : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.getTitle(_isPortuguese),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCompleted 
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white,
                          decoration: isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      Text(
                        step.getDescription(_isPortuguese),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // XP reward
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${step.xpReward}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                
                // Arrow for navigation
                if (!isCompleted && step.route != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onStepTap(FirstStep step) {
    HapticFeedback.lightImpact();
    if (step.route != null && widget.onNavigate != null) {
      widget.onNavigate!(step.route!);
    }
  }
}

/// Dialog de celebração quando todos os FirstSteps são completados
class _FirstStepsCompletionDialog extends StatefulWidget {
  final int totalXp;
  final bool isPortuguese;
  final VoidCallback onDismiss;

  const _FirstStepsCompletionDialog({
    required this.totalXp,
    required this.isPortuguese,
    required this.onDismiss,
  });

  @override
  State<_FirstStepsCompletionDialog> createState() => _FirstStepsCompletionDialogState();
}

class _FirstStepsCompletionDialogState extends State<_FirstStepsCompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final List<_ConfettiPiece> _confetti = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));
    
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 85),
    ]).animate(_mainController);
    
    _generateConfetti();
    _mainController.forward();
    _confettiController.forward();
  }

  void _generateConfetti() {
    final colors = [
      const Color(0xFFFFD700), // Dourado
      const Color(0xFFFFA500), // Laranja
      const Color(0xFFFF6B6B), // Vermelho
      const Color(0xFF4ECDC4), // Verde água
      const Color(0xFF9B51E0), // Roxo
      const Color(0xFF6366F1), // Índigo
      const Color(0xFF07E092), // Verde
      const Color(0xFFFF69B4), // Rosa
    ];

    for (int i = 0; i < 80; i++) {
      _confetti.add(_ConfettiPiece(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.2,
        size: 6 + _random.nextDouble() * 8,
        color: colors[_random.nextInt(colors.length)],
        speed: 0.2 + _random.nextDouble() * 0.5,
        angle: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        isCircle: _random.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _confettiController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Confetti
            ..._confetti.map((piece) {
              final progress = _confettiController.value;
              final y = piece.y + progress * piece.speed * 1.8;
              final rotation = piece.angle + progress * piece.rotationSpeed;
              
              if (y > 1.3) return const SizedBox.shrink();
              
              return Positioned(
                left: piece.x * size.width + math.sin(progress * 4 + piece.angle) * 25,
                top: y * size.height,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: (1 - progress * 0.4).clamp(0.0, 1.0),
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
            
            // Card de celebração
            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E1E2E),
                          Color(0xFF2A2A3E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone de troféu
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Título
                        Text(
                          widget.isPortuguese ? 'Parabéns!' : 'Congratulations!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtítulo
                        Text(
                          widget.isPortuguese 
                              ? 'Você completou todos os primeiros passos!'
                              : 'You completed all first steps!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // XP ganho
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.totalXp} XP',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Botão de continuar
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                widget.isPortuguese ? 'Continuar' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Classe para representar uma peça de confetti
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

/// Provider helper para marcar automaticamente passos como completos
/// Use em outros lugares do app quando o usuário completa uma ação
extension FirstStepsTracker on WidgetRef {
  /// Marca um passo como completo (chame quando a ação acontecer)
  void markFirstStepComplete(String stepId) {
    read(interactiveOnboardingProvider.notifier).completeFirstStep(stepId);
  }

  /// Verifica se um passo já foi completado
  bool isFirstStepComplete(String stepId) {
    return watch(completedFirstStepsProvider).contains(stepId);
  }
}

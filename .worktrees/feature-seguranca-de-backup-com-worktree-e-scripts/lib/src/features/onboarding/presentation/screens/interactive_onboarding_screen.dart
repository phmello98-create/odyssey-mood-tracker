import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import '../onboarding_providers.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';

/// Tela de onboarding interativo com animações modernas
class InteractiveOnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const InteractiveOnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<InteractiveOnboardingScreen> createState() => _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState extends ConsumerState<InteractiveOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _backgroundAnimController;
  late AnimationController _iconAnimController;
  late AnimationController _contentAnimController;
  late AnimationController _particleController;
  
  int _currentPage = 0;
  final List<_Particle> _particles = [];

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _backgroundAnimController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _iconAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.3 + 0.1,
        opacity: random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimController.dispose();
    _iconAnimController.dispose();
    _contentAnimController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    
    // Reset e reanima conteúdo
    _iconAnimController.reset();
    _contentAnimController.reset();
    _iconAnimController.forward();
    _contentAnimController.forward();

    // Atualiza provider
    ref.read(interactiveOnboardingProvider.notifier).setOnboardingPage(page);
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < OnboardingPages.all.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await ref.read(interactiveOnboardingProvider.notifier).completeInitialOnboarding();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentPageData = OnboardingPages.all[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A15),
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_backgroundAnimController.value * math.pi * 2) * 0.3,
                      -0.4 + math.cos(_backgroundAnimController.value * math.pi) * 0.1,
                    ),
                    radius: 1.2 + _backgroundAnimController.value * 0.3,
                    colors: [
                      currentPageData.gradientColors[0].withValues(alpha: 0.4),
                      currentPageData.gradientColors[1].withValues(alpha: 0.2),
                      const Color(0xFF0A0A15),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: currentPageData.gradientColors[0],
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: OnboardingPages.all.length,
                    itemBuilder: (context, index) {
                      return _buildPage(OnboardingPages.all[index], index);
                    },
                  ),
                ),

                // Bottom section
                _buildBottomSection(bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/app_icon/icon_foreground.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.rocket_launch,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ODYSSEY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),

          // Skip button
          if (_currentPage < OnboardingPages.all.length - 1)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skipOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  _isPortuguese ? 'Pular' : 'Skip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    final isActive = _currentPage == index;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.3,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Animated icon
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _iconAnimController,
                  curve: Curves.elasticOut,
                )),
                child: FadeTransition(
                  opacity: _iconAnimController,
                  child: _buildAnimatedIcon(page),
                ),
              ),

              const SizedBox(height: 40),

            // Title
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _contentAnimController,
                curve: const Interval(0.2, 0.8),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _contentAnimController,
                  curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                )),
                child: Text(
                  page.getTitle(_isPortuguese),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Subtitle
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _contentAnimController,
                curve: const Interval(0.4, 1.0),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _contentAnimController,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                )),
                child: Text(
                  page.getSubtitle(_isPortuguese),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Feature highlights
            if (page.featureHighlights.isNotEmpty)
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _contentAnimController,
                  curve: const Interval(0.6, 1.0),
                ),
                child: _buildFeatureHighlights(page),
              ),

            // Demo interativo de humor (página 2)
            if (page.hasInteractiveDemo) ...[
              const SizedBox(height: 32),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _contentAnimController,
                  curve: const Interval(0.7, 1.0),
                ),
                child: _buildMoodDemo(page),
              ),
            ],

            // Preview do HelpFab (página 3)
            if (page.showHelpFabPreview) ...[
              const SizedBox(height: 32),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _contentAnimController,
                  curve: const Interval(0.7, 1.0),
                ),
                child: _buildHelpFabPreview(page),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  /// Demo interativo de humor para onboarding
  Widget _buildMoodDemo(OnboardingPage page) {
    final moods = ['😊', '😌', '😐', '😔', '😢'];
    
    return Column(
      children: [
        Text(
          _isPortuguese ? 'Experimente:' : 'Try it:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: page.gradientColors[0].withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: moods.map((emoji) {
              return _MoodButton(
                emoji: emoji,
                color: page.gradientColors[0],
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Feedback visual de seleção
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isPortuguese 
                            ? 'Ótimo! Assim você registra seu humor $emoji'
                            : 'Great! This is how you log your mood $emoji',
                        style: const TextStyle(fontSize: 14),
                      ),
                      backgroundColor: page.gradientColors[0],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Preview do botão de ajuda para familiarizar usuário
  Widget _buildHelpFabPreview(OnboardingPage page) {
    return Column(
      children: [
        Text(
          _isPortuguese ? 'Procure este botão:' : 'Look for this button:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Seta animada apontando para o botão
            AnimatedBuilder(
              animation: _backgroundAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.sin(_backgroundAnimController.value * math.pi * 4) * 8,
                    0,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: page.gradientColors[0].withValues(alpha: 0.7),
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Preview do HelpFab
            AnimatedBuilder(
              animation: _backgroundAnimController,
              builder: (context, child) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: page.gradientColors,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.gradientColors[0].withValues(alpha: 
                          0.4 + _backgroundAnimController.value * 0.2,
                        ),
                        blurRadius: 16 + _backgroundAnimController.value * 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Seta animada apontando para o botão
            AnimatedBuilder(
              animation: _backgroundAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -math.sin(_backgroundAnimController.value * math.pi * 4) * 8,
                    0,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: page.gradientColors[0].withValues(alpha: 0.7),
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _isPortuguese 
              ? 'Ele mostra tutoriais de cada tela'
              : 'It shows tutorials for each screen',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(OnboardingPage page) {
    return AnimatedBuilder(
      animation: _backgroundAnimController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                page.gradientColors[0].withValues(alpha: 0.3),
                page.gradientColors[1].withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: page.gradientColors[0].withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: page.gradientColors[0].withValues(alpha: 
                    0.3 + _backgroundAnimController.value * 0.2),
                blurRadius: 40 + _backgroundAnimController.value * 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              Transform.rotate(
                angle: _backgroundAnimController.value * math.pi * 2,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.gradientColors[0].withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Icon
              Icon(
                page.icon,
                size: 56,
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureHighlights(OnboardingPage page) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: page.featureHighlights.map((highlight) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: page.gradientColors[0].withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: page.gradientColors[0].withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            highlight,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: page.gradientColors[0].withValues(alpha: 0.9),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection(double bottomPadding) {
    final isLastPage = _currentPage == OnboardingPages.all.length - 1;
    final currentPageData = OnboardingPages.all[_currentPage];

    return Padding(
      padding: EdgeInsets.fromLTRB(32, 20, 32, bottomPadding + 24),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(OnboardingPages.all.length, (index) {
              final isActive = index == _currentPage;
              final pageData = OnboardingPages.all[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: isActive
                        ? LinearGradient(colors: pageData.gradientColors)
                        : null,
                    color: isActive ? null : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              // Back button
              if (_currentPage > 0)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _previousPage,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              
              if (_currentPage > 0) const SizedBox(width: 16),

              // Main action button
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentPageData.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: currentPageData.gradientColors[0].withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage
                                ? (_isPortuguese ? 'Vamos Começar!' : 'Let\'s Go!')
                                : (_isPortuguese ? 'Continuar' : 'Continue'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Footer text on last page
          if (isLastPage) ...[
            const SizedBox(height: 20),
            Text(
              _isPortuguese
                  ? 'Dica: Use o botão de ajuda (?) em qualquer tela para tutoriais'
                  : 'Tip: Use the help button (?) on any screen for tutorials',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Particle for background animation
class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Painter for particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update position
      particle.y = (particle.y + particle.speed * 0.01) % 1.0;
      
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Botão de emoji para demo de humor no onboarding
class _MoodButton extends StatefulWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
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
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isPressed 
                    ? widget.color.withValues(alpha: 0.3)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isPressed
                      ? widget.color
                      : Colors.white.withValues(alpha: 0.1),
                  width: _isPressed ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

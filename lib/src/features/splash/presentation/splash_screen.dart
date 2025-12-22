import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';

import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/migration_providers.dart';
import 'package:odyssey/src/features/auth/presentation/screens/account_migration_screen.dart';
import 'package:odyssey/src/providers/app_initializer_provider.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/onboarding/presentation/screens/landing_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _orbController;
  late AnimationController _logoController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  bool _minTimeElapsed = false;
  Timer? _timer;

  // Premium colors
  static const _primaryPurple = Color(0xFF667EEA);
  static const _secondaryPurple = Color(0xFF764BA2);
  static const _accentCyan = Color(0xFF06D6A0);
  static const _darkBg = Color(0xFF0A0A12);
  static const _deepDark = Color(0xFF050510);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    // Main entrance controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Pulsing glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Floating orbs
    _orbController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat(reverse: true);

    // Logo bounce entrance
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Loading shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Particle float
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Text animations
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    // Start animation sequence
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });
  }

  void _startInitialization() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appInitializerProvider.notifier).initialize();
      _startTimer();
    });
  }

  void _startTimer() {
    final splashEnabled = ref.read(settingsProvider).splashAnimationEnabled;
    final duration = splashEnabled
        ? const Duration(milliseconds: 3200)
        : Duration.zero;

    _timer = Timer(duration, () {
      if (mounted) {
        setState(() => _minTimeElapsed = true);
        _checkAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    _logoController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _checkAndNavigate() {
    final initStatus = ref.read(appInitializerProvider).status;
    final splashEnabled = ref.read(settingsProvider).splashAnimationEnabled;
    final timeCondition = !splashEnabled || _minTimeElapsed;

    if (initStatus == AppInitStatus.success && timeCondition) {
      _navigateToHome();
    }
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    final isAuthenticated = currentUser != null;

    Widget destination;

    if (isAuthenticated) {
      final needsMigration =
          ref.read(needsMigrationProvider).valueOrNull ?? false;

      if (needsMigration && !currentUser.isGuest) {
        destination = const AccountMigrationScreen();
      } else {
        destination = const OnboardingWrapper(child: OdysseyHome());
      }
    } else {
      destination = const LandingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appInitializerProvider, (previous, next) {
      if (next.status == AppInitStatus.success) {
        _checkAndNavigate();
      }
    });

    ref.listen(settingsProvider, (previous, next) {
      if (previous?.splashAnimationEnabled != next.splashAnimationEnabled) {
        if (!next.splashAnimationEnabled) {
          _checkAndNavigate();
        }
      }
    });

    final appState = ref.watch(appInitializerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _deepDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated gradient background
          _buildGradientBackground(size),

          // Floating orbs
          _buildFloatingOrbs(size),

          // Particle system
          _buildParticles(size),

          // Grid overlay (subtle tech feel)
          _buildGridOverlay(size),

          // Central content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Animated logo with glow
                _buildAnimatedLogo(),

                const SizedBox(height: 48),

                // App name with gradient
                _buildAppName(),

                const SizedBox(height: 20),

                // Tagline
                _buildTagline(),

                const Spacer(flex: 2),

                // Loading indicator
                _buildLoadingSection(appState.status),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Error overlay
          if (appState.status == AppInitStatus.error)
            _buildErrorOverlay(appState.errorMessage),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(Size size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.5 + (_pulseController.value * 0.1),
              colors: [
                _primaryPurple.withOpacity(
                  0.15 + _pulseController.value * 0.05,
                ),
                _secondaryPurple.withOpacity(0.08),
                _darkBg.withOpacity(0.95),
                _deepDark,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrbs(Size size) {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        final floatValue = math.sin(_orbController.value * math.pi * 2);
        final floatValue2 = math.cos(_orbController.value * math.pi * 2);

        return Stack(
          children: [
            // Large primary orb
            Positioned(
              top: size.height * 0.15 + (floatValue * 30),
              right: -80 + (floatValue2 * 20),
              child: _buildGlowOrb(
                size: 280,
                color: _primaryPurple,
                opacity: 0.12 + (_pulseController.value * 0.04),
              ),
            ),
            // Secondary orb
            Positioned(
              bottom: size.height * 0.2 + (floatValue2 * 25),
              left: -100 + (floatValue * 15),
              child: _buildGlowOrb(
                size: 320,
                color: _secondaryPurple,
                opacity: 0.1 + (_pulseController.value * 0.03),
              ),
            ),
            // Accent orb
            Positioned(
              top: size.height * 0.4 + (floatValue * 20),
              left: size.width * 0.6 + (floatValue2 * 10),
              child: _buildGlowOrb(
                size: 120,
                color: _accentCyan,
                opacity: 0.08 + (_pulseController.value * 0.02),
              ),
            ),
            // Small accent orb
            Positioned(
              bottom: size.height * 0.35 + (floatValue2 * 15),
              right: size.width * 0.2,
              child: _buildGlowOrb(size: 80, color: _accentCyan, opacity: 0.06),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlowOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.5),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _ParticlePainter(
            progress: _particleController.value,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildGridOverlay(Size size) {
    return Opacity(
      opacity: 0.02,
      child: CustomPaint(size: size, painter: _GridPainter()),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: ScaleTransition(
            scale: _logoScale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Subtle glow behind logo
                  BoxShadow(
                    color: _primaryPurple.withOpacity(
                      0.15 + (_pulseController.value * 0.1),
                    ),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Hero(
                tag: 'appLogo',
                child: Image.asset(
                  'assets/images/odyssey_logo_transparent.png',
                  width: 140,
                  height: 140,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textOpacity,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE8E3FF), Color(0xFFD4C7FF)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            AppLocalizations.of(context)?.language == 'Português'
                ? 'Sua Odisseia do\nAutoconhecimento'
                : 'Your Journey of\nSelf-Discovery',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          AppLocalizations.of(context)?.splashTagline ??
              '✨ Your journey starts here',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection(AppInitStatus status) {
    if (status == AppInitStatus.error) return const SizedBox(height: 60);

    return FadeTransition(
      opacity: _taglineOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modern loading bar
          _buildLoadingBar(),
          const SizedBox(height: 16),
          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              status == AppInitStatus.loading
                  ? (AppLocalizations.of(context)?.preparando ?? 'Preparing...')
                  : '',
              key: ValueKey(status),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.08),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                // Base gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryPurple.withOpacity(0.4),
                        _secondaryPurple.withOpacity(0.3),
                        _primaryPurple.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                // Shimmer effect
                Positioned(
                  left: -70 + (_shimmerController.value * 210),
                  child: Container(
                    width: 70,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorOverlay(String? errorMessage) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      color: const Color(0xFFEF4444).withOpacity(0.9),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)?.errorInit ??
                        'Oops! Something went wrong',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorMessage ?? 'Initialization error',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Retry button
                  GestureDetector(
                    onTap: () {
                      ref.read(appInitializerProvider.notifier).initialize();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryPurple, _secondaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPurple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)?.tentarNovamente ??
                                'Try Again',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CUSTOM PAINTERS ====================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final particleSize = random.nextDouble() * 2 + 1;
      final speed = random.nextDouble() * 0.5 + 0.3;
      final phase = random.nextDouble() * math.pi * 2;

      final offsetY = math.sin((progress * speed * math.pi * 2) + phase) * 30;
      final opacity = (math.sin((progress * math.pi * 2) + phase) + 1) / 4;

      paint.color = color.withOpacity(opacity * 0.2);

      canvas.drawCircle(Offset(baseX, baseY + offsetY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

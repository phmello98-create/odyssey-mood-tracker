import 'dart:async';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';
import 'package:odyssey/src/features/auth/presentation/login_screen.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/migration_providers.dart';
import 'package:odyssey/src/features/auth/presentation/screens/account_migration_screen.dart';
import 'package:odyssey/src/providers/app_initializer_provider.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  
  late Animation<double> _backgroundScale;
  late Animation<double> _backgroundFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;
  
  bool _minTimeElapsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    // Main controller para background
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Background com zoom cinematográfico suave
    _backgroundScale = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _backgroundFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Pulse controller para glow do logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer para loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Sequência de animações
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
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
        ? const Duration(milliseconds: 2800) 
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
    _textController.dispose();
    _shimmerController.dispose();
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
    
    // Verifica estado de autenticação via provider
    final currentUser = ref.read(currentUserProvider);
    final isAuthenticated = currentUser != null;
    
    Widget destination;
    
    if (isAuthenticated) {
      // Usuário autenticado - verifica se precisa de migração
      final needsMigration = ref.read(needsMigrationProvider).valueOrNull ?? false;
      
      if (needsMigration && !currentUser.isGuest) {
        // Precisa migrar dados para a nuvem
        destination = const AccountMigrationScreen();
      } else {
        // Vai para home com wrapper de onboarding
        destination = const OnboardingWrapper(
          child: OdysseyHome(),
        );
      }
    } else {
      // Não autenticado - vai para login com onboarding após login
      destination = const LoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
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
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background com imagem e parallax cinematográfico
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundScale.value,
                child: Opacity(
                  opacity: _backgroundFade.value,
                  child: Image.asset(
                    'assets/images/splash_focus.png',
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                  ),
                ),
              );
            },
          ),

          // Overlay escuro com vignette elegante
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.3),
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0A0A12).withValues(alpha: 0.3),
                  const Color(0xFF0A0A12).withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Gradient inferior para área de branding
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  const Color(0xFF0A0A12).withValues(alpha: 0.8),
                  const Color(0xFF0A0A12),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Área de branding centralizada
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                
                // Logo com glow pulsante
                AnimatedBuilder(
                  animation: Listenable.merge([_textController, _pulseController]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: _pulseAnimation.value),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                              BoxShadow(
                                color: const Color(0xFFA78BFA).withValues(alpha: _pulseAnimation.value * 0.5),
                                blurRadius: 100,
                                spreadRadius: 30,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0A0A12).withValues(alpha: 0.7),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Hero(
                              tag: 'appLogo',
                              child: Image.asset(
                                'assets/app_icon/icon_foreground.png',
                                width: 72,
                                height: 72,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Nome do app
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFD4BBFF),
                              Color(0xFFA78BFA),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'ODYSSEY',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 14,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        AppLocalizations.of(context)?.splashTagline ?? 'Your journey starts here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Loading indicator moderno
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: _buildLoadingIndicator(appState.status),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),

          // Error state
          if (appState.status == AppInitStatus.error)
            _buildErrorState(appState.errorMessage),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(AppInitStatus status) {
    if (status == AppInitStatus.error) return const SizedBox(height: 40);
    
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de loading com shimmer
            Container(
              width: 120,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: const Color(0xFF1A1A2E),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    // Shimmer
                    Positioned(
                      left: -60 + (_shimmerController.value * 180),
                      child: Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status text
            Text(
              status == AppInitStatus.loading ? 'Preparando...' : '',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ops! Algo deu errado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage ?? 'Erro na inicialização',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      ref.read(appInitializerProvider.notifier).initialize();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.tentarNovamente),
                      ],
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

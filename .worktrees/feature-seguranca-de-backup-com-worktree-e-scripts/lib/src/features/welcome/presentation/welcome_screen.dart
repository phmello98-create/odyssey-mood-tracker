import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';
import 'package:odyssey/src/features/auth/presentation/health_data_consent_screen.dart';
import 'package:odyssey/src/providers/locale_provider.dart';

/// Dados de uma página do onboarding
class WelcomePage {
  final String titlePt;
  final String titleEn;
  final String subtitlePt;
  final String subtitleEn;
  final IconData icon;
  final List<Color> gradientColors;
  final String? lottieAsset;

  const WelcomePage({
    required this.titlePt,
    required this.titleEn,
    required this.subtitlePt,
    required this.subtitleEn,
    required this.icon,
    required this.gradientColors,
    this.lottieAsset,
  });
}

/// Tela de boas-vindas para novos usuários
class WelcomeScreen extends ConsumerStatefulWidget {
  final String userName;

  const WelcomeScreen({
    super.key,
    required this.userName,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late AnimationController _pulseController;
  int _currentPage = 0;

  static const _pages = [
    WelcomePage(
      titlePt: 'Bem-vindo ao Odyssey! 👋',
      titleEn: 'Welcome to Odyssey! 👋',
      subtitlePt: 'Seu companheiro de produtividade e bem-estar.\nVamos começar essa jornada juntos!',
      subtitleEn: 'Your productivity and wellness companion.\nLet\'s start this journey together!',
      icon: Icons.rocket_launch_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    WelcomePage(
      titlePt: 'Registre seu Humor 🌈',
      titleEn: 'Track Your Mood 🌈',
      subtitlePt: 'Entenda seus padrões emocionais.\nRegistre como você se sente e descubra insights sobre você.',
      subtitleEn: 'Understand your emotional patterns.\nRecord how you feel and discover insights about yourself.',
      icon: Icons.mood_rounded,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    ),
    WelcomePage(
      titlePt: 'Foco com Pomodoro 🍅',
      titleEn: 'Focus with Pomodoro 🍅',
      subtitlePt: 'Aumente sua produtividade.\nUse o timer Pomodoro para manter o foco e fazer pausas estratégicas.',
      subtitleEn: 'Boost your productivity.\nUse the Pomodoro timer to stay focused and take strategic breaks.',
      icon: Icons.timer_rounded,
      gradientColors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    ),
    WelcomePage(
      titlePt: 'Crie Hábitos 💪',
      titleEn: 'Build Habits 💪',
      subtitlePt: 'Pequenas ações, grandes mudanças.\nAcompanhe seus hábitos diários e construa uma rotina saudável.',
      subtitleEn: 'Small actions, big changes.\nTrack your daily habits and build a healthy routine.',
      icon: Icons.trending_up_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    WelcomePage(
      titlePt: 'Organize Tarefas ✅',
      titleEn: 'Organize Tasks ✅',
      subtitlePt: 'Nunca esqueça o importante.\nGerencie suas tarefas e conquiste seus objetivos.',
      subtitleEn: 'Never forget what matters.\nManage your tasks and achieve your goals.',
      icon: Icons.check_circle_rounded,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
    WelcomePage(
      titlePt: 'Ganhe Recompensas 🏆',
      titleEn: 'Earn Rewards 🏆',
      subtitlePt: 'Cada ação conta!\nGanhe XP, suba de nível e desbloqueie conquistas enquanto melhora sua vida.',
      subtitleEn: 'Every action counts!\nEarn XP, level up and unlock achievements while improving your life.',
      icon: Icons.emoji_events_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
  ];

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final service = ref.read(welcomeServiceProvider);
    await service.completeFirstTime();
    
    if (!mounted) return;
    
    // Verificar se precisa de consentimento LGPD
    final hasConsent = await HealthDataConsentScreen.hasConsent();
    
    if (!hasConsent && mounted) {
      // Mostrar tela de consentimento antes de ir para home
      final accepted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const HealthDataConsentScreen(),
        ),
      );
      
      // Se não aceitou, mostra aviso mas continua (dados ficam apenas locais)
      if (accepted != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPortuguese 
                  ? 'Você pode dar seu consentimento depois nas configurações.'
                  : 'You can give your consent later in settings.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OdysseyHome(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // Background gradient animado
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final page = _pages[_currentPage];
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.5 + (_pulseController.value * 0.2),
                    colors: [
                      page.gradientColors[0].withValues(alpha: 0.3),
                      page.gradientColors[1].withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),

          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header com skip button
                _buildHeader(),

                // PageView com as páginas
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Indicadores e botão
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo pequeno
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Image.asset(
                  'assets/app_icon/icon_foreground.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ODYSSEY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            GestureDetector(
              onTap: _skipOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildPage(WelcomePage page, int index) {
    final isCurrentPage = _currentPage == index;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCurrentPage ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone grande com glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        page.gradientColors[0].withValues(alpha: 0.3),
                        page.gradientColors[1].withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                      color: page.gradientColors[0].withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradientColors[0].withValues(alpha: 0.3 + _pulseController.value * 0.2),
                        blurRadius: 40 + _pulseController.value * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 64,
                    color: Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Título
            Text(
              _isPortuguese ? page.titlePt : page.titleEn,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Subtítulo
            Text(
              _isPortuguese ? page.subtitlePt : page.subtitleEn,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(double bottomPadding) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(32, 20, 32, bottomPadding + 24),
      child: Column(
        children: [
          // Indicadores de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? _pages[_currentPage].gradientColors[0]
                      : Colors.white.withValues(alpha: 0.2),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Botão principal
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _pages[_currentPage].gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _pages[_currentPage].gradientColors[0].withValues(alpha: 0.4),
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
                          ? (_isPortuguese ? 'Começar!' : 'Get Started!')
                          : (_isPortuguese ? 'Continuar' : 'Continue'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Texto de rodapé na última página
          if (isLastPage) ...[
            const SizedBox(height: 16),
            Text(
              _isPortuguese
                  ? 'Você pode revisitar este tutorial nas configurações'
                  : 'You can revisit this tutorial in settings',
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

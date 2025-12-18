import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/migration_providers.dart';
import 'package:odyssey/src/features/auth/presentation/screens/account_migration_screen.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/features/welcome/presentation/welcome_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  String? _loadingMethod;

  // Cores do tema
  static const _primaryGradient = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  String _t(String pt, String en) => _isPortuguese ? pt : en;

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _loadingMethod = 'google');

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInWithGoogle();

      result.when(
        success: (user, message) {
          if (mounted) {
            // Para login com conta real, verifica se precisa migrar dados
            _checkMigrationAndNavigate(isGuest: false);
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            _showError(message);
          }
        },
        loading: () {},
        initial: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _loadingMethod = null);
      }
    }
  }

  Future<void> _handleGuestMode() async {
    HapticFeedback.lightImpact();

    // Verificar se existem dados locais antes de continuar
    final hasLocalData = await _checkLocalDataExists();

    if (hasLocalData && mounted) {
      // Mostrar diálogo de escolha
      final shouldRestore = await _showRestoreDataDialog();

      if (!mounted) return;

      if (shouldRestore == null) {
        // Usuário cancelou
        return;
      }

      if (!shouldRestore) {
        // Usuário quer começar do zero - limpar dados locais
        await _clearLocalData();
      }
      // Se shouldRestore == true, mantém os dados locais
    }

    setState(() => _loadingMethod = 'guest');

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInAsGuest();

      result.when(
        success: (user, message) {
          if (mounted) {
            // Guest não precisa de migração, vai direto para home
            _navigateToHome();
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            _showError(message);
          }
        },
        loading: () {},
        initial: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _loadingMethod = null);
      }
    }
  }

  /// Verifica se existem dados locais salvos
  Future<bool> _checkLocalDataExists() async {
    debugPrint('[LoginScreen] Verificando dados locais...');
    try {
      // Verificar várias caixas Hive para dados locais
      // Usando nomes corretos das boxes
      final checks = await Future.wait([
        _checkHiveBoxHasData('habits'),
        _checkHiveBoxHasData('mood_records'),
        _checkHiveBoxHasData('moods'),
        _checkHiveBoxHasData('tasks'),
        _checkHiveBoxHasData('notes_v2'),
        _checkHiveBoxHasData('notes'),
        _checkHiveBoxHasData('time_tracking_records'),
        _checkHiveBoxHasData('books_v3'),
        _checkHiveBoxHasData('books'),
        _checkHiveBoxHasData('diary_entries'),
      ]);

      final hasData = checks.any((hasData) => hasData);
      debugPrint('[LoginScreen] Dados locais encontrados: $hasData');
      return hasData;
    } catch (e) {
      debugPrint('[LoginScreen] Erro ao verificar dados locais: $e');
      return false;
    }
  }

  Future<bool> _checkHiveBoxHasData(String boxName) async {
    try {
      // Verificar se a box existe e tem dados
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        return box.isNotEmpty;
      }

      // Tentar abrir a box
      final box = await Hive.openBox(boxName);
      final hasData = box.isNotEmpty;

      if (hasData) {
        debugPrint('[LoginScreen] Box $boxName tem ${box.length} itens');
      }

      return hasData;
    } catch (e) {
      // Box não existe ou erro ao abrir - sem dados
      return false;
    }
  }

  /// Limpa todos os dados locais (mesma lógica do account_deletion_service)
  Future<void> _clearLocalData() async {
    debugPrint('[LoginScreen] Iniciando limpeza de dados locais...');

    try {
      // Lista completa de boxes de dados do usuário
      final boxNames = [
        // Dados principais
        'mood_records',
        'moods',
        'diary_entries',
        'notes_v2',
        'notes',
        'tasks',
        'habits',
        'habit_completions',
        'books_v3',
        'books',
        'quotes',
        'time_tracking_records',
        // Gamificação
        'gamification',
        'achievements',
        // Outros
        'suggestions',
        'suggestion_analytics',
        'study_sessions',
        'vocabulary_items',
        'immersion_logs',
        // Onboarding (resetar para nova experiência)
        'onboarding_progress',
      ];

      for (final name in boxNames) {
        try {
          // Fechar a box se estiver aberta
          if (Hive.isBoxOpen(name)) {
            final box = Hive.box(name);
            await box.clear();
            await box.close();
          }
          // Deletar do disco
          await Hive.deleteBoxFromDisk(name);
          debugPrint('[LoginScreen] ✓ Box deletada: $name');
        } catch (e) {
          debugPrint('[LoginScreen] Erro ao deletar box $name: $e');
        }
      }

      // Limpar também algumas preferências específicas
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        'hasCompletedOnboarding',
        'firstStepsDismissed',
        'completedFirstSteps',
        'lastMoodDate',
        'streakCount',
        'totalXp',
        'currentLevel',
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('[LoginScreen] ✓ Limpeza de dados concluída!');
    } catch (e) {
      debugPrint('[LoginScreen] Erro geral ao limpar dados: $e');
    }
  }

  /// Mostra diálogo perguntando se quer restaurar dados
  Future<bool?> _showRestoreDataDialog() async {
    final isPortuguese =
        ref.read(localeStateProvider).currentLocale.languageCode == 'pt';

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (ctx) => _RestoreDataSheet(
        isPortuguese: isPortuguese,
        onRestore: () => Navigator.pop(ctx, true),
        onStartFresh: () => Navigator.pop(ctx, false),
        onCancel: () => Navigator.pop(ctx, null),
      ),
    );
  }

  /// Verifica se precisa de migração e navega para a tela apropriada
  Future<void> _checkMigrationAndNavigate({required bool isGuest}) async {
    if (isGuest) {
      _navigateToHome();
      return;
    }

    // Verifica se precisa migrar dados locais para a nuvem
    final needsMigration = await ref.read(needsMigrationProvider.future);

    if (needsMigration && mounted) {
      // Navega para tela de migração
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AccountMigrationScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // Verifica se deve mostrar o onboarding de boas-vindas
    final welcomeService = ref.read(welcomeServiceProvider);
    final welcomeType = welcomeService.determineWelcomeType();

    // Se é primeira vez, mostra o Welcome Screen
    if (welcomeType == WelcomeType.firstTime) {
      final user = ref.read(currentUserProvider);
      final userName = user?.displayName ?? 'Usuário';

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => WelcomeScreen(userName: userName),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // Caso contrário, vai para home (o welcome back sheet será mostrado lá)
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleLanguage() {
    HapticFeedback.selectionClick();
    final notifier = ref.read(localeStateProvider.notifier);
    if (_isPortuguese) {
      notifier.setLocale(const Locale('en', 'US'));
    } else {
      notifier.setLocale(const Locale('pt', 'BR'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/splash_focus.png',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),

          // Gradient overlays
          _buildGradientOverlay(),

          // Animated particles/glow effect
          _buildAnimatedGlow(),

          // Main content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(),

                      const Spacer(flex: 2),

                      // Logo and branding
                      _buildBranding(),

                      const Spacer(flex: 1),

                      // Login buttons
                      _buildLoginSection(isLoading),

                      SizedBox(height: bottomPadding + 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.3, 0.65, 0.9],
        ),
      ),
    );
  }

  Widget _buildAnimatedGlow() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          bottom: -100,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.2,
                colors: [
                  _primaryGradient[1].withValues(
                    alpha: 0.15 + (_pulseController.value * 0.1),
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildLanguageSelector()],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return GestureDetector(
      onTap: _toggleLanguage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _isPortuguese ? _buildBrazilFlag() : _buildUSFlag(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isPortuguese ? 'PT-BR' : 'EN-US',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrazilFlag() {
    return Container(
      color: const Color(0xFF009739),
      child: Center(
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 10,
            height: 10,
            color: const Color(0xFFFEDD00),
          ),
        ),
      ),
    );
  }

  Widget _buildUSFlag() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB22234),
            Colors.white,
            Color(0xFFB22234),
            Colors.white,
            Color(0xFFB22234),
          ],
          stops: [0.0, 0.2, 0.4, 0.6, 0.8],
        ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(width: 10, height: 8, color: const Color(0xFF3C3B6E)),
      ),
    );
  }

  Widget _buildBranding() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
              ),
            ),
        child: Column(
          children: [
            // Logo com glow
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGradient[1].withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/app_icon/icon_foreground.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 28),

            // App name com gradiente
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
              ).createShader(bounds),
              child: const Text(
                'ODYSSEY',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tagline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _t(
                  'Sua jornada de foco começa aqui',
                  'Your focus journey starts here',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginSection(bool isLoading) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Google button
                    _buildGoogleButton(isLoading),

                    const SizedBox(height: 12),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _t('ou', 'or'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Guest button
                    _buildGuestButton(isLoading),

                    const SizedBox(height: 20),

                    // Terms
                    Text(
                      _t(
                        'Ao continuar, você concorda com nossos\nTermos de Uso e Política de Privacidade',
                        'By continuing, you agree to our\nTerms of Use and Privacy Policy',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    final isLoadingGoogle = _loadingMethod == 'google';

    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleSignIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : _handleGoogleSignIn,
            child: Center(
              child: isLoadingGoogle
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.black54),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/google_logo.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t('Continuar com Google', 'Continue with Google'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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

  Widget _buildGuestButton(bool isLoading) {
    final isLoadingGuest = _loadingMethod == 'guest';

    return GestureDetector(
      onTap: isLoading ? null : _handleGuestMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : _handleGuestMode,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: isLoadingGuest
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t('Entrar como Visitante', 'Continue as Guest'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
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

/// Sheet para escolher se quer restaurar dados locais ou começar do zero
class _RestoreDataSheet extends StatelessWidget {
  final bool isPortuguese;
  final VoidCallback onRestore;
  final VoidCallback onStartFresh;
  final VoidCallback onCancel;

  const _RestoreDataSheet({
    required this.isPortuguese,
    required this.onRestore,
    required this.onStartFresh,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Ícone
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restore_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Título
                Text(
                  isPortuguese ? 'Dados Encontrados!' : 'Data Found!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Descrição
                Text(
                  isPortuguese
                      ? 'Encontramos dados salvos no seu dispositivo de uma sessão anterior.\n\nO que você gostaria de fazer?'
                      : 'We found data saved on your device from a previous session.\n\nWhat would you like to do?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Opção 1: Restaurar dados
                _buildOptionCard(
                  icon: Icons.cloud_download_rounded,
                  title: isPortuguese ? 'Restaurar Dados' : 'Restore Data',
                  description: isPortuguese
                      ? 'Continuar de onde parei, mantendo todos os hábitos, notas e progresso.'
                      : 'Continue from where I left off, keeping all habits, notes and progress.',
                  color: const Color(0xFF10B981),
                  onTap: onRestore,
                ),

                const SizedBox(height: 12),

                // Opção 2: Começar do zero
                _buildOptionCard(
                  icon: Icons.restart_alt_rounded,
                  title: isPortuguese ? 'Começar do Zero' : 'Start Fresh',
                  description: isPortuguese
                      ? 'Apagar tudo e iniciar uma nova jornada.'
                      : 'Clear everything and start a new journey.',
                  color: const Color(0xFFF59E0B),
                  onTap: onStartFresh,
                ),

                const SizedBox(height: 16),

                // Cancelar
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    isPortuguese ? 'Cancelar' : 'Cancel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'dart:math' as math;
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
import 'package:odyssey/src/features/auth/presentation/signup_screen.dart';
import 'package:odyssey/src/features/auth/presentation/forgot_password_screen.dart';
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
  late AnimationController _floatController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _loadingMethod;
  bool _showEmailLogin = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Cores premium
  static const _primaryGradient = [
    Color(0xFF667EEA), // Indigo suave
    Color(0xFF764BA2), // Roxo elegante
  ];

  static const _accentColor = Color(0xFF06D6A0); // Verde vibrante
  static const _darkBg = Color(0xFF0D0D1A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  String _t(String pt, String en) => _isPortuguese ? pt : en;

  // ==================== AUTH HANDLERS ====================

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loadingMethod = 'google';
      _errorMessage = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInWithGoogle();

      result.when(
        success: (user, message) {
          if (mounted) {
            _checkMigrationAndNavigate(isGuest: false);
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            setState(() => _errorMessage = message);
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

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _loadingMethod = 'email';
      _errorMessage = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      result.when(
        success: (user, message) {
          if (mounted) {
            _checkMigrationAndNavigate(isGuest: false);
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            setState(() => _errorMessage = message);
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

    final hasLocalData = await _checkLocalDataExists();

    if (hasLocalData && mounted) {
      final shouldRestore = await _showRestoreDataDialog();

      if (!mounted) return;

      if (shouldRestore == null) return;

      if (!shouldRestore) {
        await _clearLocalData();
      }
    }

    setState(() => _loadingMethod = 'guest');

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInAsGuest();

      result.when(
        success: (user, message) {
          if (mounted) {
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

  void _navigateToSignup() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignupScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((success) {
      if (success == true && mounted) {
        _checkMigrationAndNavigate(isGuest: false);
      }
    });
  }

  void _navigateToForgotPassword() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  Future<bool> _checkLocalDataExists() async {
    try {
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

      return checks.any((hasData) => hasData);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkHiveBoxHasData(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        return box.isNotEmpty;
      }

      final box = await Hive.openBox(boxName);
      return box.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final boxNames = [
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
        'gamification',
        'achievements',
        'suggestions',
        'suggestion_analytics',
        'study_sessions',
        'vocabulary_items',
        'immersion_logs',
        'onboarding_progress',
      ];

      for (final name in boxNames) {
        try {
          if (Hive.isBoxOpen(name)) {
            final box = Hive.box(name);
            await box.clear();
            await box.close();
          }
          await Hive.deleteBoxFromDisk(name);
        } catch (e) {
          debugPrint('[LoginScreen] Erro ao deletar box $name: $e');
        }
      }

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
    } catch (e) {
      debugPrint('[LoginScreen] Erro geral ao limpar dados: $e');
    }
  }

  Future<bool?> _showRestoreDataDialog() async {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (ctx) => _RestoreDataSheet(
        isPortuguese: _isPortuguese,
        onRestore: () => Navigator.pop(ctx, true),
        onStartFresh: () => Navigator.pop(ctx, false),
        onCancel: () => Navigator.pop(ctx, null),
      ),
    );
  }

  Future<void> _checkMigrationAndNavigate({required bool isGuest}) async {
    if (isGuest) {
      _navigateToHome();
      return;
    }

    final needsMigration = await ref.read(needsMigrationProvider.future);

    if (needsMigration && mounted) {
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
    final welcomeService = ref.read(welcomeServiceProvider);
    final welcomeType = welcomeService.determineWelcomeType();

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
        backgroundColor: const Color(0xFFE53935),
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background with orbs
          _buildAnimatedBackground(size),

          // Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(),

                      const Spacer(flex: 1),

                      // Logo and branding
                      _buildBranding(),

                      const Spacer(flex: 1),

                      // Login section (forms and buttons)
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

  Widget _buildAnimatedBackground(Size size) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _darkBg,
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
              ],
            ),
          ),
        ),

        // Floating orbs
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final floatValue = math.sin(_floatController.value * math.pi) * 20;
            return Stack(
              children: [
                // Large primary orb
                Positioned(
                  top: size.height * 0.1 + floatValue,
                  right: -100,
                  child: _buildGlowOrb(
                    size: 300,
                    color: _primaryGradient[0],
                    opacity: 0.15 + (_pulseController.value * 0.05),
                  ),
                ),
                // Secondary orb
                Positioned(
                  bottom: size.height * 0.3 - floatValue,
                  left: -150,
                  child: _buildGlowOrb(
                    size: 350,
                    color: _primaryGradient[1],
                    opacity: 0.12 + (_pulseController.value * 0.03),
                  ),
                ),
                // Accent orb
                Positioned(
                  top: size.height * 0.5 + floatValue * 0.5,
                  right: size.width * 0.3,
                  child: _buildGlowOrb(
                    size: 150,
                    color: _accentColor,
                    opacity: 0.08 + (_pulseController.value * 0.02),
                  ),
                ),
              ],
            );
          },
        ),

        // Subtle grid pattern overlay
        Opacity(
          opacity: 0.03,
          child: CustomPaint(size: size, painter: _GridPainter()),
        ),
      ],
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
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFlagIcon(_isPortuguese),
            const SizedBox(width: 8),
            Text(
              _isPortuguese ? 'PT' : 'EN',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagIcon(bool isPT) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: isPT ? _buildBRFlag() : _buildUSFlag(),
    );
  }

  Widget _buildBRFlag() {
    return Stack(
      children: [
        Container(color: const Color(0xFF009739)), // Verde
        Center(
          child: Transform.rotate(
            angle: 45 * 3.14159 / 180,
            child: Container(
              width: 14,
              height: 14,
              color: const Color(0xFFFEDD00), // Amarelo
            ),
          ),
        ),
        Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF012169), // Azul
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUSFlag() {
    return Stack(
      children: [
        Container(color: Colors.white),
        Column(
          children: List.generate(7, (index) {
            return Expanded(
              child: Container(
                color: index % 2 == 0 ? const Color(0xFFB22234) : Colors.white,
              ),
            );
          }),
        ),
        Container(
          width: 10,
          height: 10,
          color: const Color(0xFF3C3B6E), // Azul
          child: const Center(
            child: Icon(Icons.star, color: Colors.white, size: 6),
          ),
        ),
      ],
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
            // Logo - clean and simple
            Hero(
              tag: 'appLogo',
              child: Image.asset(
                'assets/images/odyssey_logo_transparent.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 32),

            // Inspirational subtitle (since logo already has "ODYSSEY")
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.85),
                  _primaryGradient[0].withOpacity(0.9),
                ],
              ).createShader(bounds),
              child: Text(
                _t(
                  'Sua Odisseia do\nAutoconhecimento',
                  'Your Journey of\nSelf-Discovery',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tagline with features
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFeatureChip('🧠', _t('Humor', 'Mood')),
                  _buildFeatureDot(),
                  _buildFeatureChip('⏱️', _t('Foco', 'Focus')),
                  _buildFeatureDot(),
                  _buildFeatureChip('🌱', _t('Hábitos', 'Habits')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _showTermsOfUse() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LegalDocumentSheet(
        title: _t('Termos de Uso', 'Terms of Use'),
        content: _t(
          '''
TERMOS DE USO - ODYSSEY

Última atualização: Dezembro 2025

Bem-vindo ao Odyssey! Ao usar nosso aplicativo, você concorda com estes termos.

1. ACEITAÇÃO DOS TERMOS
Ao acessar e usar o Odyssey, você aceita e concorda em cumprir estes Termos de Uso. Se você não concordar, por favor não use o aplicativo.

2. DESCRIÇÃO DO SERVIÇO
O Odyssey é um aplicativo de produtividade pessoal e bem-estar que oferece:
• Rastreamento de humor e emoções
• Gerenciamento de hábitos e tarefas
• Timer Pomodoro para foco
• Diário pessoal
• Biblioteca de leitura
• Gamificação para motivação

3. CONTA DO USUÁRIO
• Você pode usar o app como visitante (dados locais) ou criar uma conta
• Você é responsável por manter a segurança de sua conta
• Não compartilhe suas credenciais com terceiros

4. USO ACEITÁVEL
Você concorda em:
• Usar o app apenas para fins pessoais e legais
• Não tentar hackear, modificar ou prejudicar o serviço
• Não usar o app para atividades ilegais ou prejudiciais
• Respeitar outros usuários na comunidade

5. PROPRIEDADE INTELECTUAL
• O Odyssey e todo seu conteúdo são protegidos por direitos autorais
• Você não pode copiar, modificar ou distribuir nosso código ou design
• Suas anotações e dados pessoais permanecem seus

6. DADOS E BACKUP
• Seus dados são armazenados localmente no dispositivo
• Usuários com conta podem sincronizar na nuvem (Firebase)
• Recomendamos fazer backups regulares
• Não nos responsabilizamos por perda de dados em dispositivos

7. ASSINATURA PRO (QUANDO DISPONÍVEL)
• Recursos adicionais podem ser oferecidos via assinatura
• Pagamentos são processados pela loja de aplicativos
• Cancelamentos seguem as políticas da loja

8. ISENÇÃO DE GARANTIAS
• O app é fornecido "como está"
• Não garantimos que será ininterrupto ou livre de erros
• Use as recomendações de bem-estar como complemento, não substituto de aconselhamento profissional

9. LIMITAÇÃO DE RESPONSABILIDADE
Não nos responsabilizamos por:
• Danos diretos ou indiretos do uso do app
• Perda de dados ou interrupção de serviço
• Ações de terceiros

10. MODIFICAÇÕES
• Podemos atualizar estes termos periodicamente
• Continuando a usar o app, você aceita as modificações
• Mudanças significativas serão notificadas

11. LEI APLICÁVEL
Estes termos são regidos pelas leis do Brasil (LGPD aplicável).

12. CONTATO
Para dúvidas sobre estes termos:
• Email: suporte@odysseyapp.com.br

Ao usar o Odyssey, você confirma que leu e concorda com estes Termos de Uso.
''',
          '''
TERMS OF USE - ODYSSEY

Last updated: December 2025

Welcome to Odyssey! By using our app, you agree to these terms.

1. ACCEPTANCE OF TERMS
By accessing and using Odyssey, you accept and agree to comply with these Terms of Use. If you disagree, please do not use the app.

2. SERVICE DESCRIPTION
Odyssey is a personal productivity and wellness app that offers:
• Mood and emotion tracking
• Habit and task management
• Pomodoro timer for focus
• Personal diary
• Reading library
• Gamification for motivation

3. USER ACCOUNT
• You can use the app as a guest (local data) or create an account
• You are responsible for maintaining the security of your account
• Do not share your credentials with third parties

4. ACCEPTABLE USE
You agree to:
• Use the app only for personal and legal purposes
• Not attempt to hack, modify, or harm the service
• Not use the app for illegal or harmful activities
• Respect other users in the community

5. INTELLECTUAL PROPERTY
• Odyssey and all its content are protected by copyright
• You may not copy, modify, or distribute our code or design
• Your notes and personal data remain yours

6. DATA AND BACKUP
• Your data is stored locally on the device
• Account users can sync to the cloud (Firebase)
• We recommend regular backups
• We are not responsible for data loss on devices

7. PRO SUBSCRIPTION (WHEN AVAILABLE)
• Additional features may be offered via subscription
• Payments are processed by the app store
• Cancellations follow store policies

8. DISCLAIMER OF WARRANTIES
• The app is provided "as is"
• We do not guarantee it will be uninterrupted or error-free
• Use wellness recommendations as a complement, not a substitute for professional advice

9. LIMITATION OF LIABILITY
We are not responsible for:
• Direct or indirect damages from using the app
• Data loss or service interruption
• Actions of third parties

10. MODIFICATIONS
• We may update these terms periodically
• By continuing to use the app, you accept the modifications
• Significant changes will be notified

11. APPLICABLE LAW
These terms are governed by Brazilian laws (LGPD applicable).

12. CONTACT
For questions about these terms:
• Email: support@odysseyapp.com

By using Odyssey, you confirm that you have read and agree to these Terms of Use.
''',
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LegalDocumentSheet(
        title: _t('Política de Privacidade', 'Privacy Policy'),
        content: _t(
          '''
POLÍTICA DE PRIVACIDADE - ODYSSEY

Última atualização: Dezembro 2025

Sua privacidade é importante para nós. Esta política explica como coletamos, usamos e protegemos seus dados.

1. DADOS QUE COLETAMOS

Dados fornecidos por você:
• Nome e email (se criar conta)
• Registros de humor e emoções
• Hábitos e tarefas
• Entradas de diário
• Preferências do app

Dados coletados automaticamente:
• Informações do dispositivo (para compatibilidade)
• Estatísticas de uso (anônimas, para melhorias)

Dados que NÃO coletamos:
• Localização precisa
• Contatos
• Mensagens pessoais
• Informações bancárias

2. COMO USAMOS SEUS DADOS

Seus dados são usados para:
• Fornecer os serviços do app
• Sincronizar entre dispositivos (se usar conta)
• Gerar estatísticas e insights pessoais
• Melhorar o aplicativo

Seus dados NÃO são usados para:
• Publicidade direcionada
• Venda a terceiros
• Criação de perfis de marketing

3. ARMAZENAMENTO E SEGURANÇA

• Dados locais: Armazenados criptografados no seu dispositivo
• Dados na nuvem: Firebase (Google Cloud) com criptografia
• Backups: Criptografados e protegidos por sua conta

Medidas de segurança:
• Criptografia de ponta a ponta para dados sensíveis
• Autenticação segura via Google ou email
• Não armazenamos senhas em texto simples

4. COMPARTILHAMENTO DE DADOS

NÃO compartilhamos seus dados pessoais com terceiros, exceto:
• Serviços essenciais (Firebase para sync)
• Quando exigido por lei
• Com seu consentimento explícito

5. SEUS DIREITOS (LGPD/GDPR)

Você tem direito a:
• Acessar seus dados a qualquer momento
• Corrigir informações incorretas
• Excluir sua conta e todos os dados
• Exportar seus dados (backup)
• Revogar consentimentos
• Usar o app anonimamente (modo visitante)

6. RETENÇÃO DE DADOS

• Dados locais: Permanecem até você deletar
• Dados na nuvem: Mantidos enquanto conta ativa
• Após exclusão de conta: Removidos em até 30 dias

7. DADOS DE CRIANÇAS

• O Odyssey não é destinado a menores de 13 anos
• Não coletamos intencionalmente dados de crianças
• Se identificarmos, excluímos imediatamente

8. COOKIES E RASTREAMENTO

• Não usamos cookies de terceiros
• Não usamos rastreadores de publicidade
• Analytics são anônimos e agregados

9. ALTERAÇÕES NESTA POLÍTICA

• Podemos atualizar esta política
• Você será notificado sobre mudanças significativas
• A data de atualização estará sempre visível

10. CONTATO DO DPO

Para exercer seus direitos ou tirar dúvidas:
• Email: privacidade@odysseyapp.com.br
• Dentro do app: Configurações > Privacidade

11. CONSENTIMENTO

Ao usar o Odyssey, você consente com esta Política de Privacidade.

Temos o compromisso de proteger sua privacidade e seus dados pessoais.
''',
          '''
PRIVACY POLICY - ODYSSEY

Last updated: December 2025

Your privacy is important to us. This policy explains how we collect, use, and protect your data.

1. DATA WE COLLECT

Data you provide:
• Name and email (if creating an account)
• Mood and emotion records
• Habits and tasks
• Diary entries
• App preferences

Automatically collected data:
• Device information (for compatibility)
• Usage statistics (anonymous, for improvements)

Data we DO NOT collect:
• Precise location
• Contacts
• Personal messages
• Banking information

2. HOW WE USE YOUR DATA

Your data is used to:
• Provide app services
• Sync between devices (if using account)
• Generate personal statistics and insights
• Improve the application

Your data is NOT used for:
• Targeted advertising
• Sale to third parties
• Marketing profile creation

3. STORAGE AND SECURITY

• Local data: Stored encrypted on your device
• Cloud data: Firebase (Google Cloud) with encryption
• Backups: Encrypted and protected by your account

Security measures:
• End-to-end encryption for sensitive data
• Secure authentication via Google or email
• We don't store passwords in plain text

4. DATA SHARING

We DO NOT share your personal data with third parties, except:
• Essential services (Firebase for sync)
• When required by law
• With your explicit consent

5. YOUR RIGHTS (LGPD/GDPR)

You have the right to:
• Access your data at any time
• Correct incorrect information
• Delete your account and all data
• Export your data (backup)
• Revoke consents
• Use the app anonymously (guest mode)

6. DATA RETENTION

• Local data: Remains until you delete
• Cloud data: Kept while account is active
• After account deletion: Removed within 30 days

7. CHILDREN'S DATA

• Odyssey is not intended for children under 13
• We do not intentionally collect children's data
• If identified, we delete immediately

8. COOKIES AND TRACKING

• We don't use third-party cookies
• We don't use advertising trackers
• Analytics are anonymous and aggregated

9. CHANGES TO THIS POLICY

• We may update this policy
• You will be notified of significant changes
• The update date will always be visible

10. DPO CONTACT

To exercise your rights or ask questions:
• Email: privacy@odysseyapp.com
• In-app: Settings > Privacy

11. CONSENT

By using Odyssey, you consent to this Privacy Policy.

We are committed to protecting your privacy and personal data.
''',
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email login form (animated)
                    AnimatedCrossFade(
                      firstChild: _buildSocialButtons(isLoading),
                      secondChild: _buildEmailForm(isLoading),
                      crossFadeState: _showEmailLogin
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      sizeCurve: Curves.easeInOut,
                    ),

                    const SizedBox(height: 20),

                    // Terms - clickable links
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: _t(
                              'Ao continuar, você concorda com nossos\n',
                              'By continuing, you agree to our\n',
                            ),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _showTermsOfUse,
                              child: Text(
                                _t('Termos de Uso', 'Terms of Use'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _primaryGradient[0],
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _primaryGradient[0],
                                ),
                              ),
                            ),
                          ),
                          TextSpan(text: _t(' e ', ' and ')),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _showPrivacyPolicy,
                              child: Text(
                                _t('Política de Privacidade', 'Privacy Policy'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _primaryGradient[0],
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _primaryGradient[0],
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildSocialButtons(bool isLoading) {
    return Column(
      children: [
        // Google button
        _buildGoogleButton(isLoading),
        const SizedBox(height: 12),

        // Email button
        _buildEmailToggleButton(isLoading),
        const SizedBox(height: 16),

        // Divider
        _buildDivider(),
        const SizedBox(height: 16),

        // Guest button
        _buildGuestButton(isLoading),
        const SizedBox(height: 16),

        // Create account link
        _buildCreateAccountLink(),
      ],
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() {
                _showEmailLogin = false;
                _errorMessage = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            _t('Entrar com Email', 'Sign in with Email'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _t('Digite seu email', 'Enter your email');
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return _t('Email inválido', 'Invalid email');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          _buildTextField(
            controller: _passwordController,
            label: _t('Senha', 'Password'),
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _t('Digite sua senha', 'Enter your password');
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _navigateToForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                _t('Esqueceu a senha?', 'Forgot password?'),
                style: TextStyle(
                  fontSize: 13,
                  color: _primaryGradient[0],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Login button
          _buildPrimaryButton(
            onPressed: _handleEmailSignIn,
            label: _t('Entrar', 'Sign In'),
            isLoading: _loadingMethod == 'email',
            isDisabled: isLoading,
          ),
          const SizedBox(height: 16),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _t('Não tem conta? ', 'Don\'t have an account? '),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _navigateToSignup,
                child: Text(
                  _t('Criar agora', 'Create now'),
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: _primaryGradient[0], size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryGradient[0], width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    final isLoadingGoogle = _loadingMethod == 'google';

    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleSignIn,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t('Continuar com Google', 'Continue with Google'),
                          style: const TextStyle(
                            fontSize: 15,
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

  Widget _buildEmailToggleButton(bool isLoading) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showEmailLogin = true);
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_rounded,
                color: Colors.white.withOpacity(0.95),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                _t('Entrar com Email', 'Sign in with Email'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _t('ou', 'or'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
      ],
    );
  }

  Widget _buildGuestButton(bool isLoading) {
    final isLoadingGuest = _loadingMethod == 'guest';

    return GestureDetector(
      onTap: isLoading ? null : _handleGuestMode,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : _handleGuestMode,
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Center(
              child: isLoadingGuest
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t('Explorar como Visitante', 'Explore as Guest'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
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

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _t('Primeira vez? ', 'First time here? '),
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        GestureDetector(
          onTap: _navigateToSignup,
          child: Text(
            _t('Criar conta', 'Create account'),
            style: TextStyle(
              color: _accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String label,
    required bool isLoading,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: isDisabled || isLoading ? null : onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDisabled
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : _primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ==================== GRID PAINTER ====================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

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

// ==================== RESTORE DATA SHEET ====================

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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.15),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Icon with gradient
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 25,
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

                Text(
                  isPortuguese ? 'Dados Encontrados! 🎉' : 'Data Found! 🎉',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  isPortuguese
                      ? 'Encontramos dados salvos no seu dispositivo.\n\nO que você gostaria de fazer?'
                      : 'We found data saved on your device.\n\nWhat would you like to do?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                _buildOptionCard(
                  icon: Icons.cloud_download_rounded,
                  title: isPortuguese ? 'Restaurar Dados' : 'Restore Data',
                  description: isPortuguese
                      ? 'Continuar de onde parei'
                      : 'Continue where I left off',
                  color: const Color(0xFF06D6A0),
                  onTap: onRestore,
                ),

                const SizedBox(height: 12),

                _buildOptionCard(
                  icon: Icons.restart_alt_rounded,
                  title: isPortuguese ? 'Começar do Zero' : 'Start Fresh',
                  description: isPortuguese
                      ? 'Iniciar uma nova jornada'
                      : 'Start a new journey',
                  color: const Color(0xFFFFB74D),
                  onTap: onStartFresh,
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    isPortuguese ? 'Cancelar' : 'Cancel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
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
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
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

/// Sheet para exibir documentos legais (Termos e Privacidade)
class _LegalDocumentSheet extends StatelessWidget {
  final String title;
  final String content;

  const _LegalDocumentSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(color: Colors.white.withOpacity(0.1), height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.7,
                    ),
                  ),
                ),
              ),

              // Footer
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Entendi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

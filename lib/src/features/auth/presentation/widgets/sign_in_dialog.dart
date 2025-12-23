import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import 'package:odyssey/src/constants/app_themes.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';
import 'package:odyssey/src/features/welcome/presentation/welcome_screen.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/features/auth/presentation/providers/migration_providers.dart';
import 'package:odyssey/src/features/auth/presentation/screens/account_migration_screen.dart';
import 'package:odyssey/src/features/auth/presentation/signup_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({Key? key, required this.closeModal}) : super(key: key);

  final VoidCallback closeModal;

  @override
  ConsumerState<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  late SMITrigger _successAnim;
  late SMITrigger _errorAnim;
  late SMITrigger _confettiAnim;

  bool _riveInitialized = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine 1",
    );
    if (controller != null) {
      artboard.addController(controller);
      _successAnim = controller.findInput<bool>("Check") as SMITrigger;
      _errorAnim = controller.findInput<bool>("Error") as SMITrigger;
      _riveInitialized = true;
    }
  }

  void _onConfettiRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine 1",
    );
    if (controller != null) {
      artboard.addController(controller);
      _confettiAnim =
          controller.findInput<bool>("Trigger explosion") as SMITrigger;
    }
  }

  Future<void> _login() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (_riveInitialized) _errorAnim.fire();
      _showError('Preencha email e senha');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInWithEmail(email, password);

      result.when(
        success: (user, message) {
          if (mounted) {
            if (_riveInitialized) {
              _successAnim.fire();
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) _confettiAnim.fire();
              });
            }

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                widget.closeModal();
                _checkMigrationAndNavigate(isGuest: false);
              }
            });
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            if (_riveInitialized) _errorAnim.fire();
            _showError(message);
          }
        },
        loading: () {},
        initial: () {},
      );
    } catch (e) {
      if (mounted && _riveInitialized) _errorAnim.fire();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInWithGoogle();

      result.when(
        success: (user, message) {
          if (mounted) {
            if (_riveInitialized) {
              _successAnim.fire();
              _confettiAnim.fire();
            }
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                widget.closeModal();
                _checkMigrationAndNavigate(isGuest: false);
              }
            });
          }
        },
        failure: (message, code, ex) {
          if (mounted) {
            if (_riveInitialized) _errorAnim.fire();
            _showError(message);
          }
        },
        loading: () {},
        initial: () {},
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestMode() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.signInAsGuest();

      result.when(
        success: (user, message) {
          if (mounted) {
            if (_riveInitialized) {
              _successAnim.fire();
            }
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                widget.closeModal();
                _navigateToHome();
              }
            });
          }
        },
        failure: (message, errorCode, exception) {
          if (mounted) {
            if (_riveInitialized) _errorAnim.fire();
            _showError(message);
          }
        },
        loading: () {},
        initial: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.odysseyColors;
    final theme = Theme.of(context);
    const shadowColor = Colors.black;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.9),
                        theme.colorScheme.surface.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(29),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: shadowColor.withOpacity(0.3),
                          offset: const Offset(0, 30),
                          blurRadius: 30,
                        ),
                      ],
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E1E2A).withOpacity(0.95)
                          : CupertinoColors.secondarySystemBackground,
                      backgroundBlendMode: BlendMode.srcOver,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.entrar,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Acesse seu diário de humor, tarefas e hábitos com gamificação.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: "Inter",
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Email",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: "Inter",
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: _inputDecoration(
                            context,
                            Icons.email_outlined,
                            'seu@email.com',
                          ),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Senha",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: "Inter",
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          obscureText: _obscurePassword,
                          decoration:
                              _inputDecoration(
                                context,
                                Icons.lock_outline,
                                '••••••••',
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                              ),
                          controller: _passController,
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: colors.accentPink.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              color: colors.accentPink,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Entrar",
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "Inter",
                                                color: Colors.white,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  "OU",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                    fontSize: 13,
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Social login buttons (only Google - removed Apple)
                        Row(
                          children: [
                            // Google
                            Expanded(
                              child: _SocialLoginButton(
                                icon: Icons.g_mobiledata_rounded,
                                label: 'Google',
                                onTap: _handleGoogleSignIn,
                                iconColor: const Color(0xFFDB4437),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Visitante
                            Expanded(
                              child: _SocialLoginButton(
                                icon: Icons.person_outline_rounded,
                                label: 'Visitante',
                                onTap: _handleGuestMode,
                                iconColor: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Info text
                        Text(
                          "Como visitante, seus dados ficam apenas no dispositivo",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontFamily: "Inter",
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Create Account Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.dontHaveAccount,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: "Inter",
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.closeModal();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.createAccount,
                                style: TextStyle(
                                  color: colors.accentPink,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Inter",
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Rive animations overlay
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: RiveAnimation.asset(
                              "assets/rive/check.riv",
                              onInit: _onCheckRiveInit,
                            ),
                          ),
                        Positioned.fill(
                          child: SizedBox(
                            width: 500,
                            height: 500,
                            child: Transform.scale(
                              scale: 3,
                              child: RiveAnimation.asset(
                                "assets/rive/confetti.riv",
                                onInit: _onConfettiRiveInit,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: widget.closeModal,
                      minimumSize: const Size(36, 36),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurface,
                          size: 20,
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
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    IconData icon,
    String hint,
  ) {
    final theme = Theme.of(context);
    return InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}

/// Social login button widget
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontFamily: "Inter",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

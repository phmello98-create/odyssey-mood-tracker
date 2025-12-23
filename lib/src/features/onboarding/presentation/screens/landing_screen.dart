import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:odyssey/src/constants/app_themes.dart';
import 'package:odyssey/src/features/auth/presentation/widgets/sign_in_dialog.dart';
import 'package:odyssey/src/features/auth/presentation/signup_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/providers/locale_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with TickerProviderStateMixin {
  // Animation controller that shows the sign up modal as well as translateY boarding content together
  AnimationController? _signInAnimController;

  // Control touch effect animation for the "Start the Course" button
  late RiveAnimationController _btnController;

  @override
  void initState() {
    super.initState();
    _signInAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      upperBound: 1,
      vsync: this,
    );

    _btnController = OneShotAnimation("active", autoplay: false);

    const springDesc = SpringDescription(mass: 0.1, stiffness: 40, damping: 5);

    _btnController.isActiveChanged.addListener(() {
      if (!_btnController.isActive) {
        final springAnim = SpringSimulation(springDesc, 0, 1, 0);
        _signInAnimController?.animateWith(springAnim);
      }
    });
  }

  @override
  void dispose() {
    _signInAnimController?.dispose();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.odysseyColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background image with blur
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 200,
            left: 100,
            child: Image.asset("assets/images/onboarding/spline.png"),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),

          // Rive animated shapes
          const RiveAnimation.asset("assets/rive/shapes.riv"),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: const SizedBox(),
            ),
          ),

          // Main content
          AnimatedBuilder(
            animation: _signInAnimController!,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.translationValues(
                  0,
                  -50 * _signInAnimController!.value,
                  0,
                ),
                child: child,
              );
            },
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language Toggle Button (top-right)
                    Align(
                      alignment: Alignment.topRight,
                      child: _buildLanguageToggle(theme, colors),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Hero(
                              tag: 'appLogo',
                              child: Image.asset(
                                'assets/images/odyssey_logo_transparent.png',
                                width: 80,
                                height: 80,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Container(
                              width: 300,
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                ref
                                            .watch(localeStateProvider)
                                            .currentLocale
                                            .languageCode ==
                                        'pt'
                                    ? "Sua Jornada de\nHumor & Hábitos"
                                    : "Your Journey of\nMood & Habits",
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Text(
                              ref
                                          .watch(localeStateProvider)
                                          .currentLocale
                                          .languageCode ==
                                      'pt'
                                  ? "Não apenas registre, evolua. Gamifique sua rotina, controle seu humor e construa hábitos duradouros."
                                  : "Don't just record, evolve. Gamify your routine, control your mood and build lasting habits.",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontFamily: "Inter",
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animated CTA Button
                    GestureDetector(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 220,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colors.accentPink.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              RiveAnimation.asset(
                                "assets/rive/button.riv",
                                fit: BoxFit.cover,
                                controllers: [_btnController],
                              ),
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(4, 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.login_rounded,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Entrar",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontSize: 16,
                                              fontFamily: "Inter",
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
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
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _btnController.isActive = true;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Create Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dontHaveAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontFamily: "Inter",
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.createAccount,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.accentPink,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Inter",
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Info text
                    Text(
                      "✨ Desbloqueie conquistas, temas e estatísticas com uso contínuo.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontFamily: "Inter",
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sign in modal overlay
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _signInAnimController!,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Close button (visible when modal is closing/closed)
                    Positioned(
                      top: 100 - (_signInAnimController!.value * 200),
                      right: 20,
                      child: SafeArea(
                        child: Opacity(
                          opacity: 1 - _signInAnimController!.value,
                          child: Container(), // Empty when modal is open
                        ),
                      ),
                    ),

                    // Dark overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: _signInAnimController!.value < 0.1,
                        child: GestureDetector(
                          onTap: () => _signInAnimController?.reverse(),
                          child: Opacity(
                            opacity: 0.5 * _signInAnimController!.value,
                            child: Container(color: Colors.black),
                          ),
                        ),
                      ),
                    ),

                    // Sign in dialog sliding in
                    Transform.translate(
                      offset: Offset(
                        0,
                        -MediaQuery.of(context).size.height *
                            (1 - _signInAnimController!.value),
                      ),
                      child: child,
                    ),
                  ],
                );
              },
              child: SignInDialog(
                closeModal: () {
                  _signInAnimController?.reverse();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(ThemeData theme, OdysseyColorsExtension colors) {
    final localeNotifier = ref.read(localeStateProvider.notifier);
    final isPortuguese =
        ref.watch(localeStateProvider).currentLocale.languageCode == 'pt';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        localeNotifier.toggleLocale();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              isPortuguese ? 'PT' : 'EN',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 16, color: colors.accentPink),
          ],
        ),
      ),
    );
  }
}

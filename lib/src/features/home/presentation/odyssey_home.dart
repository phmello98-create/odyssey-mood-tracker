import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/presentation/home_screen.dart';
import 'package:odyssey/src/features/log/presentation/log_screen.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen.dart';
import 'package:odyssey/src/features/time_tracker/presentation/time_tracker_screen.dart';
import 'package:odyssey/src/features/gamification/presentation/profile_screen.dart';
import 'package:odyssey/src/features/analytics/presentation/analytics_screen.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/calendar/presentation/calendar_screen.dart';
import 'package:odyssey/src/features/diary/presentation/pages/diary_page.dart';
import 'package:odyssey/src/features/community/presentation/screens/community_screen.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/features/news/presentation/news_screen.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/features/settings/presentation/modern_notification_settings_screen.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/features/welcome/presentation/welcome_back_sheet.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/navigation/page_transitions.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/utils/widgets/floating_timer_widget.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/localization/app_localizations_x.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/gamification/domain/user_stats.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/features/subscription/presentation/donation_screen.dart';
import 'package:odyssey/src/features/home/presentation/widgets/rive_bottom_bar.dart';

import 'dart:math' as math;
import 'dart:io';

class OdysseyHome extends ConsumerStatefulWidget {
  const OdysseyHome({Key? key}) : super(key: key);

  @override
  ConsumerState<OdysseyHome> createState() => _OdysseyHomeState();
}

class _OdysseyHomeState extends ConsumerState<OdysseyHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Side Menu Animation (Rive App Style)
  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;
  bool _isMenuOpen = false;

  // Main navigation screens (5 items for bottom nav)
  final List<Widget> _mainScreens = const [
    HomeScreen(), // Home Dashboard
    LogScreen(), // Log/History with calendar
    MoodRecordsScreen(), // Mood Log
    TimeTrackerScreen(), // Time Tracker
    ProfileScreen(), // Profile with gamification
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _fabAnimationController.forward();

    // Side Menu Animation Controller
    _menuAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _menuAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutCubic),
    );

    // Verificar boas-vindas e onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcome();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    // Se está na aba Timer (index 3) e o Pomodoro está ativo (rodando ou pausado), mostra aviso
    if (_currentIndex == 3 && index != 3) {
      final timerState = ref.read(timerProvider);
      if ((timerState.isRunning || timerState.isPaused) &&
          timerState.isPomodoroMode) {
        _showPomodoroNavigationWarning(index);
        return;
      }
    }

    _performNavigation(index);
  }

  void _performNavigation(int index) {
    if (index == _currentIndex) return;

    // Apenas feedback háptico na navegação (som removido - era intrusivo)
    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    // Animate FAB
    _fabAnimationController.reset();
    _fabAnimationController.forward();

    // Se o menu estava aberto, fecha ao navegar
    if (_isMenuOpen) {
      _toggleSideMenu();
    }
  }

  void _toggleSideMenu() {
    // If not dragging, animate to target
    final target = _isMenuOpen ? 0.0 : 1.0;

    // If we're already at target, toggle logic needs to run to update state
    if (_menuAnimController.value == target) {
      // Toggle logic
    }

    HapticFeedback.mediumImpact();
    // Update state based on target
    setState(() => _isMenuOpen = !_isMenuOpen);

    if (_isMenuOpen) {
      _menuAnimController.forward();
    } else {
      _menuAnimController.reverse();
    }
  }

  void _checkAndShowWelcome() async {
    final welcomeService = ref.read(welcomeServiceProvider);
    final welcomeType = welcomeService.determineWelcomeType();

    // Se não é primeira vez e tem algo para mostrar, mostra o WelcomeBackSheet
    if (welcomeType != WelcomeType.firstTime &&
        welcomeType != WelcomeType.none) {
      final user = ref.read(currentUserProvider);
      final userName = user?.displayName ?? 'Usuário';

      // Pequeno delay para garantir que a tela está carregada
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Calcula dias fora
        final lastVisit = welcomeService.lastVisit;
        final daysAway = lastVisit != null
            ? DateTime.now().difference(lastVisit).inDays
            : 0;

        await WelcomeBackSheet.show(
          context: context,
          welcomeType: welcomeType,
          userName: userName,
          daysAway: daysAway,
          onLogMood: () {
            _performNavigation(2); // Mood tab
          },
          onStartTimer: () {
            _performNavigation(3); // Timer tab
          },
        );

        // Marca que mostrou boas-vindas
        await welcomeService.markWelcomeShown();
      }
    }
  }

  void _showPomodoroNavigationWarning(int targetIndex) {
    final l10n = AppLocalizations.of(context)!;
    final timerState = ref.read(timerProvider);
    final timeLeft = timerState.pomodoroTimeLeft;
    final isBreak = timerState.isPomodoroBreak;
    final taskName = timerState.taskName ?? l10n.focus;
    final accentColor = isBreak
        ? const Color(0xFF3498DB)
        : const Color(0xFFFF6B6B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (consumerContext, consumerRef, _) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header com timer circular mini
                      Row(
                        children: [
                          // Timer circular compacto
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.2),
                                  accentColor.withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isBreak ? '☕' : '🍅',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.timerActive,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  taskName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Timer badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${timeLeft.inMinutes}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Opções em grid 2x2
                      Row(
                        children: [
                          // Continuar em background
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.play_circle_outline_rounded,
                              label: l10n.continue_,
                              sublabel: l10n.inBackground,
                              color: UltravioletColors.accentGreen,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _performNavigation(targetIndex);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Pausar
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.pause_circle_outline_rounded,
                              label: l10n.pause,
                              sublabel: l10n.timer,
                              color: const Color(0xFFFFA556),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                consumerRef
                                    .read(timerProvider.notifier)
                                    .pausePomodoro();
                                soundService.stopTimerSounds();
                                _performNavigation(targetIndex);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Encerrar
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.stop_circle_outlined,
                              label: l10n.stop,
                              sublabel: l10n.session,
                              color: const Color(0xFFFF6B6B),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                consumerRef
                                    .read(timerProvider.notifier)
                                    .resetPomodoro();
                                soundService.stopTimerSounds();
                                _performNavigation(targetIndex);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Voltar ao timer
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.arrow_back_rounded,
                              label: l10n.back,
                              sublabel: l10n.timer,
                              color: Theme.of(context).colorScheme.outline,
                              onTap: () => Navigator.pop(sheetContext),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
    soundService.playModalOpen(); // Som ao abrir menu
    HapticFeedback.mediumImpact(); // Feedback tátil
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMoreMenuSheet(),
    );
  }

  Widget _buildMoreMenuSheet() {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.more,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMoreMenuItem(
                      Icons.auto_graph_outlined,
                      l10n.analytics,
                      colors.primary,
                      () => _navigateToScreen(
                        const AnalyticsScreen(),
                        title: l10n.analytics,
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.note_outlined,
                      l10n.notes,
                      colors.tertiary,
                      () => _navigateToScreen(
                        const NotesScreen(),
                        title: l10n.notes,
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.check_circle_outline,
                      l10n.tasks,
                      colors.secondary,
                      () => _navigateToScreen(
                        const TasksScreen(),
                        title: l10n.tasks,
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.menu_book_outlined,
                      l10n.library,
                      colors.tertiary,
                      () => _navigateToScreen(
                        const LibraryScreen(),
                        title: l10n.library,
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.calendar_month_outlined,
                      l10n.calendar,
                      colors.primary,
                      () => _navigateToScreen(
                        const CalendarScreen(),
                        title: l10n.calendar,
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.explore_outlined,
                      l10n.isEnglish ? 'Discover' : 'Descobrir',
                      colors.primary,
                      () => _navigateToScreen(
                        const FeatureDiscoveryScreen(),
                        title: l10n.isEnglish ? 'Discover' : 'Descobrir',
                      ),
                    ),
                    _buildMoreMenuItem(
                      Icons.settings_outlined,
                      l10n.settings,
                      colors.onSurfaceVariant,
                      () => _navigateToScreen(
                        const SettingsScreen(),
                        title: l10n.settings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMoreMenuItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(Widget screen, {String? title}) {
    Navigator.push(
      context,
      AppPageRoutes.material(ScreenWrapper(title: title, child: screen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Performance: watch apenas as propriedades necessárias para o side menu
    final userName = ref.watch(settingsProvider.select((s) => s.userName));
    final avatarPath = ref.watch(settingsProvider.select((s) => s.avatarPath));
    final colors = Theme.of(context).colorScheme;

    // Cor de fundo quando o menu está aberto (escuro estilo Rive App)
    // Cor de fundo quando o menu está aberto (agora combinando com o tema do app)
    final menuBgColor = Theme.of(context).scaffoldBackgroundColor;

    // Listen to navigation provider changes
    ref.listen<int>(navigationProvider, (previous, next) {
      if (next != _currentIndex) {
        _onNavigationTap(next);
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_isMenuOpen) {
          _toggleSideMenu();
          return false;
        }
        if (_currentIndex == 0) {
          SystemNavigator.pop();
          return true;
        }
        _onNavigationTap(0);
        return false;
      },
      child: Scaffold(
        backgroundColor: menuBgColor,
        extendBody: true,
        body: Stack(
          children: [
            // ==========================================
            // SIDE MENU (Background layer)
            // ==========================================
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(
                        ((1 - _menuAnimation.value) * -30) * math.pi / 180,
                      )
                      ..translate((1 - _menuAnimation.value) * -300),
                    child: child,
                  );
                },
                child: FadeTransition(
                  opacity: _menuAnimation,
                  child: _buildSideMenu(userName, avatarPath, colors),
                ),
              ),
            ),

            // ==========================================
            // MAIN CONTENT (Global PageView with 3D animation)
            // ==========================================
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 - (_menuAnimation.value * 0.1),
                    child: Transform.translate(
                      offset: Offset(_menuAnimation.value * 265, 0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(
                            (_menuAnimation.value * 30) * math.pi / 180,
                          ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _menuAnimation.value * 24,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _isMenuOpen ? _toggleSideMenu : null,
                  onHorizontalDragStart: (details) {
                    // Only allow drag on Home screen
                    if (_currentIndex != 0) return;
                    // Disable implicit animation while dragging
                    // controller is now driven by gesture
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_currentIndex != 0) return;

                    // Width of the screen used for normalization
                    const double dragWidth = 200.0;
                    // Calculate delta (0.0 to 1.0)
                    double delta = details.primaryDelta! / dragWidth;

                    // Update controller value
                    _menuAnimController.value += delta;
                  },
                  onHorizontalDragEnd: (details) {
                    if (_currentIndex != 0) return;

                    // Width of the screen used for normalization
                    const double dragWidth = 200.0;

                    // Velocity threshold to snap
                    double kMinFlingVelocity = 365.0;

                    // If moving fast enough
                    if (details.primaryVelocity!.abs() >= kMinFlingVelocity) {
                      double visualVelocity =
                          details.primaryVelocity! / dragWidth;

                      // If flicked right -> Open
                      if (visualVelocity > 0) {
                        _menuAnimController.fling(velocity: visualVelocity);
                        setState(() => _isMenuOpen = true);
                      }
                      // If flicked left -> Close
                      else {
                        _menuAnimController.fling(velocity: visualVelocity);
                        setState(() => _isMenuOpen = false);
                      }
                    }
                    // If moving slow, check position
                    else {
                      if (_menuAnimController.value > 0.5) {
                        _menuAnimController.forward();
                        setState(() => _isMenuOpen = true);
                      } else {
                        _menuAnimController.reverse();
                        setState(() => _isMenuOpen = false);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    absorbing: _isMenuOpen,
                    child: Scaffold(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      body: Stack(
                        children: [
                          PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            children: _mainScreens,
                          ),
                          // Floating timer widget
                          const FloatingTimerWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // MENU BUTTON (Global floating trigger)
            // ==========================================
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) {
                  return SafeArea(
                    child: Row(
                      children: [
                        SizedBox(width: _menuAnimation.value * 216),
                        child!,
                      ],
                    ),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (_currentIndex != 0 && !_isMenuOpen)
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          key: const ValueKey('menu_button_visible'),
                          onTap: _toggleSideMenu,
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape:
                                  BoxShape.circle, // Circular shape for avatar
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Consumer(
                              builder: (context, ref, _) {
                                // Performance: watch apenas as propriedades necessárias
                                final avatarPath = ref.watch(
                                  settingsProvider.select((s) => s.avatarPath),
                                );
                                final userName = ref.watch(
                                  settingsProvider.select((s) => s.userName),
                                );

                                if (_isMenuOpen) {
                                  return Icon(
                                    Icons.close_rounded,
                                    key: const ValueKey('close_icon'),
                                    color: colors.primary,
                                  );
                                }

                                if (avatarPath != null &&
                                    File(avatarPath).existsSync()) {
                                  return CircleAvatar(
                                    key: ValueKey(avatarPath),
                                    backgroundImage: FileImage(
                                      File(avatarPath),
                                    ),
                                    radius: 20,
                                  );
                                }

                                return CircleAvatar(
                                  key: const ValueKey('default_avatar'),
                                  backgroundColor: colors.primary.withOpacity(
                                    0.1,
                                  ),
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // ==========================================
            // FLOATING BOTTOM BAR (Inside Stack for true floating effect)
            // ==========================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildAnimatedBottomBar(colors),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CUSTOM ANIMATED BOTTOM BAR (Rive Style)
  // ==========================================
  Widget _buildAnimatedBottomBar(ColorScheme colors) {
    if (_isMenuOpen) return const SizedBox.shrink();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _menuAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _menuAnimation.value * 200),
            child: child,
          );
        },
        child: RiveBottomBar(
          currentIndex: _currentIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

  // ==========================================
  // SIDE MENU (Global)
  // ==========================================
  Widget _buildSideMenu(
    String userName,
    String? avatarPath,
    ColorScheme colors,
  ) {
    final stats = ref.watch(userStatsProvider.select((s) => s.totalXP));
    final title = UserTitles.getTitleForXP(stats);

    return SafeArea(
      child: Container(
        width: 288,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.surfaceContainerHighest,
                      backgroundImage: avatarPath != null
                          ? FileImage(File(avatarPath))
                          : null,
                      child: avatarPath == null
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'O',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : 'Viajante',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${title.emoji} ${title.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.7),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _menuSectionLabel('NAVEGAÇÃO'),
                    _sideMenuItem(
                      Icons.home_rounded,
                      'Início',
                      _currentIndex == 0,
                      () => _performNavigation(0),
                    ),
                    _sideMenuItem(
                      Icons.history_rounded,
                      'Histórico',
                      _currentIndex == 1,
                      () => _performNavigation(1),
                    ),
                    _sideMenuItem(
                      Icons.mood_rounded,
                      'Humor',
                      _currentIndex == 2,
                      () => _performNavigation(2),
                    ),
                    _sideMenuItem(
                      Icons.timer_rounded,
                      'Foco',
                      _currentIndex == 3,
                      () => _performNavigation(3),
                    ),
                    _sideMenuItem(
                      Icons.person_rounded,
                      'Perfil',
                      _currentIndex == 4,
                      () => _performNavigation(4),
                    ),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _sideMenuItem(
                      Icons.check_circle_rounded,
                      'Tarefas',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const TasksScreen(),
                          title: 'Tarefas',
                        );
                      },
                    ),
                    _sideMenuItem(
                      Icons.event_repeat_rounded,
                      'Hábitos',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const HabitsCalendarScreen(),
                          title: 'Hábitos',
                        );
                      },
                    ),
                    _sideMenuItem(Icons.note_alt_rounded, 'Notas', false, () {
                      _toggleSideMenu();
                      _navigateToScreen(const NotesScreen(), title: 'Notas');
                    }),
                    _sideMenuItem(Icons.book_rounded, 'Diário', false, () {
                      _toggleSideMenu();
                      _navigateToScreen(const DiaryPage(), title: 'Diário');
                    }),
                    _sideMenuItem(
                      Icons.library_books_rounded,
                      'Livros',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const LibraryScreen(),
                          title: 'Livros',
                        );
                      },
                    ),
                    _sideMenuItem(Icons.forum_rounded, 'Comunidade', false, () {
                      _toggleSideMenu();
                      _navigateToScreen(
                        const CommunityScreen(),
                        title: 'Comunidade',
                      );
                    }),
                    _sideMenuItem(Icons.article_rounded, 'Artigos', false, () {
                      _toggleSideMenu();
                      _navigateToScreen(const NewsScreen(), title: 'Artigos');
                    }),
                    _sideMenuItem(
                      Icons.auto_graph_rounded,
                      'Estatísticas',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const AnalyticsScreen(),
                          title: 'Estatísticas',
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    _menuSectionLabel('CONFIGURAÇÕES'),
                    _sideMenuItem(
                      Icons.settings_rounded,
                      'Preferências',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const SettingsScreen(),
                          title: 'Configurações',
                        );
                      },
                    ),
                    _sideMenuItem(
                      Icons.notifications_rounded,
                      'Notificações',
                      false,
                      () {
                        _toggleSideMenu();
                        _navigateToScreen(
                          const ModernNotificationSettingsScreen(),
                          title: 'Notificações',
                        );
                      },
                    ),
                    _sideMenuItem(Icons.favorite_rounded, 'Apoiar', false, () {
                      _toggleSideMenu();
                      _navigateToScreen(
                        const DonationScreen(),
                        title: 'Doação',
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Theme Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: colors.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Modo Escuro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: Theme.of(context).brightness == Brightness.dark,
                    activeColor: colors.primary,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Odyssey v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.4),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSectionLabel(String label) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _sideMenuItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.7),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Wrapper para telas que são abertas via Navigator.push
// Adiciona um botão de voltar e header opcional
class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final String? title;

  const ScreenWrapper({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: child,
    );
  }
}

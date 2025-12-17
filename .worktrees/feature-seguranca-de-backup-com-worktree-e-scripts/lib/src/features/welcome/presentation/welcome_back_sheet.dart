import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/providers/locale_provider.dart';

/// Bottom sheet acolhedor para usuários que voltam
class WelcomeBackSheet extends ConsumerStatefulWidget {
  final WelcomeType welcomeType;
  final String userName;
  final int daysAway;
  final int currentStreak;
  final VoidCallback onDismiss;
  final VoidCallback? onLogMood;
  final VoidCallback? onStartTimer;

  const WelcomeBackSheet({
    super.key,
    required this.welcomeType,
    required this.userName,
    this.daysAway = 0,
    this.currentStreak = 0,
    required this.onDismiss,
    this.onLogMood,
    this.onStartTimer,
  });

  @override
  ConsumerState<WelcomeBackSheet> createState() => _WelcomeBackSheetState();

  /// Mostra o bottom sheet de boas-vindas
  static Future<void> show({
    required BuildContext context,
    required WelcomeType welcomeType,
    required String userName,
    int daysAway = 0,
    int currentStreak = 0,
    VoidCallback? onLogMood,
    VoidCallback? onStartTimer,
  }) async {
    // Não mostra para tipo 'none'
    if (welcomeType == WelcomeType.none || welcomeType == WelcomeType.firstTime) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => WelcomeBackSheet(
        welcomeType: welcomeType,
        userName: userName,
        daysAway: daysAway,
        currentStreak: currentStreak,
        onDismiss: () => Navigator.pop(context),
        onLogMood: onLogMood != null
            ? () {
                Navigator.pop(context);
                onLogMood();
              }
            : null,
        onStartTimer: onStartTimer != null
            ? () {
                Navigator.pop(context);
                onStartTimer();
              }
            : null,
      ),
    );
  }
}

class _WelcomeBackSheetState extends ConsumerState<WelcomeBackSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  bool get _isPortuguese {
    final locale = ref.watch(localeStateProvider).currentLocale;
    return locale.languageCode == 'pt';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Retorna a saudação baseada na hora do dia
  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (_isPortuguese) {
      if (hour < 12) return 'Bom dia';
      if (hour < 18) return 'Boa tarde';
      return 'Boa noite';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
  }

  /// Retorna o emoji baseado na hora do dia
  String get _timeEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤️';
    return '🌙';
  }

  /// Retorna a mensagem principal baseada no tipo de boas-vindas
  String get _mainMessage {
    switch (widget.welcomeType) {
      case WelcomeType.longTimeNoSee:
        if (_isPortuguese) {
          return 'Sentimos sua falta! 💜';
        }
        return 'We missed you! 💜';
      case WelcomeType.welcomeBack:
        if (_isPortuguese) {
          return 'Bem-vindo de volta! 👋';
        }
        return 'Welcome back! 👋';
      case WelcomeType.newDay:
        if (_isPortuguese) {
          return 'Novo dia, novas conquistas! ✨';
        }
        return 'New day, new achievements! ✨';
      default:
        if (_isPortuguese) {
          return 'Olá! 👋';
        }
        return 'Hello! 👋';
    }
  }

  /// Retorna a mensagem secundária
  String get _subMessage {
    switch (widget.welcomeType) {
      case WelcomeType.longTimeNoSee:
        if (_isPortuguese) {
          return 'Faz ${widget.daysAway} dias desde sua última visita.\nQue bom ter você de volta!';
        }
        return 'It\'s been ${widget.daysAway} days since your last visit.\nGreat to have you back!';
      case WelcomeType.welcomeBack:
        if (_isPortuguese) {
          return 'Você ficou ${widget.daysAway} dias fora.\nPronto para retomar sua jornada?';
        }
        return 'You were away for ${widget.daysAway} days.\nReady to continue your journey?';
      case WelcomeType.newDay:
        if (_isPortuguese) {
          return 'Como você está se sentindo hoje?\nVamos fazer desse dia incrível!';
        }
        return 'How are you feeling today?\nLet\'s make this day amazing!';
      default:
        if (_isPortuguese) {
          return 'Pronto para continuar?';
        }
        return 'Ready to continue?';
    }
  }

  /// Retorna as cores do gradiente baseado no tipo
  List<Color> get _gradientColors {
    switch (widget.welcomeType) {
      case WelcomeType.longTimeNoSee:
        return [const Color(0xFF8B5CF6), const Color(0xFFA855F7)];
      case WelcomeType.welcomeBack:
        return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
      case WelcomeType.newDay:
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      default:
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstName = widget.userName.split(' ').first;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Ícone animado com glow
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _gradientColors[0].withValues(alpha: 0.2),
                        _gradientColors[1].withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: _gradientColors[0].withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _timeEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Saudação com hora do dia
              Text(
                '$_timeGreeting, $firstName!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Mensagem principal
              Text(
                _mainMessage,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Mensagem secundária
              Text(
                _subMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Streak badge (se tiver)
              if (widget.currentStreak > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        const Color(0xFFFBBF24).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        _isPortuguese
                            ? '${widget.currentStreak} dias de sequência!'
                            : '${widget.currentStreak} day streak!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Ações rápidas
              Row(
                children: [
                  // Registrar humor
                  if (widget.onLogMood != null)
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.mood_rounded,
                        label: _isPortuguese ? 'Registrar\nHumor' : 'Log\nMood',
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onLogMood!();
                        },
                      ),
                    ),

                  if (widget.onLogMood != null && widget.onStartTimer != null)
                    const SizedBox(width: 12),

                  // Iniciar timer
                  if (widget.onStartTimer != null)
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.timer_rounded,
                        label: _isPortuguese ? 'Iniciar\nFoco' : 'Start\nFocus',
                        color: const Color(0xFFFF6B6B),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onStartTimer!();
                        },
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Continuar
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.arrow_forward_rounded,
                      label: _isPortuguese ? 'Continuar' : 'Continue',
                      color: _gradientColors[0],
                      isPrimary: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onDismiss();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: _gradientColors)
              : null,
          color: isPrimary ? null : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

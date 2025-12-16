import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Card moderno para widgets da Home com efeitos visuais avançados
/// Suporta glassmorphism, gradientes sutis, shimmer e animações
class ModernHomeCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? accentColor;
  final List<Color>? gradientColors;
  final bool enableGlow;
  final bool enableShimmer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool useGlass;

  const ModernHomeCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.accentColor,
    this.gradientColors,
    this.enableGlow = false,
    this.enableShimmer = false,
    this.onTap,
    this.onLongPress,
    this.useGlass = false,
  });

  @override
  State<ModernHomeCard> createState() => _ModernHomeCardState();
}

class _ModernHomeCardState extends State<ModernHomeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
      _pressController.reverse();
      if (widget.onTap != null) {
        HapticFeedback.lightImpact();
        widget.onTap!();
      }
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: widget.useGlass ? null : colors.surface,
        gradient: widget.gradientColors != null
            ? LinearGradient(
                colors: widget.gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: widget.accentColor?.withValues(alpha: 0.2) ??
              colors.outline.withValues(alpha: isDark ? 0.08 : 0.12),
          width: 1,
        ),
        boxShadow: [
          // Shadow base sutil
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          // Glow colorido se habilitado
          if (widget.enableGlow && widget.accentColor != null)
            BoxShadow(
              color: widget.accentColor!.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
        ],
      ),
      child: widget.child,
    );

    // Aplicar glassmorphism se necessário
    if (widget.useGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: colors.surface.withValues(alpha: isDark ? 0.7 : 0.85),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: cardContent,
          );
        },
      ),
    );
  }
}

/// Header padrão modernizado para widgets da home
class ModernCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;
  final bool useGradientIcon;

  const ModernCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
    this.useGradientIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Icon com fundo gradiente sutil
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: useGradientIcon
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: useGradientIcon ? null : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            boxShadow: useGradientIcon
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: useGradientIcon ? Colors.white : color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Botão "Ver todas" modernizado
class ModernSeeAllButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const ModernSeeAllButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: effectiveColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress bar modernizada com gradiente
class ModernProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final List<Color>? gradientColors;
  final double height;
  final bool showPercentage;

  const ModernProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.gradientColors,
    this.height = 6,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colors.primary;
    final effectiveGradient = gradientColors ??
        [effectiveColor, effectiveColor.withValues(alpha: 0.7)];

    return Row(
      children: [
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: effectiveGradient),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveGradient.first.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 10),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state modernizado
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: effectiveColor.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

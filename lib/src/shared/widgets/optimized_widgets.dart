import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_sizes.dart';
import 'package:odyssey/src/constants/app_theme.dart';

/// Card otimizado com const constructor quando possível
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      padding: padding ?? AppPadding.cardAll,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? UltravioletColors.cardBackground) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
        border: border ?? Border.all(
          color: UltravioletColors.outline.withValues(alpha: 0.1),
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    
    return container;
  }
}

/// Ícone com fundo circular otimizado
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}

/// Badge de status (pendente/concluído)
class AppStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.chip,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.smBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: AppIconSize.xs),
            gapW4,
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: AppFontSize.xs,
              fontWeight: AppFontWeight.semiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção com header padronizado
class AppSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    AppIconBadge(
                      icon: icon!,
                      color: iconColor ?? UltravioletColors.primary,
                      size: 36,
                      iconSize: 18,
                    ),
                    gapW10,
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: AppFontWeight.semiBold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        gapH12,
        child,
      ],
    );
  }
}

/// Indicador de progresso circular otimizado
class AppProgressIndicator extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final Widget? child;

  const AppProgressIndicator({
    super.key,
    required this.value,
    this.size = 60,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.valueColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? UltravioletColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(
              valueColor ?? _getColorForValue(value),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }

  Color _getColorForValue(double val) {
    if (val >= 0.7) return const Color(0xFF07E092);
    if (val >= 0.4) return UltravioletColors.primary;
    return UltravioletColors.tertiary;
  }
}

/// Empty state widget reutilizável
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: UltravioletColors.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIconSize.xxxl,
            color: Colors.white24,
          ),
          gapH12,
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            gapH12,
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: AppPadding.button,
                decoration: BoxDecoration(
                  color: UltravioletColors.primary.withValues(alpha: 0.2),
                  borderRadius: AppRadius.fullBorder,
                  border: Border.all(
                    color: UltravioletColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    color: UltravioletColors.primary,
                    fontWeight: FontWeight.w600,
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

/// Shimmer loading placeholder
class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
                UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card shimmer para loading states
class AppCardShimmer extends StatelessWidget {
  final int lines;
  final bool showIcon;

  const AppCardShimmer({
    super.key,
    this.lines = 2,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          if (showIcon) ...[
            const AppShimmer(width: 44, height: 44, borderRadius: 12),
            gapW12,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
                  child: AppShimmer(
                    height: index == 0 ? 16 : 12,
                    width: index == 0 ? double.infinity : 100,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista shimmer para loading
class AppListShimmer extends StatelessWidget {
  final int itemCount;

  const AppListShimmer({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 12 : 0),
          child: const AppCardShimmer(),
        );
      }),
    );
  }
}

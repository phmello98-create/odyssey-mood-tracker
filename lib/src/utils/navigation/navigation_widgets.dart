import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/constants/app_sizes.dart';
import 'package:odyssey/src/utils/services/haptic_service.dart';

/// AppBar customizada com design consistente
class AppCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const AppCustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? AppBackButton(onPressed: onBackPressed)
          : null),
      title: titleWidget ?? (title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            )
          : null),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Botão de voltar customizado
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        hapticService.navigation();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: color ?? UltravioletColors.onSurface,
        size: size,
      ),
      tooltip: 'Voltar',
    );
  }
}

/// Botão de fechar customizado (para modais)
class AppCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const AppCloseButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        hapticService.navigation();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
      icon: Icon(
        Icons.close_rounded,
        color: color ?? UltravioletColors.onSurface,
        size: size,
      ),
      tooltip: 'Fechar',
    );
  }
}

/// Container de tela padrão com safe area e padding
class ScreenContainer extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;

  const ScreenContainer({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? AppPadding.screenH,
      child: child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? UltravioletColors.background,
      appBar: appBar,
      body: content,
    );
  }
}

/// Tela com scroll e refresh
class ScrollableScreen extends StatelessWidget {
  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;

  const ScrollableScreen({
    super.key,
    required this.children,
    this.appBar,
    this.onRefresh,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ListView(
      controller: controller,
      padding: padding ?? AppPadding.screen,
      shrinkWrap: shrinkWrap,
      children: children,
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: UltravioletColors.primary,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: UltravioletColors.background,
      appBar: appBar,
      body: content,
    );
  }
}

/// Header de seção com título e ação opcional
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: AppFontWeight.semiBold,
                    color: UltravioletColors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  gapH4,
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            GestureDetector(
              onTap: () {
                hapticService.selection();
                onTap!();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.viewAll,
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: UltravioletColors.primary,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  gapW4,
                  const Icon(
                    Icons.chevron_right,
                    size: AppIconSize.sm,
                    color: UltravioletColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Divisor estilizado
class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 24,
      thickness: thickness ?? 1,
      color: color ?? UltravioletColors.divider,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Espaço vertical com linha opcional
class VerticalSpace extends StatelessWidget {
  final double height;
  final bool showDivider;

  const VerticalSpace({
    super.key,
    this.height = 16,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showDivider) {
      return Column(
        children: [
          SizedBox(height: height / 2),
          const AppDivider(height: 1),
          SizedBox(height: height / 2),
        ],
      );
    }
    return SizedBox(height: height);
  }
}

/// FAB customizado com animação
class AppFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;
  final bool extended;

  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
    this.extended = false,
  });

  @override
  State<AppFloatingActionButton> createState() => _AppFloatingActionButtonState();
}

class _AppFloatingActionButtonState extends State<AppFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    final bgColor = widget.backgroundColor ?? UltravioletColors.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        hapticService.selection();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          height: widget.mini ? 40 : 56,
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 20 : (widget.mini ? 8 : 16),
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.mini ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: fgColor,
                size: widget.mini ? 20 : 24,
              ),
              if (widget.extended && widget.label != null) ...[
                gapW8,
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: AppFontWeight.semiBold,
                    fontSize: AppFontSize.md,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill de navegação (como tabs)
class NavigationPill extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? selectedColor;
  final Color? unselectedColor;

  const NavigationPill({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: UltravioletColors.surfaceVariant,
        borderRadius: AppRadius.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () {
              hapticService.selection();
              onChanged(index);
            },
            child: AnimatedContainer(
              duration: AppDuration.fast,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (selectedColor ?? UltravioletColors.primary)
                    : Colors.transparent,
                borderRadius: AppRadius.fullBorder,
              ),
              child: Text(
                items[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (unselectedColor ?? UltravioletColors.onSurfaceVariant),
                  fontWeight: isSelected ? AppFontWeight.semiBold : AppFontWeight.medium,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

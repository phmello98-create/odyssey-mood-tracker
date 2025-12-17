import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_theme.dart';

class OdysseyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final double? width;
  final double? height;

  const OdysseyCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.borderRadius = 24,
    this.gradientColors,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine background
    final bg = backgroundColor ?? (isDark 
        ? UltravioletColors.cardBackground 
        : theme.colorScheme.surface);
        
    // Determine border
    final border = borderColor ?? (isDark 
        ? theme.colorScheme.outline.withValues(alpha: 0.1)
        : theme.colorScheme.outline.withValues(alpha: 0.2));

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradientColors == null ? bg : null,
        gradient: gradientColors != null 
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
        boxShadow: [
          if (gradientColors != null)
            BoxShadow(
              color: gradientColors!.first.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Padding(
        padding: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: margin,
      child: content,
    );
  }
}

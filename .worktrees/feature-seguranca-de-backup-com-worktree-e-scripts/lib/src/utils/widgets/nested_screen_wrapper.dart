import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_theme.dart';

/// Wrapper para telas nested que mantém a bottom bar visível
class NestedScreenWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final VoidCallback onBackPressed;

  const NestedScreenWrapper({
    required this.child,
    required this.title,
    required this.onBackPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UltravioletColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: onBackPressed,
            child: Container(
              decoration: BoxDecoration(
                color: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: UltravioletColors.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: child,
    );
  }
}

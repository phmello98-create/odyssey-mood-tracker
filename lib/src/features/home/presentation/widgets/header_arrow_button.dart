import 'package:flutter/material.dart';

class HeaderArrowButton extends StatefulWidget {
  final VoidCallback onTap;
  final ColorScheme colors;

  const HeaderArrowButton({
    super.key,
    required this.onTap,
    required this.colors,
  });

  @override
  State<HeaderArrowButton> createState() => _HeaderArrowButtonState();
}

class _HeaderArrowButtonState extends State<HeaderArrowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.colors.primary.withOpacity(0.3)
                : widget.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: widget.colors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: widget.colors.primary,
          ),
        ),
      ),
    );
  }
}

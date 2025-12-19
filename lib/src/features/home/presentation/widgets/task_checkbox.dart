import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_theme.dart';

class TaskCheckbox extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;
  final ColorScheme colors;

  const TaskCheckbox({
    super.key,
    required this.isCompleted,
    required this.onTap,
    required this.colors,
  });

  @override
  State<TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<TaskCheckbox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? UltravioletColors.accentGreen
                  : _isHovering
                  ? UltravioletColors.accentGreen.withOpacity(
                      0.2,
                    ) // Hover color
                  : widget.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: widget.isCompleted
                  ? null
                  : Border.all(
                      color: _isHovering
                          ? UltravioletColors.accentGreen
                          : widget.colors.outline.withOpacity(0.4),
                    ),
              boxShadow: _isHovering && !widget.isCompleted
                  ? [
                      BoxShadow(
                        color: UltravioletColors.accentGreen.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: widget.isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

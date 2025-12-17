// lib/src/features/diary/presentation/widgets/diary_view_mode_selector.dart

import 'package:flutter/material.dart';
import '../controllers/diary_state.dart';

/// Seletor de modo de visualização do diário
class DiaryViewModeSelector extends StatelessWidget {
  final DiaryViewMode currentMode;
  final ValueChanged<DiaryViewMode> onModeChanged;
  final bool showLabels;

  const DiaryViewModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (showLabels) {
      return SegmentedButton<DiaryViewMode>(
        segments: const [
          ButtonSegment(
            value: DiaryViewMode.timeline,
            icon: Icon(Icons.view_agenda_rounded),
            label: Text('Timeline'),
          ),
          ButtonSegment(
            value: DiaryViewMode.grid,
            icon: Icon(Icons.grid_view_rounded),
            label: Text('Grid'),
          ),
          ButtonSegment(
            value: DiaryViewMode.calendar,
            icon: Icon(Icons.calendar_month_rounded),
            label: Text('Calendário'),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (set) => onModeChanged(set.first),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.view_agenda_rounded,
            tooltip: 'Timeline',
            isSelected: currentMode == DiaryViewMode.timeline,
            onTap: () => onModeChanged(DiaryViewMode.timeline),
          ),
          const SizedBox(width: 4),
          _ModeButton(
            icon: Icons.grid_view_rounded,
            tooltip: 'Grid',
            isSelected: currentMode == DiaryViewMode.grid,
            onTap: () => onModeChanged(DiaryViewMode.grid),
          ),
          const SizedBox(width: 4),
          _ModeButton(
            icon: Icons.calendar_month_rounded,
            tooltip: 'Calendário',
            isSelected: currentMode == DiaryViewMode.calendar,
            onTap: () => onModeChanged(DiaryViewMode.calendar),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeTrackerHeader extends StatelessWidget {
  final VoidCallback onProjectsTap;
  final VoidCallback onAddTap;
  final VoidCallback onHistoryTap;

  const TimeTrackerHeader({
    super.key,
    required this.onProjectsTap,
    required this.onAddTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderButton(
            context: context,
            icon: Icons.folder_outlined,
            label: 'Projetos',
            onTap: onProjectsTap,
          ),
          _buildHeaderButton(
            context: context,
            icon: Icons.add,
            label: 'Add',
            onTap: onAddTap,
            isPrimary: true,
          ),
          _buildHeaderButton(
            context: context,
            icon: Icons.history,
            label: 'Histórico',
            onTap: onHistoryTap,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isPrimary
                ? null
                : colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isPrimary ? 20 : 18,
                color: isPrimary
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

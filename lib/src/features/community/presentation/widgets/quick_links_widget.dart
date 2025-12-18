import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickLinksWidget extends StatelessWidget {
  const QuickLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44, // Compact height
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildQuickLink(
            context,
            label: 'Regras',
            icon: Icons.gavel_rounded,
            color: const Color(0xFFE57373),
            onTap: () {
              // TODO: Open rules
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Regras da Comunidade'),
                  content: const Text(
                    '1. Seja gentil.\n2. Mantenha o foco em crescimento.\n3. Sem spam.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildQuickLink(
            context,
            label: 'Wiki',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF64B5F6),
            onTap: () {
              // TODO: Open Wiki
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Wiki do Odyssey em construção...'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF64B5F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          _buildQuickLink(
            context,
            label: 'Eventos',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFFFFD54F),
            onTap: () {
              // TODO: Open Events
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Agenda de Eventos em breve!',
                    style: TextStyle(color: Colors.black),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFFFD54F),
                  showCloseIcon: true,
                  closeIconColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          _buildQuickLink(
            context,
            label: 'Top 100',
            icon: Icons.stars_rounded,
            color: const Color(0xFFA1887F),
            onTap: () {
              // TODO: Open Leaderboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ranking Global em breve!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFA1887F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.only(left: 8, right: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

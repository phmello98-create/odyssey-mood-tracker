import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CuratedSection extends StatelessWidget {
  const CuratedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // TODO: Replace with dynamic data from repository/backend
    final curatedItems = [
      _CuratedItem(
        title: 'Guia de Hábitos Atômicos',
        type: 'Artigo',
        author: 'ModOdyssey',
        imageUrl: '', // Placeholder
        color: const Color(0xFF6B4EFF),
        icon: Icons.article_rounded,
      ),
      _CuratedItem(
        title: 'O Poder do Agora',
        type: 'Livro do Mês',
        author: 'Eckhart Tolle',
        imageUrl: '',
        color: const Color(0xFFE91E63),
        icon: Icons.menu_book_rounded,
      ),
      _CuratedItem(
        title: 'Como vencer a Procrastinação',
        type: 'Dica Rápida',
        author: 'ModOdyssey',
        imageUrl: '',
        color: const Color(0xFFFF9800),
        icon: Icons.lightbulb_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Curadoria Odyssey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: curatedItems.length,
            itemBuilder: (context, index) {
              return _CuratedCard(item: curatedItems[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CuratedItem {
  final String title;
  final String type;
  final String author;
  final String imageUrl;
  final Color color;
  final IconData icon;

  _CuratedItem({
    required this.title,
    required this.type,
    required this.author,
    required this.imageUrl,
    required this.color,
    required this.icon,
  });
}

class _CuratedCard extends StatelessWidget {
  final _CuratedItem item;

  const _CuratedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Navigate to content details
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Abrindo: ${item.title}')));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(0.15),
                  item.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ),
                    Icon(item.icon, color: item.color, size: 20),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'por ${item.author}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

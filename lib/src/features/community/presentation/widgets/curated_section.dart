import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CuratedSection extends StatelessWidget {
  const CuratedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final curatedItems = [
      _CuratedItem(
        title: 'Guia de Hábitos Atômicos',
        type: 'Artigo',
        author: 'ModOdyssey',
        imageUrl: '',
        color: const Color(0xFF6B4EFF),
        icon: Icons.article_rounded,
        content: '''
Os hábitos atômicos são pequenas mudanças que, quando acumuladas, geram resultados extraordinários.

**Regra #1: Torne óbvio**
Deixe lembretes visuais do hábito que quer criar.

**Regra #2: Torne atraente**
Associe o novo hábito a algo que você gosta.

**Regra #3: Torne fácil**
Reduza a fricção para começar.

**Regra #4: Torne satisfatório**
Recompense-se imediatamente após completar.
        ''',
      ),
      _CuratedItem(
        title: 'O Poder do Agora',
        type: 'Livro do Mês',
        author: 'Eckhart Tolle',
        imageUrl: '',
        color: const Color(0xFFE91E63),
        icon: Icons.menu_book_rounded,
        content: '''
"O Poder do Agora" de Eckhart Tolle é um guia para iluminação espiritual.

**Principais insights:**

📌 O único momento real é o presente
📌 Sua mente não é quem você é
📌 O sofrimento vem da resistência ao que é
📌 Encontre a quietude dentro de você

**Exercício prático:**
Observe seus pensamentos sem julgá-los por 5 minutos hoje.
        ''',
      ),
      _CuratedItem(
        title: 'Como vencer a Procrastinação',
        type: 'Dica Rápida',
        author: 'ModOdyssey',
        imageUrl: '',
        color: const Color(0xFFFF9800),
        icon: Icons.lightbulb_rounded,
        content: '''
**5 técnicas rápidas contra procrastinação:**

⏰ **Regra dos 2 minutos**
Se leva menos de 2 min, faça agora.

🍅 **Técnica Pomodoro**
25 min de foco + 5 min de pausa.

📝 **Divida em micro-tarefas**
"Escrever relatório" → "Abrir documento"

🎯 **Comece pelo mais difícil**
Aproveite sua energia da manhã.

🚫 **Bloqueie distrações**
Use o modo foco do Odyssey!
        ''',
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
  final String content;

  _CuratedItem({
    required this.title,
    required this.type,
    required this.author,
    required this.imageUrl,
    required this.color,
    required this.icon,
    required this.content,
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
            _showContentSheet(context, colors);
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

  void _showContentSheet(BuildContext context, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          'por ${item.author}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.outline.withOpacity(0.2)),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Text(
                  item.content.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurface,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            // Footer actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📌 Salvo nos favoritos!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmark_outline_rounded),
                      label: const Text('Salvar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔗 Link copiado!')),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartilhar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

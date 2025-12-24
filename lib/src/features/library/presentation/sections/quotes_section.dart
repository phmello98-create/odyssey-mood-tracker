import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/notes/domain/quote.dart';
import 'package:odyssey/src/features/notes/data/quotes_repository.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:share_plus/share_plus.dart';

class QuotesSection extends ConsumerStatefulWidget {
  final String searchQuery;
  final VoidCallback onAddQuote;

  const QuotesSection({
    super.key,
    required this.searchQuery,
    required this.onAddQuote,
  });

  @override
  ConsumerState<QuotesSection> createState() => _QuotesSectionState();
}

class _QuotesSectionState extends ConsumerState<QuotesSection> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(quotesRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<Quote>>(
      stream: repo.watchQuotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !repo.isInitialized) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final allQuotes = snapshot.data ?? [];

        final quotes = widget.searchQuery.isEmpty
            ? allQuotes
            : allQuotes.where((q) {
                final query = widget.searchQuery.toLowerCase();
                return q.text.toLowerCase().contains(query) ||
                    q.author.toLowerCase().contains(query) ||
                    (q.category?.toLowerCase().contains(query) ?? false);
              }).toList();

        if (quotes.isEmpty) {
          return _buildQuotesEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return _buildQuoteCard(context, quote);
          },
        );
      },
    );
  }

  Widget _buildQuotesEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'Nenhuma frase encontrada'
                : 'Nenhuma frase salva',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'Tente buscar com outros termos.'
                : 'Guarde suas inspirações, pensamentos e\ncitações favoritas aqui.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (widget.searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onAddQuote,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Frase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.tertiary,
                foregroundColor: colors.onTertiary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Quote quote) {
    final colors = Theme.of(context).colorScheme;
    final text = quote.text;
    final author = quote.author;
    final isFavorite = quote.isFavorite;
    final category = quote.category ?? 'Inspiração';

    Color categoryColor;
    Color categoryGradientEnd;

    switch (category.toLowerCase()) {
      case 'motivação':
        categoryColor = colors.primary;
        categoryGradientEnd = colors.primaryContainer;
        break;
      case 'sabedoria':
        categoryColor = colors.tertiary;
        categoryGradientEnd = colors.tertiaryContainer;
        break;
      case 'filosofia':
        categoryColor = colors.secondary;
        categoryGradientEnd = colors.secondaryContainer;
        break;
      case 'reflexão':
        categoryColor = const Color(0xFF06B6D4);
        categoryGradientEnd = const Color(0xFF22D3EE);
        break;
      default:
        categoryColor = colors.primary;
        categoryGradientEnd = colors.primaryContainer;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: categoryColor.withValues(alpha: 0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showQuoteActions(context, quote),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  categoryColor.withValues(alpha: 0.15),
                                  categoryGradientEnd.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.format_quote_rounded,
                              color: categoryColor,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    categoryColor.withValues(alpha: 0.15),
                                    categoryGradientEnd.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          if (isFavorite) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: colors.error,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"$text"',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: colors.onSurface.withValues(alpha: 0.9),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [categoryColor, categoryGradientEnd],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            author,
                            style: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuoteActions(BuildContext context, Quote quote) {
    HapticFeedback.mediumImpact();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: quote.isFavorite ? colors.error : null,
              ),
              title: Text(
                quote.isFavorite
                    ? 'Remover dos Favoritos'
                    : 'Adicionar aos Favoritos',
              ),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(quotesRepositoryProvider);
                await repo.toggleFavorite(quote.id);
                HapticFeedback.lightImpact();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copiar Texto'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(text: '${quote.text} — ${quote.author}'),
                );
                FeedbackService.showSuccess(context, 'Texto copiado!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartilhar'),
              onTap: () async {
                Navigator.pop(context);
                final textToShare =
                    '"${quote.text}"\n— ${quote.author}\n\nEnviado via Odyssey Mood Tracker';
                await Share.share(textToShare);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text('Excluir', style: TextStyle(color: colors.error)),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(quotesRepositoryProvider);
                await repo.deleteQuote(quote.id);
                FeedbackService.showWarning(context, 'Frase removida');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

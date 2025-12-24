import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

class ArticlesSection extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onAddArticle;

  const ArticlesSection({
    super.key,
    required this.searchQuery,
    required this.onAddArticle,
  });

  @override
  State<ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends State<ArticlesSection> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.openBox('articles'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          final colors = Theme.of(context).colorScheme;
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final box = snapshot.data!;

        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box articlesBox, _) {
            final articles = articlesBox.values.toList();

            final filteredArticles = widget.searchQuery.isEmpty
                ? articles
                : articles.where((a) {
                    if (a is! Map) return false;
                    final title = (a['title'] ?? '').toString().toLowerCase();
                    final author = (a['author'] ?? '').toString().toLowerCase();
                    final source = (a['source'] ?? '').toString().toLowerCase();
                    return title.contains(widget.searchQuery.toLowerCase()) ||
                        author.contains(widget.searchQuery.toLowerCase()) ||
                        source.contains(widget.searchQuery.toLowerCase());
                  }).toList();

            filteredArticles.sort((a, b) {
              if (a is! Map || b is! Map) return 0;
              final dateA =
                  DateTime.tryParse(a['dateAdded'] ?? '') ?? DateTime(2000);
              final dateB =
                  DateTime.tryParse(b['dateAdded'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

            return Column(
              children: [
                _buildOnlineArticleSearchButton(context),
                Expanded(
                  child: filteredArticles.isEmpty
                      ? _buildArticlesEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index] as Map;
                            return _buildArticleCard(
                              context,
                              article,
                              articlesBox,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineArticleSearchButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: _showOnlineArticleSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.12),
                colors.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.travel_explore_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descobrir Artigos Online',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesquise em milhões de artigos acadêmicos',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesEmptyState(BuildContext context) {
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
              Icons.article_outlined,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'Nenhum artigo encontrado'
                : 'Nenhum artigo salvo',
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
                : 'Salve artigos, posts e textos interessantes.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (widget.searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onAddArticle,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Artigo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
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

  Widget _buildArticleCard(BuildContext context, Map article, Box box) {
    final colors = Theme.of(context).colorScheme;
    final title = article['title'] ?? 'Sem título';
    final author = article['author'] ?? '';
    final source = article['source'] ?? '';
    final status = article['status'] ?? 0;
    final favourite = article['favourite'] ?? false;
    final readingTime = article['readingTime'];
    final url = article['url'];

    Color statusColor;
    Color statusGradientEnd;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 1:
        statusColor = colors.primary;
        statusGradientEnd = colors.primaryContainer;
        statusLabel = 'Lendo';
        statusIcon = Icons.auto_stories_rounded;
        break;
      case 2:
        statusColor = const Color(0xFF10B981);
        statusGradientEnd = const Color(0xFF34D399);
        statusLabel = 'Lido';
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = colors.secondary;
        statusGradientEnd = colors.secondaryContainer;
        statusLabel = 'Para Ler';
        statusIcon = Icons.bookmark_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Borda lateral gradiente
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusGradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Conteúdo
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showArticleActions(article, box),
                onLongPress: () => _showArticleActions(article, box),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ícone com gradiente
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withValues(alpha: 0.15),
                                  statusGradientEnd.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.article_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                    color: colors.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (author.isNotEmpty || source.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 13,
                                        color: colors.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [author, source]
                                              .where((s) => s.isNotEmpty)
                                              .join(' • '),
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Favourite
                          if (favourite)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Pills row
                      Row(
                        children: [
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withValues(alpha: 0.15),
                                  statusGradientEnd.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: statusColor),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reading time pill
                          if (readingTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: colors.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${readingTime}min',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          // URL indicator
                          if (url != null && url.toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 13,
                                    color: colors.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Link',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

  void _showArticleActions(Map article, Box box) {
    final colors = Theme.of(context).colorScheme;
    final id = article['id'];
    final status = article['status'] ?? 0;
    final favourite = article['favourite'] ?? false;

    HapticFeedback.mediumImpact();
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
                color: colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Status options
            ListTile(
              leading: Icon(
                Icons.bookmark_outline,
                color: status == 0 ? colors.primary : null,
              ),
              title: const Text('Para Ler'),
              trailing: status == 0
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () async {
                await box.put(id, {...article, 'status': 0});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.visibility,
                color: status == 1 ? colors.primary : null,
              ),
              title: const Text('Lendo'),
              trailing: status == 1
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () async {
                await box.put(id, {...article, 'status': 1});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: status == 2 ? const Color(0xFF10B981) : null,
              ),
              title: const Text('Lido'),
              trailing: status == 2
                  ? const Icon(Icons.check, color: Color(0xFF10B981))
                  : null,
              onTap: () async {
                await box.put(id, {
                  ...article,
                  'status': 2,
                  'dateRead': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                FeedbackService.showSuccess(context, '✅ Marcado como lido!');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                favourite ? Icons.favorite : Icons.favorite_border,
                color: favourite ? Colors.red : null,
              ),
              title: Text(
                favourite ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos',
              ),
              onTap: () async {
                await box.put(id, {...article, 'favourite': !favourite});
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await box.delete(id);
                FeedbackService.showWarning(context, 'Artigo removido');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showOnlineArticleSearch() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final colors = Theme.of(context).colorScheme;
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.travel_explore_rounded,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descobrir Artigos',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Powered by OpenAlex • Milhões de artigos',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search field
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar artigos, temas, autores...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded),
                                  onPressed: () async {
                                    if (searchController.text.isEmpty) return;

                                    setModalState(() {
                                      isLoading = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final results = await _searchOpenAlex(
                                        searchController.text,
                                      );
                                      setModalState(() {
                                        searchResults = results;
                                        isLoading = false;
                                      });
                                    } catch (e) {
                                      debugPrint('Search error: $e');
                                      setModalState(() {
                                        errorMessage =
                                            'Erro na busca: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e}';
                                        isLoading = false;
                                      });
                                    }
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        onSubmitted: (value) async {
                          if (value.isEmpty) return;

                          setModalState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final results = await _searchOpenAlex(value);
                            setModalState(() {
                              searchResults = results;
                              isLoading = false;
                            });
                          } catch (e) {
                            debugPrint('Search error: $e');
                            setModalState(() {
                              errorMessage =
                                  'Erro na busca: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e}';
                              isLoading = false;
                            });
                          }
                        },
                      ),
                      // Quick search chips
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Builder(
                          builder: (context) {
                            Future<void> performSearch(String query) async {
                              setModalState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              try {
                                final results = await _searchOpenAlex(query);
                                setModalState(() {
                                  searchResults = results;
                                  isLoading = false;
                                });
                              } catch (e) {
                                setModalState(() {
                                  errorMessage = 'Erro: $e';
                                  isLoading = false;
                                });
                              }
                            }

                            return Row(
                              children: [
                                _buildQuickSearchChip(
                                  'Artificial Intelligence',
                                  searchController,
                                  setModalState,
                                  performSearch,
                                ),
                                _buildQuickSearchChip(
                                  'Psychology',
                                  searchController,
                                  setModalState,
                                  performSearch,
                                ),
                                _buildQuickSearchChip(
                                  'Neuroscience',
                                  searchController,
                                  setModalState,
                                  performSearch,
                                ),
                                _buildQuickSearchChip(
                                  'Climate Change',
                                  searchController,
                                  setModalState,
                                  performSearch,
                                ),
                                _buildQuickSearchChip(
                                  'Machine Learning',
                                  searchController,
                                  setModalState,
                                  performSearch,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Results
                Expanded(
                  child: errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: colors.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                style: TextStyle(color: colors.error),
                              ),
                            ],
                          ),
                        )
                      : searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Pesquise por um tema',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use os chips acima para buscas rápidas',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final result = searchResults[index];
                            return _buildSearchResultCard(result, context);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickSearchChip(
    String label,
    TextEditingController controller,
    StateSetter setModalState,
    Future<void> Function(String) onSearch,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          controller.text = label;
          onSearch(label);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchOpenAlex(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://api.openalex.org/works?search=$encodedQuery&per_page=20&mailto=app@odyssey.com',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'OdysseyApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List? ?? []).map((work) {
          final authorships = work['authorships'] as List? ?? [];
          final authors = authorships
              .take(3)
              .map((a) => a['author']?['display_name'] ?? '')
              .where((name) => name.isNotEmpty)
              .join(', ');

          final year = work['publication_year'];

          final source =
              work['primary_location']?['source']?['display_name'] ??
              work['host_venue']?['display_name'] ??
              '';

          String? openAccessUrl = work['open_access']?['oa_url'];
          openAccessUrl ??= work['primary_location']?['pdf_url'];
          if (openAccessUrl == null && work['doi'] != null) {
            final doi = work['doi'].toString().replaceAll(
              'https://doi.org/',
              '',
            );
            openAccessUrl = 'https://doi.org/$doi';
          }

          return {
            'title': work['title'] ?? 'Sem título',
            'authors': authors,
            'year': year,
            'source': source,
            'url': openAccessUrl,
            'citedCount': work['cited_by_count'] ?? 0,
            'isOpenAccess': work['open_access']?['is_oa'] ?? false,
            'doi': work['doi'],
          };
        }).toList();

        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      rethrow;
    }
  }

  Widget _buildSearchResultCard(
    Map<String, dynamic> result,
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isOpenAccess = result['isOpenAccess'] == true;
    final citedCount = result['citedCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpenAccess
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Save directly
            final box = await Hive.openBox('articles');
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            await box.put(id, {
              'id': id,
              'title': result['title'],
              'author': result['authors'],
              'source': result['source'],
              'url': result['url'],
              'status': 0, // Para ler
              'favourite': false,
              'dateAdded': DateTime.now().toIso8601String(),
            });
            if (context.mounted) {
              Navigator.pop(context);
              FeedbackService.showSuccess(context, 'Artigo salvo!');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['title'] ?? 'Sem título',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (result['authors'] != null &&
                    result['authors'].toString().isNotEmpty)
                  Text(
                    '${result['authors']}${result['year'] != null ? ' • ${result['year']}' : ''}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (result['source'] != null &&
                    result['source'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    result['source'],
                    style: TextStyle(
                      color: colors.secondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (isOpenAccess)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_open,
                              size: 12,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Open Access',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (citedCount > 0) ...[
                      Icon(
                        Icons.format_quote,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$citedCount citações',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Salvar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

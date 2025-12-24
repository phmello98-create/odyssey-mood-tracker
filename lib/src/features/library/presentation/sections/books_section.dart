import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/library/data/book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/presentation/widgets/book_card_grid.dart';
import 'package:odyssey/src/features/library/presentation/widgets/book_card_list.dart';
import 'package:odyssey/src/features/library/presentation/book_detail_screen.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

class BooksSection extends ConsumerStatefulWidget {
  final String searchQuery;
  final VoidCallback onAddBook;

  const BooksSection({
    super.key,
    required this.searchQuery,
    required this.onAddBook,
  });

  @override
  ConsumerState<BooksSection> createState() => _BooksSectionState();
}

class _BooksSectionState extends ConsumerState<BooksSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;

  final List<Map<String, dynamic>> _tabs = [
    {'status': null, 'label': 'Todos', 'icon': Icons.library_books_outlined},
    {
      'status': BookStatus.inProgress,
      'label': 'Lendo',
      'icon': Icons.auto_stories_outlined,
    },
    {
      'status': BookStatus.forLater,
      'label': 'Para Ler',
      'icon': Icons.bookmark_outline,
    },
    {
      'status': BookStatus.read,
      'label': 'Lidos',
      'icon': Icons.check_circle_outline,
    },
    {'status': 'favourites', 'label': '❤️', 'icon': Icons.favorite},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteBook(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir livro'),
        content: const Text('Tem certeza que deseja excluir este livro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(bookRepositoryProvider).deleteBook(id);
      if (mounted) {
        FeedbackService.showSuccess(context, 'Livro excluído com sucesso');
        setState(() {});
      }
    }
  }

  Future<void> _toggleFavourite(Book book) async {
    HapticFeedback.lightImpact();
    final updatedBook = book.copyWith(favourite: !book.favourite);
    await ref.read(bookRepositoryProvider).updateBook(updatedBook);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = ref.watch(bookRepositoryProvider);

    return Column(
      children: [
        // Tab Bar and View Toggle
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelColor: colors.onPrimary,
                    unselectedLabelColor: colors.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: _tabs.map((tab) {
                      return Tab(text: tab['label'] as String);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // View Toggle
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      isActive: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                      colors: colors,
                    ),
                    _buildViewToggleButton(
                      icon: Icons.view_list_rounded,
                      isActive: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              return _buildBooksList(repo, status: tab['status']);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? colors.primary : colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildBooksList(BookRepository repo, {dynamic status}) {
    List<Book> books;

    if (status == 'favourites') {
      books = repo.getAllBooks().where((b) => b.favourite).toList();
    } else if (status != null && status is BookStatus) {
      books = repo.getBooksByStatus(status);
    } else {
      books = repo.getAllBooks();
    }

    if (widget.searchQuery.isNotEmpty) {
      books = books.where((book) {
        final query = widget.searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            (book.genre?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    books.sort((a, b) => b.dateModified.compareTo(a.dateModified));

    if (books.isEmpty) {
      return _buildEmptyState(status);
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 24,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCardGrid(
            book: book,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(bookId: book.id),
              ),
            ).then((_) => setState(() {})),
            onLongPress: () => _deleteBook(book.id),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCardList(
            book: book,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(bookId: book.id),
              ),
            ).then((_) => setState(() {})),
            onLongPress: () => _deleteBook(book.id),
            onToggleFavourite: () => _toggleFavourite(book),
          );
        },
      );
    }
  }

  Widget _buildEmptyState(dynamic status) {
    final colors = Theme.of(context).colorScheme;
    String message = 'Nenhum livro encontrado';
    IconData icon = Icons.library_books_outlined;

    if (widget.searchQuery.isNotEmpty) {
      message = 'Nenhum livro encontrado para "${widget.searchQuery}"';
      icon = Icons.search_off;
    } else if (status == BookStatus.inProgress) {
      message = 'Você não está lendo nenhum livro no momento';
      icon = Icons.auto_stories_outlined;
    } else if (status == BookStatus.forLater) {
      message = 'Sua lista de leitura está vazia';
      icon = Icons.bookmark_outline;
    } else if (status == BookStatus.read) {
      message = 'Nenhum livro lido ainda';
      icon = Icons.check_circle_outline;
    } else if (status == 'favourites') {
      message = 'Nenhum livro favorito';
      icon = Icons.favorite_border;
    }

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
              icon,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.searchQuery.isEmpty && status == null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onAddBook,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Livro'),
              style: FilledButton.styleFrom(
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
}

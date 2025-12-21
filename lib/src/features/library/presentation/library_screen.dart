import 'dart:convert';
import 'package:odyssey/src/features/notes/domain/quote.dart';
import '../../notes/data/quotes_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/library/data/book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/presentation/statistics_screen.dart';
import 'package:odyssey/src/features/library/presentation/widgets/book_card_grid.dart';
import 'package:odyssey/src/features/library/presentation/widgets/book_card_list.dart';
import 'package:odyssey/src/features/library/presentation/add_book_screen.dart';
import 'package:odyssey/src/features/library/presentation/book_detail_screen.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;

class LibraryScreen extends ConsumerStatefulWidget {
  final int initialType;
  const LibraryScreen({super.key, this.initialType = 0});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
  // Showcase keys
  final GlobalKey _showcaseAdd = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseShelves = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseStats = GlobalKey();
  late TabController _tabController;
  bool _isGridView = true;
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _libraryType = 0; // 0: Books, 1: Articles, 2: Phrases

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
    _libraryType = widget.initialType;
    _initShowcase();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      final repo = ref.read(bookRepositoryProvider);
      await repo.initialize();
      final quotesRepo = ref.read(quotesRepositoryProvider);
      await quotesRepo.initialize();
      await quotesRepo.addSampleQuotesIfEmpty();
    } catch (e) {
      debugPrint('Error initializing library: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.library);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcaseStats, _showcaseShelves, _showcaseAdd];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.library,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.library, keys);
  }

  void _startTour() {
    final keys = [_showcaseStats, _showcaseShelves, _showcaseAdd];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.library, keys);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: UltravioletColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final repo = ref.watch(bookRepositoryProvider);

    return Scaffold(
      backgroundColor: UltravioletColors.background,
      body: ValueListenableBuilder(
        valueListenable: repo.box.listenable(),
        builder: (context, Box<Book> box, _) {
          final allBooks = repo.getAllBooks();
          final stats = {
            'total': allBooks.length,
            'reading': allBooks
                .where((b) => b.status == BookStatus.inProgress)
                .length,
            'finished': allBooks
                .where((b) => b.status == BookStatus.read)
                .length,
            'pages': allBooks.fold(
              0,
              (sum, b) =>
                  (sum) +
                  (b.status == BookStatus.read
                      ? (b.pages ?? 0)
                      : b.currentPage),
            ),
          };

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: UltravioletColors.background,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minha Biblioteca',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${stats['total']} livros • ${stats['pages']} páginas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: UltravioletColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    tooltip: _isGridView ? 'Lista' : 'Grade',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Estatísticas',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showOptionsMenu(context),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(_libraryType != 0 ? 52 : 92),
                  child: Column(
                    children: [
                      // Toggle Livros / Artigos / Frases
                      _buildLibraryToggle(),
                      if (_libraryType == 0) ...[
                        const SizedBox(height: 8),
                        // Tabs
                        _buildTabBar(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                // Search bar
                _buildSearchBar(),
                // Content
                Expanded(
                  child: _libraryType == 1
                      ? _buildArticlesSection()
                      : _libraryType == 2
                      ? _buildQuotesSection()
                      : TabBarView(
                          controller: _tabController,
                          children: _tabs.map((tab) {
                            return _buildBooksList(repo, status: tab['status']);
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_libraryType == 0) {
            _navigateToAddBook();
          } else if (_libraryType == 1)
            _showAddArticleDialog();
          else
            _showAddQuoteDialog();
        },
        backgroundColor: _libraryType == 0
            ? UltravioletColors.primary
            : _libraryType == 1
            ? UltravioletColors.secondary
            : UltravioletColors.accent,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _libraryType == 0
              ? 'Adicionar'
              : _libraryType == 1
              ? 'Novo Artigo'
              : 'Nova Frase',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildToggleButton(
              0,
              Icons.menu_book_rounded,
              'Livros',
              UltravioletColors.primary,
            ),
            _buildToggleButton(
              1,
              Icons.article_outlined,
              'Artigos',
              UltravioletColors.secondary,
            ),
            _buildToggleButton(
              2,
              Icons.format_quote_rounded,
              'Frases',
              UltravioletColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    int type,
    IconData icon,
    String label,
    Color activeColor,
  ) {
    final isSelected = _libraryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _libraryType = type);
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : UltravioletColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : UltravioletColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final repo = ref.watch(bookRepositoryProvider);
    final allBooks = repo.getAllBooks();

    // Contagem por status
    final counts = {
      null: allBooks.length,
      BookStatus.inProgress: allBooks
          .where((b) => b.status == BookStatus.inProgress)
          .length,
      BookStatus.forLater: allBooks
          .where((b) => b.status == BookStatus.forLater)
          .length,
      BookStatus.read: allBooks
          .where((b) => b.status == BookStatus.read)
          .length,
      'favourites': allBooks.where((b) => b.favourite).length,
    };

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _tabController.index == index;
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final count = counts[tab['status']] ?? 0;

          // Cores diferentes para cada tab
          Color tabColor;
          if (tab['status'] == 'favourites') {
            tabColor = Colors.red;
          } else {
            switch (tab['status']) {
              case BookStatus.inProgress:
                tabColor = UltravioletColors.primary;
                break;
              case BookStatus.forLater:
                tabColor = UltravioletColors.secondary;
                break;
              case BookStatus.read:
                tabColor = UltravioletColors.accentGreen;
                break;
              default:
                tabColor = UltravioletColors.primary;
            }
          }

          return Padding(
            padding: EdgeInsets.only(right: index < _tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(index);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? tabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? tabColor
                        : UltravioletColors.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : UltravioletColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : UltravioletColors.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : tabColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.white : tabColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar por título, autor ou gênero...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBooksList(BookRepository repo, {dynamic status}) {
    List<Book> books;

    if (status == 'favourites') {
      // Favoritos
      books = repo.getAllBooks().where((b) => b.favourite).toList();
    } else if (status != null && status is BookStatus) {
      books = repo.getBooksByStatus(status);
    } else {
      books = repo.getAllBooks();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      books = books.where((book) {
        final query = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            (book.genre?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by date modified (newest first)
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCardGrid(
            book: book,
            onTap: () => _navigateToBookDetail(book),
            onLongPress: () => _showBookActions(book),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BookCardList(
              book: book,
              onTap: () => _navigateToBookDetail(book),
              onLongPress: () => _showBookActions(book),
            ),
          );
        },
      );
    }
  }

  Widget _buildEmptyState(dynamic status) {
    String message;
    String subMessage;
    IconData icon;

    if (status == 'favourites') {
      message = 'Nenhum favorito';
      subMessage = 'Adicione livros aos favoritos para vê-los aqui.';
      icon = Icons.favorite_border;
    } else {
      switch (status) {
        case BookStatus.inProgress:
          message = 'Nenhum livro em leitura';
          subMessage = 'Comece uma nova aventura literária!';
          icon = Icons.auto_stories_outlined;
          break;
        case BookStatus.forLater:
          message = 'Lista de leitura vazia';
          subMessage = 'Adicione livros que você quer ler no futuro.';
          icon = Icons.bookmark_outline;
          break;
        case BookStatus.read:
          message = 'Nenhum livro finalizado';
          subMessage = 'Seus livros concluídos aparecerão aqui.';
          icon = Icons.check_circle_outline;
          break;
        default:
          message = _searchQuery.isNotEmpty
              ? 'Nenhum livro encontrado'
              : 'Sua biblioteca está vazia';
          subMessage = _searchQuery.isNotEmpty
              ? 'Tente buscar com outros termos.'
              : 'Adicione seu primeiro livro para começar.';
          icon = Icons.library_books_outlined;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: UltravioletColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(
              color: UltravioletColors.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (status == null && _searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddBook(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Livro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UltravioletColors.primary,
                foregroundColor: Colors.white,
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

  void _navigateToAddBook({Book? bookToEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookScreen(bookToEdit: bookToEdit),
      ),
    );
  }

  void _navigateToBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(bookId: book.id),
      ),
    );
  }

  void _showBookActions(Book book) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
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
                color: UltravioletColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ver Detalhes'),
              onTap: () {
                Navigator.pop(context);
                _navigateToBookDetail(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddBook(bookToEdit: book);
              },
            ),
            if (book.status == BookStatus.inProgress)
              ListTile(
                leading: const Icon(Icons.bookmark_added),
                title: const Text('Atualizar Progresso'),
                onTap: () {
                  Navigator.pop(context);
                  _showProgressDialog(book);
                },
              ),
            ListTile(
              leading: Icon(
                book.favourite ? Icons.favorite : Icons.favorite_border,
                color: book.favourite ? Colors.red : null,
              ),
              title: Text(
                book.favourite
                    ? 'Remover dos Favoritos'
                    : 'Adicionar aos Favoritos',
              ),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(bookRepositoryProvider);
                await repo.toggleFavourite(book.id);
                HapticFeedback.lightImpact();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(book);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showProgressDialog(Book book) {
    int currentPage = book.currentPage;

    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Atualizar Progresso',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                style: const TextStyle(
                  color: UltravioletColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (currentPage >= 10) {
                        setModalState(() => currentPage -= 10);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$currentPage',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: UltravioletColors.primary,
                    ),
                  ),
                  Text(
                    ' / ${book.pages ?? 0}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      if (book.pages == null || currentPage < book.pages!) {
                        setModalState(() => currentPage += 10);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (book.pages != null && book.pages! > 0)
                Slider(
                  value: currentPage.toDouble().clamp(
                    0,
                    book.pages!.toDouble(),
                  ),
                  min: 0,
                  max: book.pages!.toDouble(),
                  onChanged: (value) =>
                      setModalState(() => currentPage = value.toInt()),
                  activeColor: UltravioletColors.primary,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(bookRepositoryProvider);
                    await repo.updateProgress(book.id, currentPage);
                    Navigator.pop(context);

                    if (book.pages != null && currentPage >= book.pages!) {
                      FeedbackService.showAchievement(
                        context,
                        '📖 Livro Finalizado!',
                        'Parabéns por concluir "${book.title}"',
                      );
                    } else {
                      FeedbackService.showSuccess(
                        context,
                        '📚 Progresso atualizado!',
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        title: const Text('Excluir Livro?'),
        content: Text('Deseja excluir "${book.title}" da sua biblioteca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(bookRepositoryProvider);
              await repo.deleteBook(book.id);
              FeedbackService.showWarning(context, 'Livro removido');
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UltravioletColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Opções da Biblioteca',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Options grid
              Row(
                children: [
                  Expanded(
                    child: _buildMenuOption(
                      icon: Icons.bar_chart_rounded,
                      label: 'Estatísticas',
                      color: UltravioletColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuOption(
                      icon: Icons.sort_rounded,
                      label: 'Ordenar',
                      color: UltravioletColors.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showSortOptions();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Lixeira',
                      color: UltravioletColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showTrash();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UltravioletColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ordenar por',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Mais recentes', Icons.access_time, true),
              _buildSortOption('Título (A-Z)', Icons.sort_by_alpha, false),
              _buildSortOption('Autor', Icons.person_outline, false),
              _buildSortOption('Avaliação', Icons.star_outline, false),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? UltravioletColors.primary : null),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: UltravioletColors.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        // TODO: Implement sorting
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showTrash() {
    final repo = ref.read(bookRepositoryProvider);
    final deletedBooks = repo.box.values.where((b) => b.deleted).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UltravioletColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        color: UltravioletColors.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Lixeira',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (deletedBooks.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            // TODO: Empty trash
                            FeedbackService.showWarning(
                              context,
                              'Lixeira esvaziada',
                            );
                          },
                          child: const Text(
                            'Esvaziar',
                            style: TextStyle(color: UltravioletColors.error),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: deletedBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 64,
                            color: UltravioletColors.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Lixeira vazia',
                            style: TextStyle(
                              color: UltravioletColors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: deletedBooks.length,
                      itemBuilder: (context, index) {
                        final book = deletedBooks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.restore,
                                color: UltravioletColors.primary,
                              ),
                              onPressed: () async {
                                // TODO: Restore book
                                Navigator.pop(context);
                                FeedbackService.showSuccess(
                                  context,
                                  'Livro restaurado',
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ARTICLES SECTION
  // ==========================================

  Widget _buildArticlesSection() {
    return FutureBuilder<Box>(
      future: Hive.openBox('articles'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final box = snapshot.data!;

        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box articlesBox, _) {
            final articles = articlesBox.values.toList();

            // Apply search filter
            final filteredArticles = _searchQuery.isEmpty
                ? articles
                : articles.where((a) {
                    if (a is! Map) return false;
                    final title = (a['title'] ?? '').toString().toLowerCase();
                    final author = (a['author'] ?? '').toString().toLowerCase();
                    final source = (a['source'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery.toLowerCase()) ||
                        author.contains(_searchQuery.toLowerCase()) ||
                        source.contains(_searchQuery.toLowerCase());
                  }).toList();

            // Sort by date (newest first)
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
                // Botão de busca online
                _buildOnlineArticleSearchButton(),
                // Lista de artigos
                Expanded(
                  child: filteredArticles.isEmpty
                      ? _buildArticlesEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index] as Map;
                            return _buildArticleCard(article, articlesBox);
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

  Widget _buildOnlineArticleSearchButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: _showOnlineArticleSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UltravioletColors.secondary.withValues(alpha: 0.15),
                UltravioletColors.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UltravioletColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UltravioletColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: UltravioletColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descobrir Artigos Online',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: UltravioletColors.onSurface,
                      ),
                    ),
                    Text(
                      'Pesquise em milhões de artigos acadêmicos',
                      style: TextStyle(
                        fontSize: 11,
                        color: UltravioletColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: UltravioletColors.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 48,
              color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Nenhum artigo encontrado'
                : 'Nenhum artigo salvo',
            style: const TextStyle(
              color: UltravioletColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tente buscar com outros termos.'
                : 'Salve artigos, posts e textos interessantes.',
            style: const TextStyle(
              color: UltravioletColors.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddArticleDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Artigo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UltravioletColors.secondary,
                foregroundColor: Colors.white,
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

  Widget _buildArticleCard(Map article, Box box) {
    final title = article['title'] ?? 'Sem título';
    final author = article['author'] ?? '';
    final source = article['source'] ?? '';
    final status = article['status'] ?? 0;
    final favourite = article['favourite'] ?? false;
    final dateAdded = DateTime.tryParse(article['dateAdded'] ?? '');
    final readingTime = article['readingTime'];
    final url = article['url'];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 1:
        statusColor = UltravioletColors.primary;
        statusLabel = 'Lendo';
        statusIcon = Icons.visibility;
        break;
      case 2:
        statusColor = UltravioletColors.accentGreen;
        statusLabel = 'Lido';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = UltravioletColors.secondary;
        statusLabel = 'Para ler';
        statusIcon = Icons.bookmark_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: UltravioletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showArticleDetail(article, box),
          onLongPress: () => _showArticleActions(article, box),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.article_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (author.isNotEmpty || source.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              [
                                author,
                                source,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: const TextStyle(
                                color: UltravioletColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Favourite
                    if (favourite)
                      const Icon(Icons.favorite, color: Colors.red, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Reading time
                    if (readingTime != null) ...[
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: UltravioletColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${readingTime}min',
                        style: const TextStyle(
                          color: UltravioletColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // URL indicator
                    if (url != null && url.toString().isNotEmpty)
                      const Icon(
                        Icons.link,
                        size: 14,
                        color: UltravioletColors.onSurfaceVariant,
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

  void _showAddArticleDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final sourceController = TextEditingController();
    final urlController = TextEditingController();
    final notesController = TextEditingController();
    int readingTime = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UltravioletColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Novo Artigo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Nome do artigo ou texto',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Author
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: 'Autor',
                    hintText: 'Quem escreveu',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Source
                TextField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Fonte',
                    hintText: 'Site, revista, jornal...',
                    prefixIcon: const Icon(Icons.source_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // URL
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Link (URL)',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                // Reading time
                const Text(
                  'Tempo de leitura estimado',
                  style: TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (readingTime > 1) {
                          setModalState(() => readingTime--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$readingTime min',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setModalState(() => readingTime++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Anotações sobre o artigo...',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: UltravioletColors.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) {
                        FeedbackService.showWarning(
                          context,
                          'Digite um título',
                        );
                        return;
                      }

                      final box = await Hive.openBox('articles');
                      final id = DateTime.now().millisecondsSinceEpoch
                          .toString();

                      await box.put(id, {
                        'id': id,
                        'title': titleController.text,
                        'author': authorController.text,
                        'source': sourceController.text,
                        'url': urlController.text,
                        'notes': notesController.text,
                        'readingTime': readingTime,
                        'status': 0, // Para ler
                        'favourite': false,
                        'dateAdded': DateTime.now().toIso8601String(),
                      });

                      Navigator.pop(context);
                      FeedbackService.showSuccess(
                        context,
                        '📄 Artigo adicionado!',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UltravioletColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Salvar Artigo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // QUOTES SECTION
  // ==========================================

  Widget _buildQuotesSection() {
    final repo = ref.watch(quotesRepositoryProvider);

    return StreamBuilder<List<Quote>>(
      stream: repo.watchQuotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !repo.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final allQuotes = snapshot.data ?? [];

        // local filtering for performance and simplicity with Isar streams
        final quotes = _searchQuery.isEmpty
            ? allQuotes
            : allQuotes
                  .where(
                    (q) =>
                        q.text.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        q.author.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        (q.category?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        if (quotes.isEmpty) {
          return _buildQuotesEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return _buildQuoteCard(quote);
          },
        );
      },
    );
  }

  Widget _buildQuotesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 48,
              color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma frase salva',
            style: TextStyle(
              color: UltravioletColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guarde suas inspirações, pensamentos e\ncitações favoritas aqui.',
            style: TextStyle(
              color: UltravioletColors.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddQuoteDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Frase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UltravioletColors.accent,
                foregroundColor: Colors.white,
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

  Widget _buildQuoteCard(Quote quote) {
    final text = quote.text;
    final author = quote.author;
    final isFavorite = quote.isFavorite;
    final category = quote.category ?? 'Inspiração';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: UltravioletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: UltravioletColors.accent.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showQuoteActions(quote),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: UltravioletColors.accent,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '— $author',
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: UltravioletColors.accent.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: UltravioletColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : UltravioletColors.onSurfaceVariant,
                      size: 18,
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

  void _showAddQuoteDialog() {
    final textController = TextEditingController();
    final authorController = TextEditingController();
    String category = 'Inspiração';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UltravioletColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nova Frase',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Citação *',
                    hintText: 'Digite a frase inspiradora...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: 'Autor',
                    hintText: 'Quem disse isso?',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Categoria',
                  style: TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Inspiração', 'Filosofia', 'Psicologia', 'Geral']
                      .map((cat) {
                        final isSelected = category == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setModalState(() => category = cat);
                          },
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (textController.text.isEmpty) {
                        FeedbackService.showWarning(
                          context,
                          'Digite o texto da frase',
                        );
                        return;
                      }

                      final repo = ref.read(quotesRepositoryProvider);
                      final newQuote = Quote()
                        ..text = textController.text
                        ..author = authorController.text.isEmpty
                            ? 'Desconhecido'
                            : authorController.text
                        ..category = category
                        ..isFavorite = false
                        ..createdAt = DateTime.now();

                      await repo.addQuote(newQuote);

                      Navigator.pop(context);
                      FeedbackService.showSuccess(
                        context,
                        '✨ Frase inspiradora salva!',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UltravioletColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Salvar Frase',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuoteActions(Quote quote) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
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
                color: UltravioletColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: quote.isFavorite ? Colors.red : null,
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
                setState(() {}); // Refresh list
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
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

  void _showArticleDetail(Map article, Box box) {
    // TODO: Navigate to article detail screen
    _showArticleActions(article, box);
  }

  void _showArticleActions(Map article, Box box) {
    final id = article['id'];
    final status = article['status'] ?? 0;
    final favourite = article['favourite'] ?? false;

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
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
                color: UltravioletColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Status options
            ListTile(
              leading: Icon(
                Icons.bookmark_outline,
                color: status == 0 ? UltravioletColors.primary : null,
              ),
              title: const Text('Para Ler'),
              trailing: status == 0
                  ? const Icon(Icons.check, color: UltravioletColors.primary)
                  : null,
              onTap: () async {
                await box.put(id, {...article, 'status': 0});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.visibility,
                color: status == 1 ? UltravioletColors.primary : null,
              ),
              title: const Text('Lendo'),
              trailing: status == 1
                  ? const Icon(Icons.check, color: UltravioletColors.primary)
                  : null,
              onTap: () async {
                await box.put(id, {...article, 'status': 1});
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: status == 2 ? UltravioletColors.accentGreen : null,
              ),
              title: const Text('Lido'),
              trailing: status == 2
                  ? const Icon(
                      Icons.check,
                      color: UltravioletColors.accentGreen,
                    )
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

  // ==========================================
  // ONLINE ARTICLE SEARCH
  // ==========================================

  void _showOnlineArticleSearch() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
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
                        color: UltravioletColors.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.travel_explore_rounded,
                          color: UltravioletColors.secondary,
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
                              const Text(
                                'Powered by OpenAlex • Milhões de artigos',
                                style: TextStyle(
                                  color: UltravioletColors.onSurfaceVariant,
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
                        fillColor: UltravioletColors.surfaceVariant.withValues(
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
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: UltravioletColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: UltravioletColors.error,
                              ),
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
                              color: UltravioletColors.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Pesquise por um tema',
                              style: TextStyle(
                                color: UltravioletColors.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use os chips acima para buscas rápidas',
                              style: TextStyle(
                                color: UltravioletColors.onSurfaceVariant
                                    .withValues(alpha: 0.7),
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
          ),
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
        backgroundColor: UltravioletColors.surfaceVariant.withValues(
          alpha: 0.5,
        ),
        onPressed: () {
          controller.text = label;
          onSearch(label);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchOpenAlex(String query) async {
    // OpenAlex API - 100% free, no auth required
    // Encode query properly for URL
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
          // Extract authors
          final authorships = work['authorships'] as List? ?? [];
          final authors = authorships
              .take(3)
              .map((a) => a['author']?['display_name'] ?? '')
              .where((name) => name.isNotEmpty)
              .join(', ');

          // Extract publication year
          final year = work['publication_year'];

          // Extract source (journal/venue)
          final source =
              work['primary_location']?['source']?['display_name'] ??
              work['host_venue']?['display_name'] ??
              '';

          // Open access URL
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
            'abstract': work['abstract_inverted_index'] != null
                ? _reconstructAbstract(
                    work['abstract_inverted_index'] as Map<String, dynamic>,
                  )
                : null,
            'doi': work['doi'],
          };
        }).toList();

        return results.cast<Map<String, dynamic>>();
      } else {
        debugPrint(
          'OpenAlex API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      rethrow;
    }
  }

  String _reconstructAbstract(Map<String, dynamic> invertedIndex) {
    // OpenAlex stores abstracts as inverted index, reconstruct it
    final wordPositions = <int, String>{};
    invertedIndex.forEach((word, positions) {
      if (positions is List) {
        for (final pos in positions) {
          if (pos is int) {
            wordPositions[pos] = word;
          }
        }
      }
    });

    final sortedPositions = wordPositions.keys.toList()..sort();
    final words = sortedPositions.map((pos) => wordPositions[pos]).toList();
    final abstract = words.take(50).join(' ');
    return abstract.length > 200
        ? '${abstract.substring(0, 200)}...'
        : '$abstract...';
  }

  Widget _buildSearchResultCard(
    Map<String, dynamic> result,
    BuildContext context,
  ) {
    final isOpenAccess = result['isOpenAccess'] == true;
    final citedCount = result['citedCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: UltravioletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpenAccess
              ? UltravioletColors.accentGreen.withValues(alpha: 0.3)
              : UltravioletColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showArticlePreview(result),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
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
                // Authors & Year
                if (result['authors'] != null &&
                    result['authors'].toString().isNotEmpty)
                  Text(
                    '${result['authors']}${result['year'] != null ? ' • ${result['year']}' : ''}',
                    style: const TextStyle(
                      color: UltravioletColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Source
                if (result['source'] != null &&
                    result['source'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    result['source'],
                    style: const TextStyle(
                      color: UltravioletColors.secondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                // Bottom row
                Row(
                  children: [
                    // Open Access badge
                    if (isOpenAccess)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: UltravioletColors.accentGreen.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_open,
                              size: 12,
                              color: UltravioletColors.accentGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Open Access',
                              style: TextStyle(
                                color: UltravioletColors.accentGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Citations
                    if (citedCount > 0) ...[
                      const Icon(
                        Icons.format_quote,
                        size: 14,
                        color: UltravioletColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$citedCount citações',
                        style: const TextStyle(
                          color: UltravioletColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    // Add button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: UltravioletColors.primary,
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

  void _showArticlePreview(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UltravioletColors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Open Access badge
              if (result['isOpenAccess'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: UltravioletColors.accentGreen.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 14,
                        color: UltravioletColors.accentGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Acesso Aberto',
                        style: TextStyle(
                          color: UltravioletColors.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              // Title
              Text(
                result['title'] ?? 'Sem título',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Authors
              if (result['authors'] != null &&
                  result['authors'].toString().isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result['authors'],
                        style: const TextStyle(
                          color: UltravioletColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Year & Source
              Row(
                children: [
                  if (result['year'] != null) ...[
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${result['year']}',
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (result['citedCount'] != null &&
                      result['citedCount'] > 0) ...[
                    const Icon(
                      Icons.format_quote,
                      size: 14,
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${result['citedCount']} citações',
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              if (result['source'] != null &&
                  result['source'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.library_books_outlined,
                      size: 14,
                      color: UltravioletColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result['source'],
                        style: const TextStyle(
                          color: UltravioletColors.secondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Abstract
              if (result['abstract'] != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Resumo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UltravioletColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result['abstract'],
                  style: const TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Save to library
                        final box = await Hive.openBox('articles');
                        final id = DateTime.now().millisecondsSinceEpoch
                            .toString();

                        await box.put(id, {
                          'id': id,
                          'title': result['title'],
                          'author': result['authors'],
                          'source': result['source'],
                          'url': result['url'],
                          'notes': '',
                          'readingTime': 10,
                          'status': 0,
                          'favourite': false,
                          'dateAdded': DateTime.now().toIso8601String(),
                          'doi': result['doi'],
                          'year': result['year'],
                          'citedCount': result['citedCount'],
                        });

                        Navigator.pop(context);
                        Navigator.pop(context);
                        FeedbackService.showSuccess(
                          context,
                          '📄 Artigo salvo na biblioteca!',
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Salvar na Biblioteca'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UltravioletColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (result['url'] != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // TODO: Open URL
                        FeedbackService.showInfo(context, 'Abrindo artigo...');
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        color: UltravioletColors.secondary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: UltravioletColors.secondary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

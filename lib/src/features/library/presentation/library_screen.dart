import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/library/data/book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/presentation/add_book_screen.dart';
import 'package:odyssey/src/features/library/presentation/sections/articles_section.dart';
import 'package:odyssey/src/features/library/presentation/sections/books_section.dart';
import 'package:odyssey/src/features/library/presentation/sections/quotes_section.dart';
import 'package:odyssey/src/features/library/presentation/statistics_screen.dart';
import 'package:odyssey/src/features/notes/data/quotes_repository.dart';
import 'package:odyssey/src/features/notes/domain/quote.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:showcaseview/showcaseview.dart' as showcase;

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  int _libraryType = 0; // 0: Books, 1: Articles, 2: Quotes
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Keys for showcase
  final GlobalKey _showcaseStats = GlobalKey();
  final GlobalKey _showcaseAdd = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize showcase after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _initShowcase(); // Re-enable when showcase logic is adapted
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = ref.watch(bookRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: ValueListenableBuilder(
        valueListenable: repo.box.listenable(),
        builder: (context, Box<Book> box, _) {
          final allBooks = repo.getAllBooks();
          final stats = {
            'total': allBooks.length,
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
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: colors.surface,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: showcase.Showcase(
                  key: _showcaseStats,
                  description: 'Acompanhe suas estatísticas de leitura aqui',
                  child: Column(
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
                        _getSubtitle(context, stats),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                centerTitle: false,
                actions: [
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
                  showcase.Showcase(
                    key: _showcaseAdd,
                    description: 'Adicione novos livros, artigos ou frases',
                    child: IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showOptionsMenu(context),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLibraryToggle(context),
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                _buildSearchBar(context),
                Expanded(child: _buildCurrentSection()),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getSubtitle(BuildContext context, Map<String, dynamic> bookStats) {
    if (_libraryType == 0) {
      return '${bookStats['total']} livros • ${bookStats['pages']} páginas lidas';
    } else if (_libraryType == 1) {
      return 'Artigos, posts e notícias salvas';
    } else {
      return 'Citações e inspirações';
    }
  }

  Widget _buildCurrentSection() {
    switch (_libraryType) {
      case 1:
        return ArticlesSection(
          searchQuery: _searchQuery,
          onAddArticle: _showAddArticleDialog,
        );
      case 2:
        return QuotesSection(
          searchQuery: _searchQuery,
          onAddQuote: _showAddQuoteDialog,
        );
      case 0:
      default:
        return BooksSection(
          searchQuery: _searchQuery,
          onAddBook: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBookScreen()),
            );
          },
        );
    }
  }

  Widget _buildLibraryToggle(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(context, 0, 'Livros', Icons.book),
          const SizedBox(width: 8),
          _buildToggleButton(context, 1, 'Artigos', Icons.article),
          const SizedBox(width: 8),
          _buildToggleButton(context, 2, 'Frases', Icons.format_quote),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = _libraryType == index;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          setState(() {
            _libraryType = index;
            _searchQuery = ''; // Reset search when switching sections
            _searchController.clear();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.1),
          ),
          boxShadow: null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: _libraryType == 0
              ? 'Buscar livros...'
              : _libraryType == 1
              ? 'Buscar artigos...'
              : 'Buscar frases...',
          prefixIcon: Icon(
            Icons.search,
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: colors.primary),
              const SizedBox(width: 12),
              const Text('Adicionar Livro'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.article_outlined, color: colors.secondary),
              const SizedBox(width: 12),
              const Text('Adicionar Artigo'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded, color: colors.tertiary),
              const SizedBox(width: 12),
              const Text('Adicionar Frase'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddBookScreen()),
        );
      } else if (value == 1) {
        _showAddArticleDialog();
      } else if (value == 2) {
        _showAddQuoteDialog();
      }
    });
  }

  void _showAddArticleDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final urlController = TextEditingController();
    final notesController = TextEditingController();
    final sourceController = TextEditingController();
    int? readingTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
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
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Digite o título do artigo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorController,
                        decoration: InputDecoration(
                          labelText: 'Autor',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minutos',
                          prefixIcon: const Icon(Icons.timer_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) => readingTime = int.tryParse(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Fonte / Site',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL (Opcional)',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Anotações sobre o artigo...',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
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

                      if (context.mounted) {
                        Navigator.pop(context);
                        FeedbackService.showSuccess(
                          context,
                          '📄 Artigo adicionado!',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
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

  void _showAddQuoteDialog() {
    final textController = TextEditingController();
    final authorController = TextEditingController();
    String category = 'Inspiração';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
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
                Text(
                  'Categoria',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                      if (context.mounted) {
                        Navigator.pop(context);
                        FeedbackService.showSuccess(
                          context,
                          '✨ Frase inspiradora salva!',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
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
}

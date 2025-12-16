import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/utils/widgets/staggered_list_animation.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/features/notes/presentation/note_editor_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  // Showcase keys
  final GlobalKey _showcaseAdd = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseList = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseSearch = GlobalKey();
  late TabController _tabController;
  Box? _notesBox;
  Box? _quotesBox;
  bool _isLoading = true;
  bool _isGridView = true; // Toggle entre grid e lista
  String _sortBy = 'date'; // 'date', 'title', 'pinned'

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBoxes();
  }

  Future<void> _initializeBoxes() async {
    // Timeout de segurança para não ficar loading infinito
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        debugPrint('NotesScreen: Timeout reached, forcing loading to complete');
        setState(() => _isLoading = false);
      }
    });
    
    await _openBoxes();
  }

  Future<void> _openBoxes() async {
    try {
      // Abrir boxes com tratamento de erro individual
      try {
        if (Hive.isBoxOpen('notes_v2')) {
          _notesBox = Hive.box('notes_v2');
        } else {
          _notesBox = await Hive.openBox('notes_v2');
        }
      } catch (e) {
        debugPrint('Error opening notes box: $e');
      }

      try {
        if (Hive.isBoxOpen('quotes')) {
          _quotesBox = Hive.box('quotes');
        } else {
          _quotesBox = await Hive.openBox('quotes');
        }
      } catch (e) {
        debugPrint('Error opening quotes box: $e');
      }
      
      if (_quotesBox != null && _quotesBox!.isEmpty) {
        await _addSampleQuotes();
      }
    } catch (e) {
      debugPrint('Error opening boxes in NotesScreen: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSampleQuotes() async {
    final sampleQuotes = [
      {'id': '1', 'text': 'A única maneira de fazer um excelente trabalho é amar o que você faz.', 'author': 'Steve Jobs', 'category': 'motivational', 'isFavorite': true},
      {'id': '2', 'text': 'O sucesso é a soma de pequenos esforços repetidos dia após dia.', 'author': 'Robert Collier', 'category': 'motivational', 'isFavorite': false},
      {'id': '3', 'text': 'Conhece-te a ti mesmo.', 'author': 'Sócrates', 'category': 'philosophical', 'isFavorite': true},
      {'id': '4', 'text': 'A vida é o que acontece enquanto você está ocupado fazendo outros planos.', 'author': 'John Lennon', 'category': 'philosophical', 'isFavorite': true},
      {'id': '5', 'text': 'Seja a mudança que você deseja ver no mundo.', 'author': 'Mahatma Gandhi', 'category': 'motivational', 'isFavorite': true},
      {'id': '6', 'text': 'A imaginação é mais importante que o conhecimento.', 'author': 'Albert Einstein', 'category': 'philosophical', 'isFavorite': false},
      {'id': '7', 'text': 'Não é a mais forte das espécies que sobrevive, nem a mais inteligente, mas a que melhor se adapta às mudanças.', 'author': 'Charles Darwin', 'category': 'philosophical', 'isFavorite': true},
      {'id': '8', 'text': 'O medo de sofrer é pior que o próprio sofrimento.', 'author': 'Paulo Coelho', 'category': 'philosophical', 'isFavorite': false},
      {'id': '9', 'text': 'A persistência é o caminho do êxito.', 'author': 'Charlie Chaplin', 'category': 'motivational', 'isFavorite': true},
      {'id': '10', 'text': 'Tudo o que temos de decidir é o que fazer com o tempo que nos é dado.', 'author': 'J.R.R. Tolkien', 'category': 'philosophical', 'isFavorite': true},
      {'id': '11', 'text': 'Nada do que é humano me é estranho.', 'author': 'Terêncio', 'category': 'philosophical', 'isFavorite': false},
      {'id': '12', 'text': 'O homem é aquilo que ele faz de si mesmo.', 'author': 'Jean-Paul Sartre', 'category': 'philosophical', 'isFavorite': true},
    ];
    
    for (final quote in sampleQuotes) {
      await _quotesBox!.put(quote['id'], {
        ...quote,
        'createdAt': DateTime.now().subtract(Duration(days: int.parse(quote['id'] as String))).toIso8601String(),
      });
    }
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.notes);
    _tabController.dispose();
    super.dispose();
  }
  void _initShowcase() {
    final keys = [_showcaseSearch, _showcaseList, _showcaseAdd];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.notes,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.notes, keys);
  }
  
  void _startTour() {
    final keys = [_showcaseSearch, _showcaseList, _showcaseAdd];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.notes, keys);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: UltravioletColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: UltravioletColors.cardBackground, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Biblioteca', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  // Botão de ordenação
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: UltravioletColors.cardBackground, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.sort, color: UltravioletColors.onSurfaceVariant, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão de view (grid/lista)
                  GestureDetector(
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: UltravioletColors.cardBackground, borderRadius: BorderRadius.circular(10)),
                      child: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: UltravioletColors.onSurfaceVariant, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showSearchSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: UltravioletColors.cardBackground, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.search, color: UltravioletColors.onSurfaceVariant, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: UltravioletColors.cardBackground, borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: UltravioletColors.primary, borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: UltravioletColors.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Notas'),
                  Tab(text: 'Frases'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildNotesTab(), _buildQuotesTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: UltravioletColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_notesBox == null) return _buildErrorState('Erro ao carregar notas');
    return ValueListenableBuilder(
      valueListenable: _notesBox!.listenable(),
      builder: (context, box, _) {
        var notes = box.keys.toList();
        if (notes.isEmpty) return _buildEmptyState(icon: Icons.sticky_note_2_outlined, title: 'Nenhuma nota ainda', subtitle: 'Toque no + para criar sua primeira nota');
        
        // Ordenar notas
        notes = _sortNotes(notes.cast<String>(), box);
        
        if (_isGridView) {
          return MasonryGridView.count(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final key = notes[index] as String;
              final data = Map<String, dynamic>.from(box.get(key) as Map);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteCard(key, data, index),
              );
            },
          );
        } else {
          // Vista em lista
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final key = notes[index] as String;
              final data = Map<String, dynamic>.from(box.get(key) as Map);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteListItem(key, data, index),
              );
            },
          );
        }
      },
    );
  }
  
  List<String> _sortNotes(List<String> notes, Box box) {
    final notesList = notes.map((key) => {'key': key, 'data': box.get(key) as Map}).toList();
    
    switch (_sortBy) {
      case 'title':
        notesList.sort((a, b) {
          final titleA = (a['data'] as Map)['title'] as String? ?? '';
          final titleB = (b['data'] as Map)['title'] as String? ?? '';
          return titleA.toLowerCase().compareTo(titleB.toLowerCase());
        });
        break;
      case 'pinned':
        notesList.sort((a, b) {
          final pinnedA = (a['data'] as Map)['isPinned'] == true ? 0 : 1;
          final pinnedB = (b['data'] as Map)['isPinned'] == true ? 0 : 1;
          if (pinnedA != pinnedB) return pinnedA.compareTo(pinnedB);
          // Se ambos têm mesmo status de pin, ordenar por data
          final dateA = DateTime.tryParse((a['data'] as Map)['createdAt'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse((b['data'] as Map)['createdAt'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date':
      default:
        notesList.sort((a, b) {
          final dateA = DateTime.tryParse((a['data'] as Map)['createdAt'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse((b['data'] as Map)['createdAt'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
    }
    
    return notesList.map((n) => n['key'] as String).toList();
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ordenar por', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSortOption('date', 'Data (mais recente)', Icons.calendar_today),
              _buildSortOption('title', 'Título (A-Z)', Icons.sort_by_alpha),
              _buildSortOption('pinned', 'Fixadas primeiro', Icons.push_pin),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? UltravioletColors.primary : UltravioletColors.onSurfaceVariant),
      title: Text(label, style: TextStyle(color: isSelected ? UltravioletColors.primary : null, fontWeight: isSelected ? FontWeight.w600 : null)),
      trailing: isSelected ? const Icon(Icons.check, color: UltravioletColors.primary) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
  
  Widget _buildNoteListItem(String id, Map<String, dynamic> data, int index) {
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final dateStr = data['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final isPinned = data['isPinned'] as bool? ?? false;
    final colors = [UltravioletColors.primary, UltravioletColors.secondary, UltravioletColors.tertiary, UltravioletColors.accentGreen];
    final color = colors[index % colors.length];
    
    return OdysseyCard(
      onTap: () => _showNoteEditor(id: id, initialData: data),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: isPinned ? color.withOpacity(0.5) : Theme.of(context).colorScheme.outline.withOpacity(0.1),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPinned) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 14, color: color)),
                    Expanded(
                      child: Text(
                        title ?? content.split('\n').first,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (title != null && content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String id, Map<String, dynamic> data, int index) {
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final dateStr = data['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final isPinned = data['isPinned'] as bool? ?? false;
    final colors = [UltravioletColors.primary, UltravioletColors.secondary, UltravioletColors.tertiary, UltravioletColors.accentGreen];
    final color = colors[index % colors.length];

    return OdysseyCard(
      onTap: () => _showNoteEditor(id: id, initialData: data),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: isPinned ? color.withOpacity(0.5) : Theme.of(context).colorScheme.outline.withOpacity(0.1),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.5)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned || title != null)
                  Row(children: [
                    if (isPinned) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.push_pin, size: 16, color: color)),
                    if (title != null) Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                if (title != null) const SizedBox(height: 8),
                Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: title != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface), maxLines: 4, overflow: TextOverflow.ellipsis),
                if (date != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(_formatDate(date), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6))),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesTab() {
    if (_quotesBox == null) return _buildErrorState('Erro ao carregar frases');
    return ValueListenableBuilder(
      valueListenable: _quotesBox!.listenable(),
      builder: (context, box, _) {
        final quotes = box.keys.toList().reversed.toList();
        if (quotes.isEmpty) return _buildEmptyState(icon: Icons.format_quote_outlined, title: 'Nenhuma frase ainda', subtitle: 'Guarde suas citações e ideias favoritas');
        
        final allQuotes = quotes.map((k) => Map<String, dynamic>.from(box.get(k) as Map)).toList();
        final favorites = allQuotes.where((q) => q['isFavorite'] == true).toList();
        final others = allQuotes.where((q) => q['isFavorite'] != true).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (allQuotes.isNotEmpty) _buildQuoteOfTheDay(favorites.isNotEmpty ? favorites.first : allQuotes.first),
            const SizedBox(height: 24),
            if (favorites.isNotEmpty) ...[_buildQuoteSectionHeader('Favoritas', Icons.favorite, favorites.length), const SizedBox(height: 12), ...favorites.map((q) => _buildQuoteCard(q)), const SizedBox(height: 24)],
            if (others.isNotEmpty) ...[_buildQuoteSectionHeader('Todas', Icons.format_quote, others.length), const SizedBox(height: 12), ...others.map((q) => _buildQuoteCard(q))],
          ]),
        );
      },
    );
  }

  Widget _buildQuoteSectionHeader(String title, IconData icon, int count) {
    return Row(children: [
      Icon(icon, size: 20, color: UltravioletColors.onSurfaceVariant),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: UltravioletColors.surfaceVariant, borderRadius: BorderRadius.circular(8)), child: Text('$count', style: const TextStyle(fontSize: 12, color: UltravioletColors.onSurfaceVariant))),
    ]);
  }

  Widget _buildQuoteOfTheDay(Map<String, dynamic> quote) {
    return OdysseyCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      gradientColors: [
        Theme.of(context).colorScheme.primary.withOpacity(0.15),
        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      ],
      borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      borderRadius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20)),
          const SizedBox(width: 10),
          Text('Frase do Dia', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
        ]),
        const SizedBox(height: 16),
        Text('"${quote['text']}"', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.5)),
        if (quote['author'] != null) ...[const SizedBox(height: 12), Text('— ${quote['author']}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))],
      ]),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final isFavorite = quote['isFavorite'] == true;
    return OdysseyCard(
      onTap: () => _showQuoteEditor(id: quote['id'], initialData: quote),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: isFavorite ? Theme.of(context).colorScheme.tertiary.withOpacity(0.3) : Theme.of(context).colorScheme.outline.withOpacity(0.1),
      borderRadius: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.format_quote, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5), size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(quote['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.4))),
          GestureDetector(onTap: () => _toggleQuoteFavorite(quote['id']), child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant, size: 20)),
        ]),
        if (quote['author'] != null) ...[
          const SizedBox(height: 10),
          Row(children: [const SizedBox(width: 32), Text('— ${quote['author']}${quote['source'] != null ? ', ${quote['source']}' : ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))]),
        ],
      ]),
    );
  }

  void _toggleQuoteFavorite(String id) {
    final quote = _quotesBox!.get(id) as Map;
    final updated = Map<String, dynamic>.from(quote);
    updated['isFavorite'] = !(quote['isFavorite'] == true);
    _quotesBox!.put(id, updated);
    HapticFeedback.lightImpact();
  }

  void _showAddDialog() {
    switch (_tabController.index) {
      case 0: _showNoteEditor(); break;
      case 1: _showQuoteEditor(); break;
    }
  }

  void _showNoteEditor({String? id, Map<String, dynamic>? initialData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          noteId: id,
          initialData: initialData,
        ),
      ),
    );
  }

  void _showQuoteEditor({String? id, Map<String, dynamic>? initialData}) {
    final textController = TextEditingController(text: initialData?['text'] ?? '');
    final authorController = TextEditingController(text: initialData?['author'] ?? '');
    final sourceController = TextEditingController(text: initialData?['source'] ?? '');
    final isEditing = id != null;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isEditing ? 'Editar Frase' : 'Nova Frase', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            if (isEditing) IconButton(onPressed: () { Navigator.pop(context); _deleteQuote(id); }, icon: const Icon(Icons.delete_outline, color: UltravioletColors.error)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: textController, autofocus: true, maxLines: 4, decoration: InputDecoration(hintText: 'A frase ou citação...', filled: true, fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: authorController, decoration: InputDecoration(hintText: 'Autor', prefixIcon: const Icon(Icons.person_outline, size: 20), filled: true, fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: sourceController, decoration: InputDecoration(hintText: 'Fonte', prefixIcon: const Icon(Icons.source_outlined, size: 20), filled: true, fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isEmpty) return;
              HapticFeedback.mediumImpact();
              final quoteId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
              _quotesBox!.put(quoteId, {'id': quoteId, 'text': text, 'author': authorController.text.trim().isEmpty ? null : authorController.text.trim(), 'source': sourceController.text.trim().isEmpty ? null : sourceController.text.trim(), 'createdAt': initialData?['createdAt'] ?? DateTime.now().toIso8601String(), 'isFavorite': initialData?['isFavorite'] ?? false});
              Navigator.pop(context);
              FeedbackService.showSuccess(context, isEditing ? 'Frase atualizada!' : 'Frase salva!', icon: Icons.format_quote);
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isEditing ? 'Salvar' : 'Adicionar Frase'),
          )),
        ]),
      ),
    );
  }

  void _deleteNote(String id) {
    soundService.playModalOpen();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: UltravioletColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Excluir nota?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), ElevatedButton(onPressed: () { _notesBox!.delete(id); Navigator.pop(context); soundService.playDelete(); }, style: ElevatedButton.styleFrom(backgroundColor: UltravioletColors.error), child: const Text('Excluir'))],
    ));
  }

  void _deleteQuote(String id) {
    soundService.playModalOpen();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: UltravioletColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Excluir frase?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), ElevatedButton(onPressed: () { _quotesBox!.delete(id); Navigator.pop(context); soundService.playDelete(); }, style: ElevatedButton.styleFrom(backgroundColor: UltravioletColors.error), child: const Text('Excluir'))],
    ));
  }

  void _showSearchSheet() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Busca em desenvolvimento'))); }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: UltravioletColors.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Icon(icon, size: 40, color: UltravioletColors.tertiary)),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: UltravioletColors.onSurfaceVariant), textAlign: TextAlign.center),
    ])));
  }

  Widget _buildErrorState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: UltravioletColors.error),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: UltravioletColors.error)),
    ]));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) { if (diff.inHours == 0) return 'Há ${diff.inMinutes} min'; return 'Há ${diff.inHours}h'; }
    else if (diff.inDays == 1) return 'Ontem';
    else if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    else return DateFormat('dd/MM/yyyy').format(date);
  }
}

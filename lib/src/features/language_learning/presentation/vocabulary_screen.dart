import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/language_learning_repository.dart';
import '../domain/vocabulary_item.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  final String languageId;
  final String languageName;
  final Color languageColor;
  final bool showReviewMode;

  const VocabularyScreen({
    super.key,
    required this.languageId,
    required this.languageName,
    required this.languageColor,
    this.showReviewMode = false,
  });

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> with SingleTickerProviderStateMixin {
  late LanguageLearningRepository _repository;
  late TabController _tabController;
  List<VocabularyItem> _allVocabulary = [];
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(languageLearningRepositoryProvider);
    _tabController = TabController(length: 4, vsync: this);
    if (widget.showReviewMode) {
      _tabController.index = 1; // Go to "Para Revisar" tab
    }
    _loadVocabulary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVocabulary() {
    setState(() {
      _allVocabulary = _repository.getVocabularyForLanguage(widget.languageId);
    });
  }

  List<VocabularyItem> _getFilteredVocabulary(String? statusFilter, bool needsReviewFilter) {
    var items = _allVocabulary;

    if (statusFilter != null) {
      items = items.where((v) => v.status == statusFilter).toList();
    }

    if (needsReviewFilter) {
      items = items.where((v) => v.needsReview).toList();
    }

    if (_searchQuery.isNotEmpty) {
      items = items.where((v) =>
          v.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.translation.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_selectedCategory != null) {
      items = items.where((v) => v.category == _selectedCategory).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = widget.languageColor;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors, color),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar palavras...',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: [
                  Tab(text: 'Todas (${_allVocabulary.length})'),
                  Tab(text: 'Revisar (${_getFilteredVocabulary(null, true).length})'),
                  const Tab(text: 'Aprendendo'),
                  const Tab(text: 'Dominadas'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVocabularyList(colors, null, false),
                  _buildVocabularyList(colors, null, true),
                  _buildVocabularyList(colors, VocabularyStatus.learning, false),
                  _buildVocabularyList(colors, VocabularyStatus.mastered, false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVocabularySheet(),
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), colors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vocabulário',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  widget.languageName,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_allVocabulary.isNotEmpty)
            GestureDetector(
              onTap: () => _startFlashcardReview(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Flashcards',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVocabularyList(ColorScheme colors, String? statusFilter, bool needsReviewFilter) {
    final items = _getFilteredVocabulary(statusFilter, needsReviewFilter);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              needsReviewFilter
                  ? 'Nenhuma palavra para revisar! 🎉'
                  : 'Nenhuma palavra ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              needsReviewFilter
                  ? 'Você está em dia com as revisões'
                  : 'Adicione palavras para estudar',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildVocabularyCard(colors, item);
      },
    );
  }

  Widget _buildVocabularyCard(ColorScheme colors, VocabularyItem item) {
    final statusColor = Color(VocabularyStatus.getColor(item.status));

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await _repository.deleteVocabularyItem(item.id);
        _loadVocabulary();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: () => _showVocabularyDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),

              // Word info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (item.pronunciation != null)
                      Text(
                        item.pronunciation!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      item.translation,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Review info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.needsReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Revisar',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 2),
                      Text(
                        '${(item.accuracy * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVocabularySheet() {
    final colors = Theme.of(context).colorScheme;
    final wordController = TextEditingController();
    final translationController = TextEditingController();
    final pronunciationController = TextEditingController();
    final exampleController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
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
                        color: colors.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Adicionar Palavra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Word field
                  TextField(
                    controller: wordController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Palavra *',
                      hintText: 'Ex: Hello',
                      labelStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Translation field
                  TextField(
                    controller: translationController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Tradução *',
                      hintText: 'Ex: Olá',
                      labelStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pronunciation field
                  TextField(
                    controller: pronunciationController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Pronúncia (opcional)',
                      hintText: 'Ex: /həˈloʊ/',
                      labelStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Example sentence
                  TextField(
                    controller: exampleController,
                    style: TextStyle(color: colors.onSurface),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Exemplo (opcional)',
                      hintText: 'Ex: Hello, how are you?',
                      labelStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category selector
                  Text(
                    'CATEGORIA (opcional)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: VocabularyCategories.all.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            selectedCategory = isSelected ? null : cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.languageColor.withValues(alpha: 0.2)
                                : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? widget.languageColor
                                  : colors.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? widget.languageColor : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: wordController.text.isEmpty || translationController.text.isEmpty
                          ? null
                          : () async {
                              await _repository.addVocabularyItem(
                                languageId: widget.languageId,
                                word: wordController.text,
                                translation: translationController.text,
                                pronunciation: pronunciationController.text.isEmpty
                                    ? null
                                    : pronunciationController.text,
                                exampleSentence: exampleController.text.isEmpty
                                    ? null
                                    : exampleController.text,
                                category: selectedCategory,
                              );
                              _loadVocabulary();
                              if (mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.languageColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVocabularyDetail(VocabularyItem item) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = Color(VocabularyStatus.getColor(item.status));

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
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
                  color: colors.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Word and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.word,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      if (item.pronunciation != null)
                        Text(
                          item.pronunciation!,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    VocabularyStatus.getDisplayName(item.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Translation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.languageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.translation,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Example
            if (item.exampleSentence != null) ...[
              Text(
                'Exemplo:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.exampleSentence!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailStat(colors, '${item.reviewCount}', 'Revisões'),
                _buildDetailStat(colors, '${(item.accuracy * 100).round()}%', 'Acertos'),
                _buildDetailStat(colors, item.category ?? '-', 'Categoria'),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            if (item.needsReview)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _repository.reviewVocabularyItem(item.id, false);
                        _loadVocabulary();
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Errei', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _repository.reviewVocabularyItem(item.id, true);
                        _loadVocabulary();
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)!.acertei),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(ColorScheme colors, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _startFlashcardReview() {
    final itemsToReview = _getFilteredVocabulary(null, true);
    if (itemsToReview.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.naoHaPalavrasParaRevisarAgora)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardReviewScreen(
          items: itemsToReview,
          repository: _repository,
          languageColor: widget.languageColor,
        ),
      ),
    ).then((_) => _loadVocabulary());
  }
}

// Flashcard Review Screen
class FlashcardReviewScreen extends StatefulWidget {
  final List<VocabularyItem> items;
  final LanguageLearningRepository repository;
  final Color languageColor;

  const FlashcardReviewScreen({
    super.key,
    required this.items,
    required this.repository,
    required this.languageColor,
  });

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;
  int _incorrectCount = 0;

  VocabularyItem get currentItem => widget.items[_currentIndex];
  bool get isFinished => _currentIndex >= widget.items.length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isFinished) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration,
                  size: 80,
                  color: widget.languageColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Revisão Concluída! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildResultCard(colors, _correctCount, 'Acertos', const Color(0xFF10B981)),
                    const SizedBox(width: 20),
                    _buildResultCard(colors, _incorrectCount, 'Erros', Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${((_correctCount / widget.items.length) * 100).round()}% de acertos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.languageColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Concluir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.items.length,
                backgroundColor: colors.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(widget.languageColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 32),

            // Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showAnswer = !_showAnswer),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showAnswer
                          ? [widget.languageColor.withValues(alpha: 0.15), widget.languageColor.withValues(alpha: 0.05)]
                          : [colors.surfaceContainerHighest, colors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _showAnswer
                          ? widget.languageColor.withValues(alpha: 0.3)
                          : colors.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAnswer ? currentItem.translation : currentItem.word,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_showAnswer && currentItem.pronunciation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          currentItem.pronunciation!,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        _showAnswer ? 'Toque para ver a palavra' : 'Toque para ver a tradução',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            if (_showAnswer)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleAnswer(false),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Errei', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAnswer(true),
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)!.acertei),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ColorScheme colors, int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAnswer(bool wasCorrect) async {
    HapticFeedback.mediumImpact();
    await widget.repository.reviewVocabularyItem(currentItem.id, wasCorrect);

    setState(() {
      if (wasCorrect) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
      _currentIndex++;
      _showAnswer = false;
    });
  }
}

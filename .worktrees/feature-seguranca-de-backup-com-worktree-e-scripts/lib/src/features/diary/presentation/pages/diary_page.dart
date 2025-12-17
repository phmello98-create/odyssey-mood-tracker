import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/diary_providers.dart';
import '../../data/models/diary_entry.dart';
import 'diary_editor_page.dart';

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  String _searchQuery = '';
  bool _showStarredOnly = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = _showStarredOnly
        ? ref.watch(starredEntriesProvider)
        : _searchQuery.isEmpty
            ? ref.watch(diaryEntriesProvider)
            : ref.watch(searchEntriesProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário'),
        actions: [
          IconButton(
            icon: Icon(
              _showStarredOnly ? Icons.star : Icons.star_border,
              color: _showStarredOnly ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _showStarredOnly = !_showStarredOnly;
              });
            },
            tooltip: 'Favoritos',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) => entries.isEmpty
            ? _buildEmptyState()
            : _buildEntriesList(entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar entradas: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewEntry(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Entrada'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showStarredOnly
                ? 'Nenhuma entrada favorita'
                : _searchQuery.isNotEmpty
                    ? 'Nenhuma entrada encontrada'
                    : 'Comece seu diário!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showStarredOnly
                ? 'Marque entradas como favoritas para vê-las aqui'
                : _searchQuery.isNotEmpty
                    ? 'Tente buscar por outro termo'
                    : 'Clique no botão + para criar sua primeira entrada',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<DiaryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _DiaryEntryCard(
          entry: entry,
          onTap: () => _openEntry(context, entry),
        );
      },
    );
  }

  void _createNewEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
    );
  }

  void _openEntry(BuildContext context, DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiaryEditorPage(entryId: entry.id)),
    );
  }

  Future<void> _showSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar no Diário'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _searchQuery = result;
      });
    }
  }
}

class _DiaryEntryCard extends ConsumerWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const _DiaryEntryCard({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com data e ações
              Row(
                children: [
                  if (entry.feeling != null) ...[
                    Text(
                      entry.feeling!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(entry.entryDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeFormat.format(entry.entryDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      entry.starred ? Icons.star : Icons.star_border,
                      color: entry.starred ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => _toggleStarred(ref),
                  ),
                ],
              ),

              // Título
              if (entry.title != null && entry.title!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entry.title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Preview do conteúdo
              if (entry.searchableText != null &&
                  entry.searchableText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.searchableText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStarred(WidgetRef ref) async {
    final repository = ref.read(diaryRepositoryProvider);
    await repository.toggleStarred(entry.id);
    ref.invalidate(diaryEntriesProvider);
    ref.invalidate(starredEntriesProvider);
  }
}

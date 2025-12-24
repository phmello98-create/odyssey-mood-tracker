import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/diary_entry_isar.dart';
import '../controllers/diary_isar_provider.dart';
import '../widgets/diary_calendar_strip.dart';
import '../widgets/diary_search_bar.dart';
import 'diary_editor_page.dart';

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  bool _showStarredOnly = false;
  bool _isCardView = true;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(diarySearchQueryProvider);
    final isSearchActive = searchQuery.isNotEmpty && searchQuery.length >= 2;

    // Usar provider filtrado quando busca está ativa
    final entriesAsync = ref.watch(diaryFilteredEntriesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Meu Diário',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isCardView ? Icons.view_list : Icons.view_agenda),
                tooltip: _isCardView ? 'Ver como lista' : 'Ver como cards',
                onPressed: () => setState(() => _isCardView = !_isCardView),
              ),
              IconButton(
                icon: Icon(_showStarredOnly ? Icons.star : Icons.star_border),
                color: _showStarredOnly ? Colors.amber : null,
                onPressed: () =>
                    setState(() => _showStarredOnly = !_showStarredOnly),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ==========================================
          // BARRA DE BUSCA INTELIGENTE
          // ==========================================
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DiarySearchBar(),
            ),
          ),

          // Sugestões de busca rápida (quando não há busca ativa)
          if (!isSearchActive)
            const SliverToBoxAdapter(child: DiarySearchSuggestions()),

          // Contador de resultados (quando busca está ativa)
          if (isSearchActive)
            SliverToBoxAdapter(
              child: entriesAsync.when(
                data: (entries) => DiarySearchResultsCount(
                  count: entries.length,
                  query: searchQuery,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Calendário Horizontal (apenas quando não há busca)
          if (!isSearchActive)
            SliverToBoxAdapter(
              child: DiaryCalendarStrip(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          entriesAsync.when(
            data: (entries) {
              var displayedEntries = entries;

              // Filtro por favoritos
              if (_showStarredOnly) {
                displayedEntries = displayedEntries
                    .where((e) => e.isStarred)
                    .toList();
              }

              // Filtro por data (apenas quando não há busca)
              if (_selectedDate != null && !isSearchActive) {
                displayedEntries = displayedEntries.where((e) {
                  return e.entryDate.year == _selectedDate!.year &&
                      e.entryDate.month == _selectedDate!.month &&
                      e.entryDate.day == _selectedDate!.day;
                }).toList();
              }

              if (displayedEntries.isEmpty) {
                // Estado vazio específico para busca
                if (isSearchActive) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: DiarySearchEmptyState(query: searchQuery),
                  );
                }

                // Estado vazio normal (sem busca)
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDate == null
                              ? 'Seu diário está vazio'
                              : 'Nada neste dia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedDate == null)
                          Text(
                            'Toque em + para começar',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  80,
                ), // Padding extra embaixo
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = displayedEntries[index];
                    return _isCardView
                        ? _DiaryEntryCard(
                            entry: entry,
                            searchQuery: searchQuery,
                          )
                        : _DiaryEntryListItem(
                            entry: entry,
                            searchQuery: searchQuery,
                          );
                  }, childCount: displayedEntries.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Erro ao carregar diário: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
          );
        },
        label: const Text('Escrever'),
        icon: const Icon(Icons.edit),
      ),
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntryIsar entry;
  final String searchQuery;

  const _DiaryEntryCard({required this.entry, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd', 'pt_BR'); // Dia
    final monthFormat = DateFormat('MMM', 'pt_BR'); // Mês abrev
    final timeFormat = DateFormat('HH:mm');

    // Mapeamento de humor para cores e icones (simplificado)
    // Em um app real, use um helper compartilhado
    final moodColor = _getMoodColor(entry.feeling ?? 'neutral');
    final moodIcon = _getMoodIcon(entry.feeling ?? 'neutral');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryEditorPage(
              entryId: entry.id.toString(),
              initialDate: entry.entryDate,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Coluna da Data
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateFormat.format(entry.entryDate),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: moodColor,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      monthFormat.format(entry.entryDate).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: moodColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(moodIcon, color: moodColor, size: 20),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeFormat.format(entry.entryDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (entry.isStarred)
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SearchHighlightText(
                        text: entry.title ?? 'Sem título',
                        query: searchQuery,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      SearchHighlightText(
                        text: entry.searchableText ?? 'Sem conteúdo...',
                        query: searchQuery,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      if (entry.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: entry.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // Preview de Imagem (se existir)
              if (entry.imagePath != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Image.file(
                    File(entry.imagePath!),
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String feeling) {
    switch (feeling) {
      case 'amazing':
        return const Color(0xFF4ADE80);
      case 'good':
        return const Color(0xFF81C784);
      case 'bad':
        return const Color(0xFFFFB74D);
      case 'terrible':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getMoodIcon(String feeling) {
    switch (feeling) {
      case 'amazing':
        return Icons.sentiment_very_satisfied_rounded;
      case 'good':
        return Icons.sentiment_satisfied_rounded;
      case 'bad':
        return Icons.sentiment_dissatisfied_rounded;
      case 'terrible':
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }
}

// ============================================
// LISTA COMPACTA
// ============================================
class _DiaryEntryListItem extends StatelessWidget {
  final DiaryEntryIsar entry;
  final String searchQuery;

  const _DiaryEntryListItem({required this.entry, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final moodColor = _getMoodColor(entry.feeling ?? 'neutral');

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryEditorPage(
              entryId: entry.id.toString(),
              initialDate: entry.entryDate,
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: entry.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(entry.imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildDateBadge(dateFormat, moodColor),
              ),
            )
          : _buildDateBadge(dateFormat, moodColor),
      title: SearchHighlightText(
        text: entry.title ?? 'Sem título',
        query: searchQuery,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            timeFormat.format(entry.entryDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              entry.tags.take(2).map((t) => '#$t').join(' '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isStarred)
            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
          Icon(
            _getMoodIcon(entry.feeling ?? 'neutral'),
            color: moodColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateFormat format, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          format.format(entry.entryDate),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String feeling) {
    switch (feeling) {
      case 'amazing':
        return const Color(0xFF4ADE80);
      case 'good':
        return const Color(0xFF81C784);
      case 'bad':
        return const Color(0xFFFFB74D);
      case 'terrible':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getMoodIcon(String feeling) {
    switch (feeling) {
      case 'amazing':
        return Icons.sentiment_very_satisfied_rounded;
      case 'good':
        return Icons.sentiment_satisfied_rounded;
      case 'bad':
        return Icons.sentiment_dissatisfied_rounded;
      case 'terrible':
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }
}

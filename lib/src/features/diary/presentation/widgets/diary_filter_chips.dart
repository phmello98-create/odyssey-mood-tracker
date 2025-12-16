// lib/src/features/diary/presentation/widgets/diary_filter_chips.dart

import 'package:flutter/material.dart';
import '../../domain/repositories/i_diary_repository.dart';

/// Chips de filtro para o diário
class DiaryFilterChips extends StatelessWidget {
  final DiaryFilter currentFilter;
  final List<String> availableTags;
  final ValueChanged<DiaryFilter> onFilterChanged;

  const DiaryFilterChips({
    super.key,
    required this.currentFilter,
    required this.availableTags,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Filtro de favoritos
          _FilterChip(
            label: 'Favoritos',
            icon: Icons.star_rounded,
            isSelected: currentFilter.starred == true,
            onTap: () {
              onFilterChanged(currentFilter.copyWith(
                starred: currentFilter.starred == true ? null : true,
              ));
            },
            selectedColor: Colors.amber,
          ),

          const SizedBox(width: 8),

          // Filtro por período
          _DateRangeChip(
            currentFilter: currentFilter,
            onFilterChanged: onFilterChanged,
          ),

          const SizedBox(width: 8),

          // Filtro por sentimento
          _FeelingFilterChip(
            currentFilter: currentFilter,
            onFilterChanged: onFilterChanged,
          ),

          const SizedBox(width: 8),

          // Filtro de ordenação
          _SortChip(
            currentSort: currentFilter.sortOrder,
            onSortChanged: (sort) {
              onFilterChanged(currentFilter.copyWith(sortOrder: sort));
            },
          ),

          // Tags
          if (availableTags.isNotEmpty) ...[
            const SizedBox(width: 8),
            _TagsFilterChip(
              availableTags: availableTags,
              selectedTags: currentFilter.tags,
              onTagsChanged: (tags) {
                onFilterChanged(currentFilter.copyWith(
                  tags: tags.isEmpty ? null : tags,
                ));
              },
            ),
          ],

          // Botão de limpar filtros
          if (currentFilter.hasFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: Icon(
                Icons.clear_rounded,
                size: 16,
                color: colorScheme.error,
              ),
              label: Text(
                'Limpar',
                style: TextStyle(color: colorScheme.error),
              ),
              onPressed: () {
                onFilterChanged(currentFilter.clearFilters());
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = selectedColor ?? colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? effectiveColor : colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onSelected: (_) => onTap(),
      selectedColor: effectiveColor.withValues(alpha: 0.2),
      checkmarkColor: effectiveColor,
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  final DiaryFilter currentFilter;
  final ValueChanged<DiaryFilter> onFilterChanged;

  const _DateRangeChip({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = currentFilter.startDate != null || currentFilter.endDate != null;

    return FilterChip(
      selected: hasDateFilter,
      label: const Text('Data'),
      avatar: const Icon(Icons.calendar_today_rounded, size: 18),
      onSelected: (_) => _showDatePicker(context),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: currentFilter.startDate != null && currentFilter.endDate != null
          ? DateTimeRange(start: currentFilter.startDate!, end: currentFilter.endDate!)
          : null,
      locale: const Locale('pt', 'BR'),
    );

    if (result != null) {
      onFilterChanged(currentFilter.copyWith(
        startDate: result.start,
        endDate: result.end,
      ));
    }
  }
}

class _FeelingFilterChip extends StatelessWidget {
  final DiaryFilter currentFilter;
  final ValueChanged<DiaryFilter> onFilterChanged;

  static const _feelings = [
    '😊', '😄', '🥳', '😍', // Feliz
    '😌', '🧘', '☮️',       // Calmo
    '😢', '😭', '😞',       // Triste
    '😡', '😤', '🤬',       // Irritado
    '😰', '😨', '😱',       // Ansioso
    '🤔', '💭', '🧐',       // Pensativo
  ];

  const _FeelingFilterChip({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFeeling = currentFilter.feeling != null;

    return FilterChip(
      selected: hasFeeling,
      label: Text(hasFeeling ? currentFilter.feeling! : 'Sentimento'),
      onSelected: (_) => _showFeelingPicker(context),
    );
  }

  void _showFeelingPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar por sentimento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentFilter.feeling != null)
                  TextButton(
                    onPressed: () {
                      onFilterChanged(currentFilter.copyWith(feeling: null));
                      Navigator.pop(context);
                    },
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _feelings.map((feeling) {
                final isSelected = currentFilter.feeling == feeling;
                return InkWell(
                  onTap: () {
                    onFilterChanged(currentFilter.copyWith(feeling: feeling));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        feeling,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final DiarySortOrder currentSort;
  final ValueChanged<DiarySortOrder> onSortChanged;

  const _SortChip({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    switch (currentSort) {
      case DiarySortOrder.newestFirst:
        label = 'Mais recentes';
        break;
      case DiarySortOrder.oldestFirst:
        label = 'Mais antigas';
        break;
      case DiarySortOrder.alphabetical:
        label = 'A-Z';
        break;
    }

    return PopupMenuButton<DiarySortOrder>(
      initialValue: currentSort,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: DiarySortOrder.newestFirst,
          child: Text('Mais recentes primeiro'),
        ),
        const PopupMenuItem(
          value: DiarySortOrder.oldestFirst,
          child: Text('Mais antigas primeiro'),
        ),
        const PopupMenuItem(
          value: DiarySortOrder.alphabetical,
          child: Text('Ordem alfabética'),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.sort_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _TagsFilterChip extends StatelessWidget {
  final List<String> availableTags;
  final List<String>? selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const _TagsFilterChip({
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedTags = selectedTags != null && selectedTags!.isNotEmpty;

    return FilterChip(
      selected: hasSelectedTags,
      label: Text(hasSelectedTags ? '${selectedTags!.length} tags' : 'Tags'),
      avatar: const Icon(Icons.tag_rounded, size: 18),
      onSelected: (_) => _showTagsPicker(context),
    );
  }

  void _showTagsPicker(BuildContext context) {
    final selected = List<String>.from(selectedTags ?? []);

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtrar por tags',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => selected.clear());
                          },
                          child: const Text('Limpar'),
                        ),
                      FilledButton(
                        onPressed: () {
                          onTagsChanged(selected);
                          Navigator.pop(context);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTags.map((tag) {
                  final isSelected = selected.contains(tag);
                  return FilterChip(
                    label: Text('#$tag'),
                    selected: isSelected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selected.add(tag);
                        } else {
                          selected.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

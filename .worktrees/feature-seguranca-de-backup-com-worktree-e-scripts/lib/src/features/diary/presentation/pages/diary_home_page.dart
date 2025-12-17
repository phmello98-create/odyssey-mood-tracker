// lib/src/features/diary/presentation/pages/diary_home_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../controllers/diary_providers.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/diary_stats_header.dart';
import '../widgets/diary_empty_state.dart';
import '../widgets/diary_search_bar.dart';
import '../widgets/diary_filter_chips.dart';
import '../widgets/diary_view_mode_selector.dart';
import 'diary_editor_page.dart';
import '../../../../localization/app_localizations.dart';

/// Prompts de escrita inspiradores
const List<String> _writingPrompts = [
  'O que te fez sorrir hoje?',
  'Descreva um momento de gratidão',
  'Como você está se sentindo agora?',
  'O que você aprendeu recentemente?',
  'Qual foi o destaque do seu dia?',
  'O que você gostaria de lembrar sobre hoje?',
  'Descreva algo que te inspirou',
  'Que pequena alegria você notou hoje?',
  'O que você está ansioso para fazer?',
  'Descreva uma pessoa que alegrou seu dia',
];

/// Página principal do diário com múltiplas views
class DiaryHomePage extends ConsumerStatefulWidget {
  const DiaryHomePage({super.key});

  @override
  ConsumerState<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends ConsumerState<DiaryHomePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _showSearch = false;
  bool _showWritingPrompt = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _currentPrompt = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _fabAnimationController.forward();

    // Pulse animation for prompts
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Random prompt
    _currentPrompt = _writingPrompts[math.Random().nextInt(_writingPrompts.length)];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(diaryControllerProvider);
    if (state is DiaryStateLoaded && state.hasMore && !state.isLoadingMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(diaryControllerProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar
            _buildAppBar(context, state, colorScheme),

            // Conteúdo baseado no estado
            ..._buildContent(context, state, colorScheme),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, colorScheme),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    DiaryState state,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar.large(
      title: _showSearch
          ? DiarySearchBar(
              autoFocus: true,
              onSearch: (query) {
                ref.read(diaryControllerProvider.notifier).search(query);
              },
              onClear: () {
                setState(() => _showSearch = false);
              },
            )
          : Text(l10n.diaryMyDiary),
      actions: [
        if (!_showSearch) ...[
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => _showSearch = true),
            tooltip: 'Buscar',
          ),
        ],
        if (state is DiaryStateLoaded) ...[
          DiaryViewModeSelector(
            currentMode: state.viewMode,
            onModeChanged: (mode) {
              ref.read(diaryControllerProvider.notifier).setViewMode(mode);
            },
          ),
          const SizedBox(width: 8),
        ],
        PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'insights',
              child: ListTile(
                leading: Icon(Icons.insights_rounded),
                title: Text('Estatísticas'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download_rounded),
                title: Text('Exportar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_rounded),
                title: Text('Configurações'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'insights':
                // TODO: Navegar para insights
                break;
              case 'export':
                _showExportDialog(context);
                break;
              case 'settings':
                // TODO: Navegar para configurações
                break;
            }
          },
        ),
      ],
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    DiaryState state,
    ColorScheme colorScheme,
  ) {
    return switch (state) {
      DiaryStateInitial() || DiaryStateLoading() => [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      DiaryStateError(:final message) => [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      DiaryStateEmpty(:final hasFilters) => [
        SliverFillRemaining(
          child: DiaryEmptyState(
            hasFilters: hasFilters,
            onCreateEntry: () => _openEditor(context),
            onClearFilters: () {
              ref.read(diaryControllerProvider.notifier).clearFilters();
            },
          ),
        ),
      ],
      DiaryStateLoaded(
        :final entries,
        :final filter,
        :final viewMode,
        :final allTags,
        :final hasMore,
        :final isLoadingMore,
      ) => [
        // Writing Prompt Card
        if (!filter.hasFilters && viewMode != DiaryViewMode.calendar)
          SliverToBoxAdapter(
            child: _buildWritingPromptCard(context, colorScheme),
          ),

        // Estatísticas
        if (!filter.hasFilters && viewMode != DiaryViewMode.calendar)
          const SliverToBoxAdapter(
            child: DiaryStatsHeader(),
          ),

        // Filtros
        if (allTags.isNotEmpty || filter.hasFilters)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DiaryFilterChips(
                currentFilter: filter,
                availableTags: allTags,
                onFilterChanged: (newFilter) {
                  ref.read(diaryControllerProvider.notifier).applyFilter(newFilter);
                },
              ),
            ),
          ),

        // Conteúdo baseado no modo de visualização
        ...switch (viewMode) {
          DiaryViewMode.timeline => _buildTimelineView(entries, isLoadingMore, hasMore),
          DiaryViewMode.grid => _buildGridView(entries, isLoadingMore, hasMore),
          DiaryViewMode.calendar => _buildCalendarView(entries, context),
        },
      ],
    };
  }

  List<Widget> _buildTimelineView(
    List<DiaryEntryEntity> entries,
    bool isLoadingMore,
    bool hasMore,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList.builder(
          itemCount: entries.length + (isLoadingMore || hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= entries.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final entry = entries[index];
            // Animação sutil de entrada
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: DiaryEntryCard(
                entry: entry,
                onTap: () => _openEntry(context, entry.id),
                onLongPress: () => _showEntryOptions(context, entry),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildGridView(
    List<DiaryEntryEntity> entries,
    bool isLoadingMore,
    bool hasMore,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= entries.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final entry = entries[index];
              // Animação escalonada para grid
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 40)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: DiaryEntryCardCompact(
                  entry: entry,
                  onTap: () => _openEntry(context, entry.id),
                ),
              );
            },
            childCount: entries.length + (isLoadingMore || hasMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCalendarView(
    List<DiaryEntryEntity> entries,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Agrupar entradas por dia
    final entriesByDay = <DateTime, List<DiaryEntryEntity>>{};
    for (final entry in entries) {
      final key = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      entriesByDay.putIfAbsent(key, () => []).add(entry);
    }

    final selectedEntries = _selectedDay != null
        ? entriesByDay[DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
          )] ?? []
        : <DiaryEntryEntity>[];

    return [
      // Calendário
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              locale: 'pt_BR',
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return entriesByDay[key] ?? [];
              },
            ),
          ),
        ),
      ),

      // Entradas do dia selecionado
      if (_selectedDay != null) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d \'de\' MMMM', 'pt_BR').format(_selectedDay!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${selectedEntries.length} ${selectedEntries.length == 1 ? 'entrada' : 'entradas'}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedEntries.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma entrada neste dia',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => _openEditorForDate(_selectedDay!),
                      child: const Text('Criar entrada'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: selectedEntries.length,
              itemBuilder: (context, index) {
                final entry = selectedEntries[index];
                return DiaryEntryCard(
                  entry: entry,
                  compact: true,
                  showFullDate: false,
                  onTap: () => _openEntry(context, entry.id),
                );
              },
            ),
          ),
      ],

      // Espaço extra no final
      const SliverToBoxAdapter(
        child: SizedBox(height: 100),
      ),
    ];
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Hero(
        tag: 'new_entry_fab',
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _openEditor(context);
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Nova Entrada'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 6,
          highlightElevation: 12,
        ),
      ),
    );
  }

  Widget _buildWritingPromptCard(BuildContext context, ColorScheme colorScheme) {
    if (!_showWritingPrompt) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.tertiaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.tertiary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _openEditorWithPrompt(_currentPrompt);
            },
            borderRadius: BorderRadius.circular(20),
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
                          color: colorScheme.tertiary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: colorScheme.tertiary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Inspiração do dia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _currentPrompt = _writingPrompts[
                                math.Random().nextInt(_writingPrompts.length)];
                          });
                        },
                        tooltip: 'Outro prompt',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _showWritingPrompt = false);
                        },
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"$_currentPrompt"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onTertiaryContainer,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toque para começar a escrever',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditorWithPrompt(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiaryEditorPage(initialPrompt: prompt)),
    ).then((_) {
      ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
    });
  }

  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
    ).then((_) {
      // Recarrega ao voltar
      ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
    });
  }

  void _openEditorForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiaryEditorPage(initialDate: date)),
    ).then((_) {
      ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
    });
  }

  void _openEntry(BuildContext context, String entryId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiaryEditorPage(entryId: entryId)),
    ).then((_) {
      ref.read(diaryControllerProvider.notifier).loadEntries(refresh: true);
    });
  }

  void _showEntryOptions(BuildContext context, DiaryEntryEntity entry) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                entry.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                color: entry.starred ? Colors.amber : null,
              ),
              title: Text(entry.starred ? 'Remover dos favoritos' : 'Adicionar aos favoritos'),
              onTap: () {
                Navigator.pop(context);
                ref.read(diaryControllerProvider.notifier).toggleStarred(entry.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar compartilhamento
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              title: Text('Excluir', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DiaryEntryEntity entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir entrada'),
        content: const Text(
          'Tem certeza que deseja excluir esta entrada? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(diaryControllerProvider.notifier).deleteEntry(entry.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Diário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('JSON'),
              subtitle: const Text('Formato estruturado para backup'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(diaryControllerProvider.notifier)
                    .exportAsJson();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exportado como JSON')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Markdown'),
              subtitle: const Text('Formato legível para texto'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(diaryControllerProvider.notifier)
                    .exportAsMarkdown();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exportado como Markdown')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

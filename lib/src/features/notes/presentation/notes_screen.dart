import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/utils/widgets/staggered_list_animation.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/features/notes/presentation/note_editor_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with TickerProviderStateMixin {
  final GlobalKey _showcaseAdd = GlobalKey();
  final GlobalKey _showcaseList = GlobalKey();
  final GlobalKey _showcaseSearch = GlobalKey();
  Box? _notesBox;
  bool _isLoading = true;
  bool _isGridView = true;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _initializeBoxes();
  }

  Future<void> _initializeBoxes() async {
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
      try {
        if (Hive.isBoxOpen('notes_v2')) {
          _notesBox = Hive.box('notes_v2');
        } else {
          _notesBox = await Hive.openBox('notes_v2');
        }
      } catch (e) {
        debugPrint('Error opening notes box: $e');
      }
    } catch (e) {
      debugPrint('Error opening boxes in NotesScreen: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.notes);
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

  void _showNoteEditor({String? id, Map<String, dynamic>? initialData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NoteEditorScreen(noteId: id, initialData: initialData),
      ),
    );
  }

  void _showAddDialog() {
    _showNoteEditor();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header Premium
            _buildPremiumHeader(colors),
            const SizedBox(height: 8),
            Expanded(child: _buildNotesTab(colors)),
          ],
        ),
      ),
      floatingActionButton: _buildPremiumFAB(colors),
    );
  }

  /// Header premium com pesquisa integrada
  Widget _buildPremiumHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back button, title, actions
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Minhas Notas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    if (_notesBox != null)
                      Text(
                        '${_notesBox!.length} ${_notesBox!.length == 1 ? 'nota' : 'notas'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              _buildHeaderButton(
                icon: Icons.sort_rounded,
                onTap: _showSortOptions,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: _isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                onTap: () => setState(() => _isGridView = !_isGridView),
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar sempre visível
          GestureDetector(
            onTap: _showSearchSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Buscar em suas notas...',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⌘K',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
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

  /// FAB Premium com label expandido
  Widget _buildPremiumFAB(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddDialog,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, color: colors.onPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Nova Nota',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colors.onSurfaceVariant, size: 20),
      ),
    );
  }

  Widget _buildNotesTab(ColorScheme colors) {
    if (_notesBox == null) {
      return _buildErrorState('Erro ao carregar notas', colors);
    }
    return ValueListenableBuilder(
      valueListenable: _notesBox!.listenable(),
      builder: (context, box, _) {
        var notes = box.keys.toList();
        if (notes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sticky_note_2_outlined,
            title: 'Nenhuma nota ainda',
            subtitle: 'Toque no + para criar sua primeira nota',
            colors: colors,
          );
        }

        notes = _sortNotes(notes.cast<String>(), box);

        if (_isGridView) {
          return MasonryGridView.count(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final key = notes[index];
              final rawData = box.get(key);
              if (rawData == null || rawData is! Map) {
                return const SizedBox.shrink();
              }

              final data = Map<String, dynamic>.from(rawData);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteCard(key.toString(), data, index, colors),
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final key = notes[index];
              final rawData = box.get(key);
              if (rawData == null || rawData is! Map) {
                return const SizedBox.shrink();
              }

              final data = Map<String, dynamic>.from(rawData);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteListItem(key.toString(), data, index, colors),
              );
            },
          );
        }
      },
    );
  }

  List<String> _sortNotes(List<String> notes, Box box) {
    final notesList = notes
        .map((key) {
          final data = box.get(key);
          if (data == null || data is! Map) return null;
          return {'key': key, 'data': Map<String, dynamic>.from(data)};
        })
        .whereType<Map<String, dynamic>>()
        .toList();

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
          final dateA =
              DateTime.tryParse((a['data'] as Map)['createdAt'] ?? '') ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse((b['data'] as Map)['createdAt'] ?? '') ??
              DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date':
      default:
        notesList.sort((a, b) {
          final dateA =
              DateTime.tryParse((a['data'] as Map)['createdAt'] ?? '') ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse((b['data'] as Map)['createdAt'] ?? '') ??
              DateTime(2000);
          return dateB.compareTo(dateA);
        });
    }

    return notesList.map((n) => n['key'] as String).toList();
  }

  void _showSortOptions() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption(
                'date',
                'Data (mais recente)',
                Icons.calendar_today,
                colors,
              ),
              _buildSortOption(
                'title',
                'Título (A-Z)',
                Icons.sort_by_alpha,
                colors,
              ),
              _buildSortOption(
                'pinned',
                'Fixadas primeiro',
                Icons.push_pin,
                colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String value,
    String label,
    IconData icon,
    ColorScheme colors,
  ) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? colors.primary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colors.primary) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildNoteListItem(
    String id,
    Map<String, dynamic> data,
    int index,
    ColorScheme colors,
  ) {
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final dateStr = data['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final isPinned = data['isPinned'] as bool? ?? false;
    final imagePath = data['imagePath'] as String?;

    // Paleta de cores moderna e sofisticada (Pastel / Muted)
    final cardColors = [
      const Color(0xFF818CF8), // Indigo Soft
      const Color(0xFFA78BFA), // Violet Soft
      const Color(0xFFF472B6), // Pink Soft
      const Color(0xFF2DD4BF), // Teal Soft
      const Color(0xFFFBBF24), // Amber Soft
      const Color(0xFF60A5FA), // Blue Soft
    ];
    final accentColor = cardColors[index % cardColors.length];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Métricas
    final wordCount = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingTimeMinutes = (wordCount / 200).ceil();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : colors.outline.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteEditor(id: id, initialData: data),
          onLongPress: () => _deleteNote(id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador visual (Barra ou Ícone)
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPinned
                        ? accentColor
                        : accentColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(width: 16),

                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Título e Data
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (title != null && title.isNotEmpty)
                                  ? title
                                  : content
                                        .split('\n')
                                        .first, // Fallback para primeira linha do conteúdo
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (date != null)
                            Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Preview
                      Text(
                        content.replaceAll('\n', ' '), // Preview em uma linha
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Footer: Métricas e Pin
                      Row(
                        children: [
                          if (isPinned) ...[
                            Icon(Icons.push_pin, size: 12, color: accentColor),
                            const SizedBox(width: 8),
                          ],

                          // Tempo de leitura
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${readingTimeMinutes} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                if (imagePath != null && File(imagePath).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  // Chevron sutil
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(
    String id,
    Map<String, dynamic> data,
    int index,
    ColorScheme colors,
  ) {
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final dateStr = data['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final isPinned = data['isPinned'] as bool? ?? false;
    final imagePath = data['imagePath'] as String?;

    // Paleta de cores moderna e sofisticada (Pastel / Muted)
    final cardColors = [
      const Color(0xFF818CF8), // Indigo Soft
      const Color(0xFFA78BFA), // Violet Soft
      const Color(0xFFF472B6), // Pink Soft
      const Color(0xFF2DD4BF), // Teal Soft
      const Color(0xFFFBBF24), // Amber Soft
      const Color(0xFF60A5FA), // Blue Soft
    ];
    final accentColor = cardColors[index % cardColors.length];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Métricas
    final wordCount = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingTimeMinutes = (wordCount / 200).ceil();
    final hasEmoji = RegExp(
      r'[\u{1F300}-\u{1F9FF}]',
      unicode: true,
    ).hasMatch(content);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? colors
                  .surfaceContainer // Dark mode: surface um pouco mais clara
            : Colors.white, // Light mode: branco puro para limpeza
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : colors.outline.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _showNoteEditor(id: id, initialData: data),
          onLongPress: () => _deleteNote(id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem de Capa
              if (imagePath != null && File(imagePath).existsSync())
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Data e Pin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (date != null)
                          Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              letterSpacing: 0.5,
                            ),
                          ),
                        if (isPinned)
                          Icon(Icons.push_pin, size: 14, color: accentColor)
                        else if (hasEmoji)
                          Text('✨', style: TextStyle(fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Título Grande
                    if (title != null && title.isNotEmpty) ...[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Conteúdo (se não tiver título, ele assume o destaque)
                    if (title == null || title.isEmpty)
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (content.isNotEmpty)
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 16),

                    // Footer minimalista com "Tags" visuais
                    Row(
                      children: [
                        // Tag de tempo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 10,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${readingTimeMinutes}min',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor.withValues(alpha: 0.8),
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
            ],
          ),
        ),
      ),
    );
  }

  void _deleteNote(String id) {
    final colors = Theme.of(context).colorScheme;
    soundService.playModalOpen();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _notesBox!.delete(id);
              Navigator.pop(context);
              soundService.playDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showSearchSheet() {
    final colors = Theme.of(context).colorScheme;
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          List<MapEntry<String, Map>> filteredNotes = [];

          if (_notesBox != null && query.isNotEmpty) {
            final allNotes = _notesBox!.keys.map((key) {
              final data = Map<String, dynamic>.from(
                _notesBox!.get(key) as Map,
              );
              return MapEntry(key.toString(), data);
            }).toList();

            filteredNotes = allNotes.where((entry) {
              final title = (entry.value['title'] as String? ?? '')
                  .toLowerCase();
              final content = (entry.value['content'] as String? ?? '')
                  .toLowerCase();
              return title.contains(query) || content.contains(query);
            }).toList();
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) => setModalState(() {}),
                      style: TextStyle(color: colors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Buscar notas...',
                        hintStyle: TextStyle(color: colors.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: colors.primary),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colors.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
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
                  ),
                  // Results count
                  if (query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${filteredNotes.length} ${filteredNotes.length == 1 ? 'resultado' : 'resultados'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Results
                  Expanded(
                    child: query.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Digite para buscar',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma nota encontrada',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final entry = filteredNotes[index];
                              final data = Map<String, dynamic>.from(
                                entry.value,
                              );
                              final title = data['title'] as String?;
                              final content = data['content'] as String? ?? '';
                              final isPinned =
                                  data['isPinned'] as bool? ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPinned
                                          ? Icons.push_pin
                                          : Icons.sticky_note_2,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    title ?? content.split('\n').first,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: title != null && content.isNotEmpty
                                      ? Text(
                                          content,
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: colors.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showNoteEditor(
                                      id: entry.key,
                                      initialData: data,
                                    );
                                  },
                                ),
                              );
                            },
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: colors.tertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colors.error)),
        ],
      ),
    );
  }
}

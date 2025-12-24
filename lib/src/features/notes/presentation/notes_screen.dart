import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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
            // iOS-style header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildHeaderButton(
                    icon: Icons.sort,
                    onTap: _showSortOptions,
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(
                    icon: _isGridView ? Icons.view_list : Icons.grid_view,
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(
                    icon: Icons.search,
                    onTap: _showSearchSheet,
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildNotesTab(colors)),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddDialog,
            borderRadius: BorderRadius.circular(16),
            child: Icon(Icons.add, color: colors.onPrimary, size: 28),
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
              final key = notes[index] as String;
              final data = Map<String, dynamic>.from(box.get(key) as Map);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteCard(key, data, index, colors),
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final key = notes[index] as String;
              final data = Map<String, dynamic>.from(box.get(key) as Map);
              return StaggeredListAnimation(
                index: index,
                child: _buildNoteListItem(key, data, index, colors),
              );
            },
          );
        }
      },
    );
  }

  List<String> _sortNotes(List<String> notes, Box box) {
    final notesList = notes
        .map((key) => {'key': key, 'data': box.get(key) as Map})
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
    final accentColors = [colors.primary, colors.secondary, colors.tertiary];
    final color = accentColors[index % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned
              ? color.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isPinned ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteEditor(id: id, initialData: data),
          onLongPress: () => _deleteNote(id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2),
                    child: Icon(Icons.push_pin, size: 16, color: color),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2),
                    child: Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? content.split('\n').first,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (title != null && content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (date != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
    final accentColors = [colors.primary, colors.secondary, colors.tertiary];
    final color = accentColors[index % accentColors.length];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPinned
              ? color.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isPinned ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned || title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (isPinned)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.push_pin, size: 12, color: color),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: title != null
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      height: 1.5,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'Há ${diff.inMinutes} min';
      return 'Há ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

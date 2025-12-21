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
          color: colors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddDialog,
            borderRadius: BorderRadius.circular(16),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: isPinned
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteEditor(id: id, initialData: data),
          onLongPress: () => _deleteNote(id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 50,
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
                          if (isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: color,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title ?? content.split('\n').first,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
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
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (date != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
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
    final accentColors = [colors.primary, colors.secondary, colors.tertiary];
    final color = accentColors[index % accentColors.length];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: isPinned
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteEditor(id: id, initialData: data),
          onLongPress: () => _deleteNote(id),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPinned || title != null)
                      Row(
                        children: [
                          if (isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: color,
                              ),
                            ),
                          if (title != null)
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    if (title != null) const SizedBox(height: 6),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: title != null
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Busca em desenvolvimento')));
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

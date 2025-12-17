import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/notes/presentation/note_editor_screen.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

class QuickNotesWidget extends StatefulWidget {
  const QuickNotesWidget({super.key});

  @override
  State<QuickNotesWidget> createState() => _QuickNotesWidgetState();
}

class _QuickNotesWidgetState extends State<QuickNotesWidget> with SingleTickerProviderStateMixin {
  Box? _notesBox;
  bool _isLoading = true;
  final _quickNoteController = TextEditingController();
  int _previousTextLength = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _initBox();
    _quickNoteController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentLength = _quickNoteController.text.length;
    
    if (currentLength > _previousTextLength) {
      // Texto adicionado - som de digitação
      soundService.playSndType();
    } else if (currentLength < _previousTextLength) {
      // Texto deletado - som de delete
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }
    
    _previousTextLength = currentLength;
  }

  Future<void> _initBox() async {
    try {
      if (Hive.isBoxOpen('notes_v2')) {
        _notesBox = Hive.box('notes_v2');
      } else {
        _notesBox = await Hive.openBox('notes_v2');
      }
    } catch (e) {
      debugPrint('Error opening notes box: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quickNoteController.removeListener(_onTextChanged);
    _quickNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickNote() async {
    final text = _quickNoteController.text.trim();
    if (text.isEmpty || _notesBox == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _notesBox!.put(id, {
      'id': id,
      'content': text,
      'title': text.length > 30 ? '${text.substring(0, 30)}...' : text,
      'createdAt': DateTime.now().toIso8601String(),
      'category': 'quick',
      'isPinned': false,
    });

    _quickNoteController.clear();
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      FeedbackService.showSuccess(context, AppLocalizations.of(context)!.notaSalva, icon: Icons.note_add_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return _buildContainer(colors, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return _buildContainer(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header melhorado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFA726).withValues(alpha: 0.2),
                      const Color(0xFFFF7043).withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFFFA726), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notasRapidas, 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600, 
                        color: colors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Capture suas ideias',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.verTodas, 
                        style: TextStyle(
                          fontSize: 12, 
                          color: colors.primary, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 10, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campo de nota rápida melhorado
          Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
              if (hasFocus) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isFocused 
                    ? colors.surfaceContainerHighest
                    : colors.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused 
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.outline.withValues(alpha: 0.1),
                  width: _isFocused ? 1.5 : 1,
                ),
                boxShadow: _isFocused ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: TextField(
                controller: _quickNoteController,
                style: TextStyle(fontSize: 14, color: colors.onSurface),
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Escreva uma nota rápida...',
                  hintStyle: TextStyle(
                    fontSize: 13, 
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6),
                    child: GestureDetector(
                      onTap: _saveQuickNote,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
                onSubmitted: (_) => _saveQuickNote(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de notas recentes melhorada
          if (_notesBox != null)
            ValueListenableBuilder(
              valueListenable: _notesBox!.listenable(),
              builder: (context, box, _) {
                final notes = box.values.toList();
                notes.sort((a, b) {
                  final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
                  final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
                  return dateB.compareTo(dateA);
                });

                final recentNotes = notes.take(3).toList();

                if (recentNotes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.05),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded, 
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5), 
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.nenhumaNotaAinda, 
                          style: TextStyle(
                            fontSize: 13, 
                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: recentNotes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final note = entry.value;
                    final createdAt = DateTime.tryParse(note['createdAt'] ?? '');
                    final title = note['title'] ?? 'Sem título';
                    final content = note['content'] ?? '';
                    final isQuick = note['category'] == 'quick';

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 200 + (index * 100)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note['id'])),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isQuick 
                                        ? [const Color(0xFFFFA726), const Color(0xFFFF7043)]
                                        : [colors.primary, colors.secondary],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w600, 
                                        color: colors.onSurface,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (content.isNotEmpty && content != title) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        content,
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (createdAt != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatDate(createdAt),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContainer(ColorScheme colors, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(date);
  }
}

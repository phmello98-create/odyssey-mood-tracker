import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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

class _QuickNotesWidgetState extends State<QuickNotesWidget> {
  Box? _notesBox;
  bool _isLoading = true;
  final _quickNoteController = TextEditingController();
  int _previousTextLength = 0;

  @override
  void initState() {
    super.initState();
    _initBox();
    _quickNoteController.addListener(_onTextChanged);
  }

  /// Abre o campo de texto expandido com animação de zoom
  void _openExpandedTextField() {
    HapticFeedback.mediumImpact();
    soundService.playModalOpen();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ExpandedNoteEditor(
          initialText: _quickNoteController.text,
          onSave: (text) {
            _quickNoteController.text = text;
            _saveQuickNote();
            Navigator.pop(context);
          },
          onCancel: (text) {
            // Preserva o texto digitado
            _quickNoteController.text = text;
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _onTextChanged() {
    final currentLength = _quickNoteController.text.length;

    if (currentLength > _previousTextLength) {
      soundService.playSndType();
    } else if (currentLength < _previousTextLength) {
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
      FeedbackService.showSuccess(
        context,
        'Nota salva!',
        icon: Icons.note_add_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const notesColor = Color(0xFFFFA726);

    if (_isLoading) {
      return _buildContainer(
        colors,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _buildContainer(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      notesColor.withOpacity(0.2),
                      const Color(0xFFFF7043).withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sticky_note_2_rounded,
                  color: notesColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas Rápidas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Capture suas ideias',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Notes count badge + View all
              if (_notesBox != null)
                ValueListenableBuilder(
                  valueListenable: _notesBox!.listenable(),
                  builder: (context, box, _) {
                    final count = box.length;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: notesColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: notesColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: notesColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick note input - Tap to expand
          GestureDetector(
            onTap: _openExpandedTextField,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.transparent, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _quickNoteController.text.isEmpty
                          ? 'Toque para escrever...'
                          : _quickNoteController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _quickNoteController.text.isEmpty
                            ? colors.onSurfaceVariant.withOpacity(0.5)
                            : colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [notesColor, Color(0xFFFF7043)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: notesColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Recent notes list
          if (_notesBox != null)
            ValueListenableBuilder(
              valueListenable: _notesBox!.listenable(),
              builder: (context, box, _) {
                final notes = box.values.toList();
                notes.sort((a, b) {
                  final dateA =
                      DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
                  final dateB =
                      DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
                  return dateB.compareTo(dateA);
                });

                final recentNotes = notes.take(3).toList();

                if (recentNotes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: colors.onSurfaceVariant.withOpacity(0.4),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Nenhuma nota ainda',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: recentNotes.asMap().entries.map((entry) {
                    final note = entry.value;
                    final createdAt = DateTime.tryParse(
                      note['createdAt'] ?? '',
                    );
                    final title = note['title'] ?? 'Sem título';
                    final content = note['content'] ?? '';
                    final isQuick = note['category'] == 'quick';
                    final isPinned = note['isPinned'] == true;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NoteEditorScreen(noteId: note['id']),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.onSurface.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Color indicator
                            Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isQuick ? notesColor : colors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isPinned)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: Icon(
                                            Icons.push_pin_rounded,
                                            size: 12,
                                            color: notesColor,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (content.isNotEmpty && content != title)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        content,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Time
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.onSurfaceVariant.withOpacity(
                                    0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ],
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
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

/// Widget de edição expandida de nota com animações premium
class _ExpandedNoteEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onSave;
  final Function(String) onCancel;

  const _ExpandedNoteEditor({
    required this.initialText,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ExpandedNoteEditor> createState() => _ExpandedNoteEditorState();
}

class _ExpandedNoteEditorState extends State<_ExpandedNoteEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  static const notesColor = Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();

    // Auto-focus após a animação
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background com blur muito sutil - quase visível o app
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                soundService.playModalClose();
                widget.onCancel(_controller.text);
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(color: Colors.black.withOpacity(0.15)),
              ),
            ),
          ),

          // Card compacto centralizado
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 60,
                bottom: bottomInset + 60,
              ),
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: screenSize.width - 48,
                      constraints: BoxConstraints(
                        maxHeight: screenSize.height * 0.4,
                        maxWidth: 400,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.onSurface.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          // Campo de texto compacto
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                maxLines: null,
                                minLines: 4,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colors.onSurface,
                                  height: 1.4,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Escreva sua nota...',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: colors.onSurfaceVariant.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),

                          // Footer compacto
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Row(
                              children: [
                                // Minimizar
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    soundService.playModalClose();
                                    widget.onCancel(_controller.text);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.onSurface.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: colors.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Salvar
                                GestureDetector(
                                  onTap: () {
                                    if (_controller.text.trim().isEmpty) {
                                      HapticFeedback.heavyImpact();
                                      soundService.playError();
                                      return;
                                    }
                                    HapticFeedback.mediumImpact();
                                    soundService.playSuccess();
                                    widget.onSave(_controller.text);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [notesColor, Color(0xFFFF7043)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Salvar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

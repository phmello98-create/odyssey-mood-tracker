import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/services/speech_service.dart';
import 'package:odyssey/src/utils/services/app_lifecycle_service.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/notes/data/synced_notes_repository.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/features/onboarding/presentation/onboarding_providers.dart';
import 'package:odyssey/src/utils/services/note_intelligence_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final Map<String, dynamic>? initialData;

  const NoteEditorScreen({super.key, this.noteId, this.initialData});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with WidgetsBindingObserver {
  late EditorState _editorState;
  late TextEditingController _titleController;
  SyncedNotesRepository? _notesRepo;
  bool _isLoading = true;
  bool _isPinned = false;
  bool _hasChanges = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveTimer;
  DateTime? _lastAutoSave;
  int _previousTitleLength = 0;
  int _previousContentLength = 0;
  String? _currentNoteId; // ID da nota sendo editada/criada

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController(
      text: widget.initialData?['title'] ?? '',
    );
    _previousTitleLength = _titleController.text.length;
    _isPinned = widget.initialData?['isPinned'] ?? false;
    _currentNoteId = widget
        .noteId; // Inicializa com o noteId passado (pode ser null para nova nota)
    _titleController.addListener(_onTitleChanged);
    _scrollController.addListener(_onScroll);
    _initEditor();

    // Auto-save a cada 30 segundos
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasChanges) {
        _autoSaveNote();
      }
    });
  }

  void _onScroll() {
    // Fecha o teclado quando o usuário rola a tela
    FocusScope.of(context).unfocus();
  }

  void _onTitleChanged() {
    final currentLength = _titleController.text.length;

    if (currentLength > _previousTitleLength) {
      soundService.playSndType();
    } else if (currentLength < _previousTitleLength) {
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }

    _previousTitleLength = currentLength;
  }

  void _onEditorContentChanged() {
    final plainText = _editorState.document.root.children
        .map((node) => node.delta?.toPlainText() ?? '')
        .join('\n');
    final currentLength = plainText.length;

    if (currentLength > _previousContentLength) {
      soundService.playSndType();
    } else if (currentLength < _previousContentLength) {
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }

    _previousContentLength = currentLength;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App indo para background - auto-save
      _autoSaveNote();
    }
  }

  Future<void> _initEditor() async {
    _notesRepo = ref.read(syncedNotesRepositoryProvider);
    await _notesRepo!.initialize();

    // Carrega dados da nota pelo ID se initialData não foi fornecido
    Map<String, dynamic>? noteData = widget.initialData;
    if (noteData == null && widget.noteId != null) {
      final savedNote = _notesRepo!.getNote(widget.noteId!);
      if (savedNote != null) {
        noteData = savedNote;
        // Atualiza o controlador de título com os dados carregados
        _titleController.text = noteData['title'] ?? '';
        _isPinned = noteData['isPinned'] ?? false;
      }
    }

    // Parse existing content or create blank
    if (noteData != null && noteData['jsonContent'] != null) {
      try {
        final jsonContent = jsonDecode(noteData['jsonContent']);
        _editorState = EditorState(document: Document.fromJson(jsonContent));
      } catch (e) {
        // Fallback: tentar criar documento com texto simples
        final plainContent = noteData['content'] ?? '';
        if (plainContent.isNotEmpty) {
          _editorState = EditorState(
            document: Document.blank()
              ..insert([0], [paragraphNode(text: plainContent)]),
          );
        } else {
          _editorState = EditorState.blank(withInitialText: true);
        }
      }
    } else if (noteData != null && noteData['content'] != null) {
      // Se só tem conteúdo de texto simples (notas rápidas antigas)
      final plainContent = noteData['content'] as String;
      if (plainContent.isNotEmpty) {
        _editorState = EditorState(
          document: Document.blank()
            ..insert([0], [paragraphNode(text: plainContent)]),
        );
      } else {
        _editorState = EditorState.blank(withInitialText: true);
      }
    } else {
      _editorState = EditorState.blank(withInitialText: true);
    }

    // Listen for changes
    _editorState.transactionStream.listen((_) {
      _onEditorContentChanged();
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });

    // Inicializar o comprimento inicial do conteúdo
    final initialPlainText = _editorState.document.root.children
        .map((node) => node.delta?.toPlainText() ?? '')
        .join('\n');
    _previousContentLength = initialPlainText.length;

    // Listen for title changes
    _titleController.addListener(() {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });

    setState(() => _isLoading = false);
  }

  /// Auto-save silencioso da nota
  Future<void> _autoSaveNote() async {
    final now = DateTime.now();
    // Evitar salvar múltiplas vezes em menos de 10 segundos
    if (_lastAutoSave != null &&
        now.difference(_lastAutoSave!) < const Duration(seconds: 10)) {
      return;
    }
    _lastAutoSave = now;

    try {
      final title = _titleController.text.trim();
      final document = _editorState.document;

      final plainText = document.root.children
          .map((node) => node.delta?.toPlainText() ?? '')
          .join('\n')
          .trim();

      if (plainText.isEmpty && title.isEmpty) {
        return; // Não salvar nota vazia
      }

      // Se não tem ID ainda, cria um novo e salva para reutilizar
      _currentNoteId ??= DateTime.now().millisecondsSinceEpoch.toString();

      final jsonContent = jsonEncode(document.toJson());

      final noteData = {
        'id': _currentNoteId!,
        'title': title.isEmpty ? null : title,
        'content': plainText,
        'jsonContent': jsonContent,
        'isPinned': _isPinned,
        'createdAt':
            widget.initialData?['createdAt'] ??
            DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Sempre usa updateNote se já tem ID, ou addNote se é novo
      if (widget.noteId != null) {
        await _notesRepo!.updateNote(_currentNoteId!, noteData);
      } else {
        await _notesRepo!.addNote(noteData);
      }

      debugPrint('[NoteEditor] Note auto-saved: $_currentNoteId');
      setState(() => _hasChanges = false);

      // Limpar da recuperação de emergência
      ref.read(appLifecycleServiceProvider).clearUnsavedNote();
    } catch (e) {
      debugPrint('[NoteEditor] Auto-save error: $e');
    }
  }

  @override
  void dispose() {
    // Salvar antes de sair
    if (_hasChanges) {
      _autoSaveNote();
    }
    _autoSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final document = _editorState.document;

    // Get plain text for preview
    final plainText = document.root.children
        .map((node) => node.delta?.toPlainText() ?? '')
        .join('\n')
        .trim();

    if (plainText.isEmpty && title.isEmpty) {
      FeedbackService.showError(context, 'A nota está vazia');
      return;
    }

    // Se não tem ID ainda, cria um novo e salva para reutilizar
    _currentNoteId ??= DateTime.now().millisecondsSinceEpoch.toString();

    final jsonContent = jsonEncode(document.toJson());

    final noteData = {
      'id': _currentNoteId!,
      'title': title.isEmpty ? null : title,
      'content': plainText,
      'jsonContent': jsonContent,
      'isPinned': _isPinned,
      'createdAt':
          widget.initialData?['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (widget.noteId != null) {
      _notesRepo!.updateNote(_currentNoteId!, noteData);
    } else {
      _notesRepo!.addNote(noteData);
      // Track first note creation for onboarding
      ref
          .read(interactiveOnboardingProvider.notifier)
          .completeFirstStep('create_note');
    }

    // Análise de sentimento em background (não bloqueia o save)
    _analyzeNoteInBackground(_currentNoteId!, plainText, title);

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    FeedbackService.showSuccess(
      context,
      widget.noteId != null ? 'Nota atualizada!' : 'Nota salva!',
      icon: Icons.check_circle,
    );
  }

  /// Analisa a nota em background após salvar
  Future<void> _analyzeNoteInBackground(
    String noteId,
    String content,
    String title,
  ) async {
    try {
      final intelligenceService = ref.read(noteIntelligenceServiceProvider);
      await intelligenceService.initialize();
      final result = await intelligenceService.analyzeNote(
        noteId,
        content,
        title: title.isNotEmpty ? title : null,
      );
      if (result != null) {
        debugPrint(
          '[NoteEditor] Sentiment analysis: ${result.sentiment?.label} (${result.sentiment?.score})',
        );
      }
    } catch (e) {
      debugPrint('[NoteEditor] Background analysis error: $e');
    }
  }

  void _deleteNote() {
    if (widget.noteId == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.deleteNote),
        content: Text(AppLocalizations.of(context)!.deleteNoteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _notesRepo!.deleteNote(widget.noteId!);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close editor
              HapticFeedback.heavyImpact();
              FeedbackService.showSuccess(
                context,
                'Nota excluída',
                icon: Icons.delete,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: UltravioletColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.noteId != null
              ? AppLocalizations.of(context)!.editNote
              : AppLocalizations.of(context)!.newNote,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isPinned = !_isPinned),
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          if (widget.noteId != null)
            IconButton(
              onPressed: _deleteNote,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          TextButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, size: 20),
            label: Text(AppLocalizations.of(context)!.save),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Title field
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escolha um título',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (!_hasChanges) setState(() => _hasChanges = true);
                    },
                  ),
                ),

                // Editor
                Expanded(
                  child: Container(
                    color: colors.surface,
                    child: AppFlowyEditor(
                      editorState: _editorState,
                      editorScrollController: EditorScrollController(
                        editorState: _editorState,
                        scrollController: _scrollController,
                      ),
                      editorStyle: _buildEditorStyle(),
                      blockComponentBuilders: _buildBlockComponentBuilders(),
                      characterShortcutEvents: standardCharacterShortcutEvents,
                      commandShortcutEvents: standardCommandShortcutEvents,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Toolbar at bottom
          _buildCustomToolbar(),
        ],
      ),
    );
  }

  void _showColorPicker(bool isBackground, Selection? savedSelection) {
    final colors = [
      {'name': 'Padrão', 'value': null},
      {'name': 'Cinza', 'value': '0xff9e9e9e'},
      {'name': 'Vermelho', 'value': '0xfff44336'},
      {'name': 'Laranja', 'value': '0xffff9800'},
      {'name': 'Amarelo', 'value': '0xffffeb3b'},
      {'name': 'Verde', 'value': '0xff4caf50'},
      {'name': 'Azul', 'value': '0xff2196f3'},
      {'name': 'Roxo', 'value': '0xff9c27b0'},
      {'name': 'Rosa', 'value': '0xffe91e63'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBackground ? 'Cor de destaque' : 'Cor do texto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.start,
                children: colors.map((color) {
                  final colorValue = color['value'];
                  final colorInt = colorValue != null
                      ? int.parse(colorValue)
                      : null;
                  final displayColor = colorInt != null
                      ? Color(colorInt)
                      : Theme.of(context).colorScheme.onSurface;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (isBackground) {
                        _applyHighlightColor(
                          colorValue != null
                              ? '0x4d${colorValue.substring(4)}'
                              : 'clear',
                          savedSelection,
                        );
                      } else {
                        _applyTextColor(colorValue ?? 'clear', savedSelection);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isBackground
                                ? (colorInt != null
                                      ? Color(colorInt).withValues(alpha: 0.3)
                                      : Colors.transparent)
                                : displayColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: colorValue == null
                              ? Icon(
                                  Icons.format_clear,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          color['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildToolbarButton(
                  Icons.format_bold,
                  'Negrito',
                  () => _toggleFormat(AppFlowyRichTextKeys.bold),
                ),
                _buildToolbarButton(
                  Icons.format_italic,
                  'Itálico',
                  () => _toggleFormat(AppFlowyRichTextKeys.italic),
                ),
                _buildToolbarButton(
                  Icons.format_underlined,
                  'Sublinhado',
                  () => _toggleFormat(AppFlowyRichTextKeys.underline),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  width: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),

                _buildToolbarButton(
                  Icons.format_color_text,
                  'Cor do texto',
                  () => _showColorPicker(false, _editorState.selection),
                ),
                _buildToolbarButton(
                  Icons.format_color_fill,
                  'Cor de fundo',
                  () => _showColorPicker(true, _editorState.selection),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  width: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),

                _buildToolbarButton(
                  Icons.format_list_bulleted,
                  'Lista',
                  () => _insertBlock('bulleted_list'),
                ),
                _buildToolbarButton(
                  Icons.check_box_outlined,
                  'Checklist',
                  () => _insertBlock('todo_list'),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  width: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),

                _buildToolbarButton(
                  Icons.format_quote,
                  'Citação',
                  () => _insertBlock('quote'),
                ),
                _buildToolbarButton(
                  Icons.code,
                  'Código',
                  () => _toggleFormat(AppFlowyRichTextKeys.code),
                ),
              ],
            ),
          ),
          // Voice input - elegant inline
          _buildVoiceButton(),
          // Close keyboard button
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.keyboard_hide_outlined),
              onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              tooltip: 'Fechar teclado',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return InlineMicButton(
      onResult: (text) {
        // Insert text at current cursor position
        final selection = _editorState.selection;
        if (selection == null) return;

        // Get the node at the cursor position
        final node = _editorState.getNodeAtPath(selection.start.path);
        if (node == null) return;

        final transaction = _editorState.transaction;
        transaction.insertText(node, selection.start.offset, text);
        _editorState.apply(transaction);
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        splashRadius: 18,
      ),
    );
  }

  void _toggleFormat(String key) {
    final selection = _editorState.selection;
    if (selection == null) return;
    _editorState.toggleAttribute(key);
  }

  void _applyTextColor(String? colorHex, Selection? savedSelection) {
    final selection = savedSelection ?? _editorState.selection;
    if (selection == null) return;
    _editorState.formatDelta(selection, {
      AppFlowyRichTextKeys.textColor: colorHex == 'clear' ? null : colorHex,
    });
  }

  void _applyHighlightColor(String? colorHex, Selection? savedSelection) {
    final selection = savedSelection ?? _editorState.selection;
    if (selection == null) return;
    _editorState.formatDelta(selection, {
      AppFlowyRichTextKeys.backgroundColor: colorHex == 'clear'
          ? null
          : colorHex,
    });
  }

  void _insertBlock(String type) {
    final selection = _editorState.selection;
    if (selection == null) return;

    final node = _editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;

    final transaction = _editorState.transaction;

    // Criar novo nó do tipo correto
    Node newNode;
    switch (type) {
      case 'bulleted_list':
        newNode = bulletedListNode(delta: node.delta);
        break;
      case 'todo_list':
        newNode = todoListNode(checked: false, delta: node.delta);
        break;
      case 'quote':
        newNode = quoteNode(delta: node.delta);
        break;
      case 'numbered_list':
        newNode = numberedListNode(delta: node.delta);
        break;
      case 'heading':
        newNode = headingNode(level: 2, delta: node.delta);
        break;
      default:
        newNode = paragraphNode(delta: node.delta);
    }

    // Substituir o nó atual pelo novo
    transaction.insertNode(selection.start.path, newNode);
    transaction.deleteNode(node);
    _editorState.apply(transaction);
  }

  EditorStyle _buildEditorStyle() {
    final colors = Theme.of(context).colorScheme;
    return EditorStyle.mobile(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      cursorColor: colors.primary,
      selectionColor: const Color(0x4da78bfa), // primary with 30% opacity
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(fontSize: 16, color: colors.onSurface, height: 1.6),
        bold: const TextStyle(fontWeight: FontWeight.w700),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: colors.primary,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          backgroundColor: colors.surfaceContainerHighest,
          color: colors.tertiary,
        ),
      ),
    );
  }

  Map<String, BlockComponentBuilder> _buildBlockComponentBuilders() {
    final builders = standardBlockComponentBuilderMap;

    // Customize heading style
    builders['heading'] = HeadingBlockComponentBuilder(
      textStyleBuilder: (level) => TextStyle(
        fontSize: level == 1
            ? 28
            : level == 2
            ? 24
            : 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.4,
      ),
    );

    // Customize quote style
    builders['quote'] = QuoteBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: (node) => const EdgeInsets.symmetric(vertical: 8),
      ),
    );

    return builders;
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.unsavedChanges),
        content: Text(AppLocalizations.of(context)!.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close editor without saving
            },
            child: Text(
              AppLocalizations.of(context)!.discard,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _saveNote();
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}

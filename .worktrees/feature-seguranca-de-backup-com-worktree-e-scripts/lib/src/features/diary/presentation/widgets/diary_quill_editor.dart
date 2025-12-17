import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Editor rico baseado em Quill para entradas do diário
/// Inspirado no StoryPad com toolbar personalizável
class DiaryQuillEditor extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onContentChanged;
  final bool readOnly;
  final FocusNode? focusNode;
  final ScrollController? scrollController;

  const DiaryQuillEditor({
    super.key,
    required this.initialContent,
    required this.onContentChanged,
    this.readOnly = false,
    this.focusNode,
    this.scrollController,
  });

  @override
  State<DiaryQuillEditor> createState() => _DiaryQuillEditorState();
}

class _DiaryQuillEditorState extends State<DiaryQuillEditor> {
  late QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      // Tenta carregar documento existente
      final doc = widget.initialContent.isEmpty
          ? Document()
          : Document.fromJson(jsonDecode(widget.initialContent) as List);
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      // Escuta mudanças
      _controller.addListener(_onContentChanged);
    } catch (e) {
      // Se falhar ao parsear, cria documento vazio
      _controller = QuillController.basic();
      _controller.addListener(_onContentChanged);
    }
  }

  void _onContentChanged() {
    if (!widget.readOnly) {
      final delta = jsonEncode(_controller.document.toDelta().toJson());
      widget.onContentChanged(delta);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar de formatação
        if (!widget.readOnly) _buildToolbar(theme),

        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: widget.focusNode ?? _editorFocusNode,
              config: QuillEditorConfig(
                padding: const EdgeInsets.all(16),
                placeholder: 'Escreva sobre o seu dia...',
                expands: false,
                scrollable: true,
                autoFocus: !widget.readOnly,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QuillSimpleToolbar(
        controller: _controller,
        config: const QuillSimpleToolbarConfig(
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showColorButton: true,
          showBackgroundColorButton: false,
          showClearFormat: true,
          showListBullets: true,
          showListNumbers: true,
          showListCheck: true,
          showQuote: true,
          showIndent: true,
          showLink: false,
          showUndo: true,
          showRedo: true,
          showFontFamily: false,
          showFontSize: false,
          showInlineCode: true,
          showCodeBlock: false,
          showDividers: true,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          multiRowsDisplay: false,
          showAlignmentButtons: true,
        ),
      ),
    );
  }
}

/// Converte conteúdo Quill Delta para texto plano (para busca)
String quillDeltaToPlainText(String deltaJson) {
  try {
    final doc = Document.fromJson(jsonDecode(deltaJson) as List);
    return doc.toPlainText();
  } catch (e) {
    return '';
  }
}

/// Cria um documento Quill vazio
String createEmptyQuillDocument() {
  final doc = Document();
  return jsonEncode(doc.toDelta().toJson());
}

/// Cria um documento Quill a partir de texto plano
String createQuillDocumentFromText(String text) {
  final doc = Document()..insert(0, text);
  return jsonEncode(doc.toDelta().toJson());
}

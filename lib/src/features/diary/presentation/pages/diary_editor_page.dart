import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../localization/app_localizations.dart';
import '../../data/models/diary_entry.dart';
import '../controllers/diary_providers.dart';
import '../widgets/feeling_selector_widget.dart';

class DiaryEditorPage extends ConsumerStatefulWidget {
  final String? entryId;
  final DateTime? initialDate;
  final String? initialPrompt;

  const DiaryEditorPage({
    super.key,
    this.entryId,
    this.initialDate,
    this.initialPrompt,
  });

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late TextEditingController _tagController;
  late FocusNode _editorFocusNode;
  late ScrollController _scrollController;

  DiaryEntry? _existingEntry;
  String? _selectedFeeling;
  List<String> _tags = [];
  late DateTime _entryDate;
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _showPrompt = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagController = TextEditingController();
    _editorFocusNode = FocusNode();
    _scrollController = ScrollController();
    _quillController = QuillController.basic();
    _entryDate = widget.initialDate ?? DateTime.now();

    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);

    _loadEntry();
  }

  @override
  void dispose() {
    _titleController.removeListener(_onContentChanged);
    _quillController.removeListener(_onContentChanged);
    _titleController.dispose();
    _tagController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadEntry() async {
    if (widget.entryId != null) {
      final repository = ref.read(diaryRepositoryProvider);
      final entry = await repository.getEntry(widget.entryId!);

      if (entry != null && mounted) {
        setState(() {
          _existingEntry = entry;
          _titleController.text = entry.title ?? '';
          _selectedFeeling = entry.feeling;
          _tags = List.from(entry.tags);
          _entryDate = entry.entryDate;

          // Parse Quill Delta JSON
          try {
            if (entry.content.isNotEmpty && entry.content != '[]') {
              final deltaJson = jsonDecode(entry.content) as List;
              _quillController = QuillController(
                document: Document.fromJson(deltaJson),
                selection: const TextSelection.collapsed(offset: 0),
              );
              _quillController.addListener(_onContentChanged);
            }
          } catch (e) {
            debugPrint('Error parsing Quill delta: $e');
          }
        });
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isEditing = widget.entryId != null;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Entrada' : 'Nova Entrada'),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
                tooltip: 'Excluir',
              ),
            TextButton.icon(
              onPressed: _isSaving ? null : _saveEntry,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prompt de inspiração (se houver)
                    if (widget.initialPrompt != null && _showPrompt)
                      _buildPromptCard(theme),

                    // Data da entrada
                    _buildDateSelector(theme),
                    const SizedBox(height: 16),

                    // Seletor de sentimento
                    _buildFeelingSection(theme),
                    const SizedBox(height: 16),

                    // Campo de título
                    _buildTitleField(theme),
                    const SizedBox(height: 16),

                    // Editor de texto rico
                    _buildEditor(theme),
                    const SizedBox(height: 16),

                    // Tags
                    _buildTagsSection(theme),
                    const SizedBox(height: 100), // Espaço para toolbar
                  ],
                ),
              ),
            ),

            // Toolbar do Quill
            _buildToolbar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final dateFormat = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR');

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(_entryDate),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.diaryHowAreYouFeeling,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        FeelingSelectorWidget(
          selectedFeeling: _selectedFeeling,
          onFeelingSelected: (feeling) {
            setState(() {
              _selectedFeeling = feeling;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextField(
      controller: _titleController,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.diaryEditorTitle,
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QuillEditor.basic(
          controller: _quillController,
          focusNode: _editorFocusNode,
          config: QuillEditorConfig(
            padding: const EdgeInsets.all(16),
            placeholder: AppLocalizations.of(context)!.diaryEditorContentPlaceholder,
            expands: false,
            scrollable: true,
            autoFocus: false,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: QuillSimpleToolbar(
          controller: _quillController,
          config: const QuillSimpleToolbarConfig(
            toolbarIconAlignment: WrapAlignment.start,
            multiRowsDisplay: false,
            showDividers: false,
            showFontFamily: false,
            showFontSize: false,
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showStrikeThrough: false,
            showInlineCode: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showClearFormat: false,
            showAlignmentButtons: false,
            showLeftAlignment: false,
            showCenterAlignment: false,
            showRightAlignment: false,
            showJustifyAlignment: false,
            showHeaderStyle: true,
            showListNumbers: true,
            showListBullets: true,
            showListCheck: true,
            showCodeBlock: false,
            showQuote: true,
            showIndent: false,
            showLink: false,
            showUndo: true,
            showRedo: true,
            showDirection: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showClipboardCut: false,
            showClipboardCopy: false,
            showClipboardPaste: false,
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeTag(tag),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar tag'),
              onPressed: _showAddTagDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Inspiração',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onTertiaryContainer.withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: () => setState(() => _showPrompt = false),
                tooltip: 'Fechar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${widget.initialPrompt}"',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: colorScheme.onTertiaryContainer,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null && mounted) {
      // Mantém a hora atual se for hoje, senão usa meio-dia
      final now = DateTime.now();
      final newDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        picked.year == now.year &&
                picked.month == now.month &&
                picked.day == now.day
            ? now.hour
            : 12,
        picked.year == now.year &&
                picked.month == now.month &&
                picked.day == now.day
            ? now.minute
            : 0,
      );

      setState(() {
        _entryDate = newDate;
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _showAddTagDialog() async {
    _tagController.clear();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Tag'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nome da tag',
            prefixIcon: Icon(Icons.tag),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _tagController.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      final tag = result.trim();
      if (!_tags.contains(tag)) {
        setState(() {
          _tags.add(tag);
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(diaryRepositoryProvider);

      // Converte o documento Quill para JSON
      final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());

      // Extrai texto plano para busca
      final plainText = _quillController.document.toPlainText().trim();

      final now = DateTime.now();

      final entry = _existingEntry?.copyWith(
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            content: deltaJson,
            feeling: _selectedFeeling,
            tags: _tags,
            entryDate: _entryDate,
            searchableText: plainText.isEmpty ? null : plainText,
            updatedAt: now,
          ) ??
          DiaryEntry(
            id: now.millisecondsSinceEpoch.toString(),
            createdAt: now,
            updatedAt: now,
            entryDate: _entryDate,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            content: deltaJson,
            feeling: _selectedFeeling,
            tags: _tags,
            searchableText: plainText.isEmpty ? null : plainText,
          );

      await repository.saveEntry(entry);

      // Invalida os providers para atualizar a lista
      ref.invalidate(diaryEntriesProvider);
      ref.invalidate(starredEntriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada salva com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Entrada'),
        content: const Text(
          'Tem certeza que deseja excluir esta entrada? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.entryId != null && mounted) {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.deleteEntry(widget.entryId!);

      ref.invalidate(diaryEntriesProvider);
      ref.invalidate(starredEntriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.diaryEntryDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.diaryDiscardChanges),
        content: Text(
          AppLocalizations.of(context)!.diaryDiscardChangesMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.continueEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.discard),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

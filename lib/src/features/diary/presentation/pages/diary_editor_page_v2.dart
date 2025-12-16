// lib/src/features/diary/presentation/pages/diary_editor_page_v2.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../controllers/diary_editor_controller.dart';
import '../controllers/diary_state.dart';
import '../widgets/feeling_selector_widget.dart';
import '../../../../utils/services/sound_service.dart';
import '../../../../localization/app_localizations.dart';

/// Página de edição do diário com auto-save e templates
class DiaryEditorPageV2 extends ConsumerStatefulWidget {
  final String? entryId;
  final DateTime? initialDate;

  const DiaryEditorPageV2({
    super.key,
    this.entryId,
    this.initialDate,
  });

  @override
  ConsumerState<DiaryEditorPageV2> createState() => _DiaryEditorPageV2State();
}

class _DiaryEditorPageV2State extends ConsumerState<DiaryEditorPageV2> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late TextEditingController _tagController;
  late FocusNode _editorFocusNode;
  late ScrollController _scrollController;

  bool _isInitialized = false;
  bool _showToolbar = true;
  int _previousTitleLength = 0;
  int _previousContentLength = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagController = TextEditingController();
    _editorFocusNode = FocusNode();
    _scrollController = ScrollController();
    _quillController = QuillController.basic();

    _editorFocusNode.addListener(_onFocusChange);
    _scrollController.addListener(_onScroll);
    _titleController.addListener(_onTitleChanged);
    _quillController.addListener(_onQuillContentChanged);
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

  void _onQuillContentChanged() {
    final currentLength = _quillController.document.toPlainText().length;
    
    if (currentLength > _previousContentLength) {
      soundService.playSndType();
    } else if (currentLength < _previousContentLength) {
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }
    
    _previousContentLength = currentLength;
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _tagController.dispose();
    _quillController.removeListener(_onQuillContentChanged);
    _quillController.dispose();
    _editorFocusNode.removeListener(_onFocusChange);
    _editorFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Mostrar toolbar quando o editor está focado
    if (_editorFocusNode.hasFocus) {
      setState(() => _showToolbar = true);
    }
  }

  void _initializeFromEntry(DiaryEntryEntity entry) {
    if (_isInitialized) return;
    _isInitialized = true;

    _titleController.text = entry.title ?? '';
    _previousTitleLength = _titleController.text.length;

    // Carregar conteúdo Quill
    try {
      if (entry.content.isNotEmpty && entry.content != '[]') {
        final deltaJson = jsonDecode(entry.content) as List;
        _quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _previousContentLength = _quillController.document.toPlainText().length;
      }
    } catch (e) {
      debugPrint('Error parsing Quill delta: $e');
    }

    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final controller = ref.read(diaryEditorControllerProvider(widget.entryId).notifier);

    // Atualizar título
    controller.updateTitle(_titleController.text);

    // Atualizar conteúdo
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();
    controller.updateContent(deltaJson, plainText);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryEditorControllerProvider(widget.entryId));
    final controller = ref.read(diaryEditorControllerProvider(widget.entryId).notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Inicializar com os dados da entrada
    if (state.entry != null && !_isInitialized) {
      _initializeFromEntry(state.entry!);
    }

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isEditing = widget.entryId != null;

    return PopScope(
      canPop: state.canExitSafely,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Salvar antes de sair
        final saved = await controller.saveNow();
        if (saved && mounted) {
          Navigator.pop(context);
        } else if (mounted) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, state, controller, isEditing, colorScheme),
        body: Column(
          children: [
            // Indicador de salvamento
            _buildSaveIndicator(state, colorScheme),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data da entrada
                    _buildDateSelector(state.entry?.entryDate ?? widget.initialDate ?? DateTime.now(), controller, theme),
                    const SizedBox(height: 16),

                    // Seletor de sentimento
                    _buildFeelingSection(state.entry?.feeling, controller, theme),
                    const SizedBox(height: 16),

                    // Campo de título
                    _buildTitleField(theme),
                    const SizedBox(height: 16),

                    // Editor de texto rico
                    _buildEditor(theme, colorScheme),
                    const SizedBox(height: 16),

                    // Tags
                    _buildTagsSection(state.entry?.tags ?? [], controller, theme),

                    // Estatísticas
                    if (state.entry != null)
                      _buildStats(state.entry!, colorScheme),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Toolbar do Quill
            if (_showToolbar) _buildToolbar(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    DiaryEditorState state,
    DiaryEditorController controller,
    bool isEditing,
    ColorScheme colorScheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(isEditing ? l10n.diaryEditorTitle : l10n.diaryEditorTitle),
      actions: [
        // Botão de template (apenas para novas entradas)
        if (!isEditing)
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => _showTemplateSelector(context, controller),
            tooltip: 'Templates',
          ),

        // Toggle favorito
        if (state.entry != null)
          IconButton(
            icon: Icon(
              state.entry!.starred ? Icons.star_rounded : Icons.star_outline_rounded,
              color: state.entry!.starred ? Colors.amber : null,
            ),
            onPressed: controller.toggleStarred,
            tooltip: state.entry!.starred ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          ),

        // Botão de deletar
        if (isEditing)
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () => _confirmDelete(context, controller),
            tooltip: 'Excluir',
          ),

        // Botão de salvar
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton.tonal(
            onPressed: state.isSaving
                ? null
                : () async {
                    final saved = await controller.saveNow();
                    if (saved && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entrada salva!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            child: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveIndicator(DiaryEditorState state, ColorScheme colorScheme) {
    if (!state.hasUnsavedChanges && state.saveStatus != EditorSaveStatus.saving) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 24,
      color: switch (state.saveStatus) {
        EditorSaveStatus.saving => colorScheme.primaryContainer,
        EditorSaveStatus.saved => Colors.green.withValues(alpha: 0.2),
        EditorSaveStatus.error => colorScheme.errorContainer,
        EditorSaveStatus.idle when state.hasUnsavedChanges => colorScheme.surfaceContainerHighest,
        _ => Colors.transparent,
      },
      child: Center(
        child: Text(
          switch (state.saveStatus) {
            EditorSaveStatus.saving => 'Salvando...',
            EditorSaveStatus.saved => 'Salvo ✓',
            EditorSaveStatus.error => 'Erro ao salvar',
            EditorSaveStatus.idle when state.hasUnsavedChanges => 'Alterações não salvas',
            _ => '',
          },
          style: TextStyle(
            fontSize: 12,
            color: switch (state.saveStatus) {
              EditorSaveStatus.saved => Colors.green.shade700,
              EditorSaveStatus.error => colorScheme.error,
              _ => colorScheme.onSurface.withValues(alpha: 0.6),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(DateTime date, DiaryEditorController controller, ThemeData theme) {
    final dateFormat = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR');

    return InkWell(
      onTap: () => _selectDate(date, controller),
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
              dateFormat.format(date),
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

  Widget _buildFeelingSection(String? feeling, DiaryEditorController controller, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.diaryHowAreYouFeeling,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        FeelingSelectorWidget(
          selectedFeeling: feeling,
          onFeelingSelected: controller.updateFeeling,
        ),
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _titleController,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: l10n.diaryEditorTitle,
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

  Widget _buildEditor(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QuillEditor.basic(
          controller: _quillController,
          focusNode: _editorFocusNode,
          config: QuillEditorConfig(
            padding: const EdgeInsets.all(16),
            placeholder: l10n.diaryEditorContentPlaceholder,
            expands: false,
            scrollable: true,
            autoFocus: false,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
        child: Row(
          children: [
            Expanded(
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
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_hide_rounded),
              onPressed: () {
                _editorFocusNode.unfocus();
                setState(() => _showToolbar = false);
              },
              tooltip: 'Esconder toolbar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(List<String> tags, DiaryEditorController controller, ThemeData theme) {
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
            ...tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => controller.removeTag(tag),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar'),
              onPressed: () => _showAddTagDialog(controller),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(DiaryEntryEntity entry, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Icon(
            Icons.notes_rounded,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.effectiveWordCount} palavras',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '~${entry.effectiveReadingTime} min de leitura',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(DateTime currentDate, DiaryEditorController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      final now = DateTime.now();
      final newDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        picked.year == now.year && picked.month == now.month && picked.day == now.day
            ? now.hour
            : 12,
        picked.year == now.year && picked.month == now.month && picked.day == now.day
            ? now.minute
            : 0,
      );
      controller.updateEntryDate(newDate);
    }
  }

  Future<void> _showAddTagDialog(DiaryEditorController controller) async {
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

    if (result != null && result.trim().isNotEmpty) {
      controller.addTag(result.trim());
    }
  }

  void _showTemplateSelector(BuildContext context, DiaryEditorController controller) {
    final templates = ref.read(diaryTemplatesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Escolha um template',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Text(template.iconEmoji, style: const TextStyle(fontSize: 32)),
                      title: Text(template.name),
                      subtitle: Text(template.description),
                      onTap: () {
                        Navigator.pop(context);
                        controller.applyTemplate(template);

                        // Atualizar o editor com o conteúdo do template
                        try {
                          final deltaJson = jsonDecode(template.initialContent) as List;
                          setState(() {
                            _quillController = QuillController(
                              document: Document.fromJson(deltaJson),
                              selection: const TextSelection.collapsed(offset: 0),
                            );
                            _quillController.addListener(_onContentChanged);
                          });
                        } catch (e) {
                          debugPrint('Error applying template: $e');
                        }
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
  }

  Future<void> _confirmDelete(BuildContext context, DiaryEditorController controller) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.diaryConfirmDelete),
        content: Text(l10n.diaryDeleteCannotUndo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final deleted = await controller.delete();
      if (deleted && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.diaryEntryDeleted)),
        );
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.diaryDiscardChanges),
        content: Text(l10n.diaryDiscardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

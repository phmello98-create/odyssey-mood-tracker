import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/diary_entry_isar.dart';
import '../../data/repositories/diary_isar_repository.dart';
import '../widgets/diary_editor_widgets.dart';

class DiaryEditorPage extends ConsumerStatefulWidget {
  final String? entryId; // Pode ser String legado ou ID numérico stringified
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
  late ScrollController _scrollController;
  late FocusNode _editorFocusNode;

  DiaryEntryIsar? _currentEntry;
  String? _selectedFeeling;
  List<String> _tags = [];
  String? _imagePath; // Caminho da foto anexada
  late DateTime _entryDate;

  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _editorFocusNode = FocusNode();
    _scrollController = ScrollController();
    _quillController = QuillController.basic();
    _entryDate = widget.initialDate ?? DateTime.now();

    _titleController.addListener(_markChanged);
    _quillController.addListener(_markChanged);

    _loadEntry();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    if (widget.entryId != null) {
      // Tentar parsing para Isar ID
      final isarId = int.tryParse(widget.entryId!);

      if (isarId != null) {
        final repo = ref.read(diaryIsarRepositoryProvider);
        final entry = await repo.getById(isarId);

        if (entry != null && mounted) {
          _currentEntry = entry;
          _titleController.text = entry.title ?? '';
          _selectedFeeling = entry.feeling;
          _tags = List.from(entry.tags);
          _entryDate = entry.entryDate;
          _imagePath = entry.imagePath;

          if (entry.content != null && entry.content!.isNotEmpty) {
            try {
              final json = jsonDecode(entry.content!);
              _quillController = QuillController(
                document: Document.fromJson(json),
                selection: const TextSelection.collapsed(offset: 0),
              );
              _quillController.addListener(_markChanged);
            } catch (e) {
              debugPrint('Error parsing quill content: $e');
            }
          }
        }
      } else {
        // TODO: Lógica de migração legado se necessário
        // Por enquanto, IDs não numéricos são ignorados (ou tratados como novos em branco)
      }
    } else if (widget.initialPrompt != null) {
      // Inserir prompt no editor se for novo
      _quillController.document.insert(0, '\n\n"${widget.initialPrompt}"\n');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(diaryIsarRepositoryProvider);
      final contentJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );
      final plainText = _quillController.document.toPlainText().trim();
      final now = DateTime.now();

      final entry = _currentEntry ?? DiaryEntryIsar();

      entry
        ..title = _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim()
        ..content = contentJson
        ..feeling = _selectedFeeling
        ..tags = _tags
        ..entryDate = _entryDate
        ..searchableText = plainText.isEmpty ? null : plainText
        ..imagePath = _imagePath
        ..updatedAt = now;

      if (_currentEntry == null) {
        entry.createdAt = now;
      }

      await repo.saveEntry(entry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (picked != null) {
      // Copiar para diretório do app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'diary_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
        _hasChanges = true;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.entryId != null ? 'Editando' : 'Nova Entrada',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              DateFormat('d MMMM, y', 'pt_BR').format(_entryDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _saveEntry,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('Salvar'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Humor
                  Text(
                    'Como você está?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumMoodSelector(
                    selectedMood: _selectedFeeling,
                    onSelected: (val) => setState(() {
                      _selectedFeeling = val;
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  HeadlessTitleField(
                    controller: _titleController,
                    hintText: 'Título da sua história...',
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  ModernTagInput(
                    tags: _tags,
                    onAddTag: (tag) => setState(() {
                      if (!_tags.contains(tag)) _tags.add(tag);
                      _hasChanges = true;
                    }),
                    onRemoveTag: (tag) => setState(() => _tags.remove(tag)),
                    onInputTap: _showAddTagDialog,
                  ),
                  const SizedBox(height: 20),

                  // Foto
                  _buildPhotoSection(theme),

                  const Divider(height: 40),

                  // Editor
                  QuillEditor.basic(
                    controller: _quillController,
                    focusNode: _editorFocusNode,
                    config: QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      placeholder: 'Escreva sobre seu dia...',
                      autoFocus: false,
                    ),
                  ),

                  const SizedBox(height: 80), // Espaço extra
                ],
              ),
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                toolbarIconAlignment: WrapAlignment.center,
                showClipboardCopy: false,
                showClipboardCut: false,
                showClipboardPaste: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTagDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Trabalho, Família...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tags.add(result);
        _hasChanges = true;
      });
    }
  }

  Widget _buildPhotoSection(ThemeData theme) {
    if (_imagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_imagePath!),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAddPhotoButton(theme),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return _buildAddPhotoButton(theme);
  }

  Widget _buildAddPhotoButton(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicionar foto',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

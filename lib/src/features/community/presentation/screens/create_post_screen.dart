import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/community_providers.dart';
import '../../domain/post.dart';
import '../../domain/post_dto.dart';
import '../../domain/topic.dart';
import '../../domain/tag.dart';

/// Tela para criar um novo post - Versão Rica
/// Com título, imagens, tags e seleção de tópico
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

  PostType _selectedType = PostType.text;
  CommunityTopic? _selectedTopic;
  List<String> _tags = [];
  List<File> _selectedImages = [];
  bool _isPosting = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            images.take(4 - _selectedImages.length).map((x) => File(x.path)),
          );
          if (_selectedImages.isNotEmpty) {
            _selectedType = PostType.image;
          }
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) {
        _selectedType = PostType.text;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().toLowerCase().replaceAll('#', '');
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag) && _tags.length < 5) {
      setState(() {
        _tags.add(cleanTag);
        _tagController.clear();
      });
      HapticFeedback.selectionClick();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    HapticFeedback.lightImpact();
  }

  void _showTagSuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _TagSuggestionsSheet(onTagSelected: _addTag, currentTags: _tags),
    );
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite algo para compartilhar')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final repo = ref.read(communityRepositoryProvider);

      // Extrair tags do conteúdo + tags selecionadas
      final extractedTags = PostTag.extractFromText(_contentController.text);
      final allTags = {..._tags, ...extractedTags}.toList();

      final dto = CreatePostDto(
        content: _contentController.text.trim(),
        type: _selectedType,
        categories: _selectedTopic != null ? [_selectedTopic!.name] : [],
        // TODO: Upload images to Firebase Storage
      );

      await repo.createPost(dto);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Post publicado!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: _buildAppBar(colors),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de post
                  _buildTypeSelector(colors),
                  const SizedBox(height: 16),

                  // Tópico
                  _buildTopicSelector(colors),
                  const SizedBox(height: 16),

                  // Título (opcional)
                  _buildTitleField(colors),
                  const SizedBox(height: 12),

                  // Conteúdo
                  _buildContentField(colors),

                  // Imagens selecionadas
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImagePreview(colors),
                  ],

                  // Tags
                  const SizedBox(height: 16),
                  _buildTagsSection(colors),
                ],
              ),
            ),
          ),

          // Toolbar
          _buildToolbar(colors),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colors) {
    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colors.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Novo Post',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: _isPosting ? null : _createPost,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Publicar'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeChip(colors, PostType.text, '📝', 'Texto'),
          _buildTypeChip(colors, PostType.mood, '💭', 'Humor'),
          _buildTypeChip(colors, PostType.insight, '💡', 'Insight'),
          _buildTypeChip(colors, PostType.achievement, '🏆', 'Conquista'),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    ColorScheme colors,
    PostType type,
    String emoji,
    String label,
  ) {
    final isSelected = _selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(emoji), const SizedBox(width: 4), Text(label)],
        ),
        selected: isSelected,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
        },
        backgroundColor: colors.surfaceContainerHighest,
        selectedColor: colors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? colors.primary : colors.onSurfaceVariant,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildTopicSelector(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tópico',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CommunityTopic.values.map((topic) {
              final isSelected = _selectedTopic == topic;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(topic.emoji),
                      const SizedBox(width: 4),
                      Text(topic.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTopic = isSelected ? null : topic;
                    });
                  },
                  backgroundColor: colors.surfaceContainerHighest,
                  selectedColor: Color(topic.colorValue).withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Color(topic.colorValue)
                        : colors.onSurfaceVariant,
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(ColorScheme colors) {
    return TextField(
      controller: _titleController,
      maxLength: 100,
      decoration: InputDecoration(
        hintText: 'Título (opcional)',
        hintStyle: TextStyle(
          color: colors.onSurfaceVariant.withOpacity(0.5),
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
        counterText: '',
      ),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildContentField(ColorScheme colors) {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocus,
      maxLines: null,
      minLines: 4,
      maxLength: 1000,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'O que você quer compartilhar?',
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.5)),
        border: InputBorder.none,
        counterStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      ),
      style: TextStyle(fontSize: 15, height: 1.5, color: colors.onSurface),
    );
  }

  Widget _buildImagePreview(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagens (${_selectedImages.length}/4)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showTagSuggestions,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Sugestões'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Tags selecionadas
            ..._tags.map(
              (tag) => Chip(
                label: Text('#$tag'),
                onDeleted: () => _removeTag(tag),
                deleteIcon: const Icon(Icons.close, size: 14),
                backgroundColor: colors.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: colors.primary, fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            // Input de nova tag
            if (_tags.length < 5)
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _tagController,
                  onSubmitted: _addTag,
                  decoration: InputDecoration(
                    hintText: '+ Adicionar',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Image picker
            IconButton(
              icon: Badge(
                isLabelVisible: _selectedImages.isNotEmpty,
                label: Text('${_selectedImages.length}'),
                child: Icon(
                  Icons.image_outlined,
                  color: _selectedImages.isEmpty
                      ? colors.onSurfaceVariant
                      : colors.primary,
                ),
              ),
              onPressed: _selectedImages.length < 4 ? _pickImages : null,
            ),
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: colors.onSurfaceVariant,
              ),
              onPressed: () {
                // TODO: Emoji picker
              },
            ),
            IconButton(
              icon: Icon(Icons.tag_rounded, color: colors.onSurfaceVariant),
              onPressed: _showTagSuggestions,
            ),
            const Spacer(),
            Text(
              '${_contentController.text.length}/1000',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de sugestões de tags
class _TagSuggestionsSheet extends StatelessWidget {
  final Function(String) onTagSelected;
  final List<String> currentTags;

  const _TagSuggestionsSheet({
    required this.onTagSelected,
    required this.currentTags,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestions = SuggestedTags.all
        .where((t) => !currentTags.contains(t))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags Populares',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((tag) {
              return ActionChip(
                label: Text('#$tag'),
                onPressed: () {
                  onTagSelected(tag);
                  Navigator.pop(context);
                },
                backgroundColor: colors.surfaceContainerHighest,
                labelStyle: TextStyle(color: colors.primary, fontSize: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

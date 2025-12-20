import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final String? initialContent;
  final PostType? initialType;
  final CommunityTopic? initialTopic;
  final String? selectedMoodLabel;
  final String? selectedMoodEmoji;

  const CreatePostScreen({
    super.key,
    this.initialContent,
    this.initialType,
    this.initialTopic,
    this.selectedMoodLabel,
    this.selectedMoodEmoji,
  });

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

  // Mood selecionado para compartilhar
  String? _selectedMoodLabel;
  String? _selectedMoodEmoji;
  String? _selectedMoodAsset;

  final ImagePicker _imagePicker = ImagePicker();

  // Lista de moods disponíveis para seleção com assets SVG
  static const List<Map<String, dynamic>> _availableMoods = [
    {
      'label': 'Ótimo',
      'emoji': '😊',
      'asset': 'assets/mood_icons/smile.svg',
      'color': 0xFF4CAF50,
    },
    {
      'label': 'Bem',
      'emoji': '🙂',
      'asset': 'assets/mood_icons/calm.svg',
      'color': 0xFF7C4DFF,
    },
    {
      'label': 'Ok',
      'emoji': '😐',
      'asset': 'assets/mood_icons/neutral.svg',
      'color': 0xFFFFC107,
    },
    {
      'label': 'Mal',
      'emoji': '😔',
      'asset': 'assets/mood_icons/sad.svg',
      'color': 0xFFFF9800,
    },
    {
      'label': 'Péssimo',
      'emoji': '😢',
      'asset': 'assets/mood_icons/loudly_crying.svg',
      'color': 0xFFF44336,
    },
  ];

  // Tags populares pré-definidas
  static const List<String> _popularTags = [
    'humor',
    'reflexão',
    'gratidão',
    'conquista',
    'meditação',
    'produtividade',
    'saúde',
    'motivação',
    'foco',
    'autocuidado',
    'mindfulness',
    'rotina',
    'hábitos',
    'energia',
    'paz',
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar com valores passados
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.initialTopic != null) {
      _selectedTopic = widget.initialTopic;
    }
    if (widget.selectedMoodLabel != null) {
      _selectedMoodLabel = widget.selectedMoodLabel;
      // Encontrar o asset correspondente ao label
      final mood = _availableMoods.firstWhere(
        (m) => m['label'] == widget.selectedMoodLabel,
        orElse: () => _availableMoods.first,
      );
      _selectedMoodAsset = mood['asset'] as String;
      _selectedMoodEmoji = mood['emoji'] as String;
    }
    if (widget.selectedMoodEmoji != null && _selectedMoodEmoji == null) {
      _selectedMoodEmoji = widget.selectedMoodEmoji;
    }

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
      final isOffline = ref.read(isOfflineModeProvider);

      // Extrair tags do conteúdo + tags selecionadas
      final extractedTags = PostTag.extractFromText(_contentController.text);
      final allTags = {..._tags, ...extractedTags}.toList();

      // Construir metadata com mood se selecionado (qualquer tipo de post)
      Map<String, dynamic>? metadata;
      if (_selectedMoodLabel != null) {
        metadata = {
          'moodLabel': _selectedMoodLabel,
          if (_selectedMoodEmoji != null) 'moodEmoji': _selectedMoodEmoji,
          if (_selectedMoodAsset != null) 'moodAsset': _selectedMoodAsset,
        };
      }

      // Caminhos das imagens selecionadas
      final imagePaths = _selectedImages.map((file) => file.path).toList();

      final dto = CreatePostDto(
        content: _contentController.text.trim(),
        type: _selectedType,
        categories: _selectedTopic != null ? [_selectedTopic!.name] : [],
        metadata: metadata,
        localImagePaths: imagePaths,
      );

      // Usar mock repository se estiver offline
      if (isOffline) {
        final mockRepo = ref.read(mockCommunityRepositoryProvider);
        await mockRepo.createPost(dto);
      } else {
        final repo = ref.read(communityRepositoryProvider);
        await repo!.createPost(dto);
      }

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

                  // Seletor de Mood (apenas para posts de humor)
                  if (_selectedType == PostType.mood) ...[
                    _buildMoodSelector(colors),
                    const SizedBox(height: 16),
                  ],

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

                  // Espaço extra no final
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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

  Widget _buildMoodSelector(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Como você está se sentindo?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedMoodAsset != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(
                    _availableMoods.firstWhere(
                          (m) => m['asset'] == _selectedMoodAsset,
                          orElse: () => _availableMoods.first,
                        )['color']
                        as int,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  _selectedMoodAsset!,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Color(
                      _availableMoods.firstWhere(
                            (m) => m['asset'] == _selectedMoodAsset,
                            orElse: () => _availableMoods.first,
                          )['color']
                          as int,
                    ),
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _selectedMoodLabel != null
                  ? colors.primary.withOpacity(0.3)
                  : colors.outline.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _availableMoods.map((mood) {
              final isSelected = _selectedMoodLabel == mood['label'];
              final moodColor = Color(mood['color'] as int);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedMoodLabel = mood['label'] as String;
                    _selectedMoodEmoji = mood['emoji'] as String;
                    _selectedMoodAsset = mood['asset'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? moodColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: moodColor, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: isSelected ? 44 : 40,
                          height: isSelected ? 44 : 40,
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(
                              isSelected ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              mood['asset'] as String,
                              width: isSelected ? 26 : 22,
                              height: isSelected ? 26 : 22,
                              colorFilter: ColorFilter.mode(
                                moodColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mood['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? moodColor
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedMoodLabel != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(
                    _availableMoods.firstWhere(
                          (m) => m['label'] == _selectedMoodLabel,
                          orElse: () => _availableMoods.first,
                        )['color']
                        as int,
                  ).withOpacity(0.15),
                  Color(
                    _availableMoods.firstWhere(
                          (m) => m['label'] == _selectedMoodLabel,
                          orElse: () => _availableMoods.first,
                        )['color']
                        as int,
                  ).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final mood = _availableMoods.firstWhere(
                      (m) => m['label'] == _selectedMoodLabel,
                      orElse: () => _availableMoods.first,
                    );
                    return SvgPicture.asset(
                      _selectedMoodAsset ?? mood['asset'] as String,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        Color(mood['color'] as int),
                        BlendMode.srcIn,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Sentindo-se $_selectedMoodLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(
                      _availableMoods.firstWhere(
                            (m) => m['label'] == _selectedMoodLabel,
                            orElse: () => _availableMoods.first,
                          )['color']
                          as int,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _titleController,
        maxLength: 100,
        decoration: InputDecoration(
          hintText: 'Título (opcional)',
          hintStyle: TextStyle(
            color: colors.onSurfaceVariant.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          counterText: '',
        ),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildContentField(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            maxLines: null,
            minLines: 4,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'O que você quer compartilhar?',
              hintStyle: TextStyle(
                color: colors.onSurfaceVariant.withOpacity(0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              counterText: '',
            ),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Barra de ações
          Row(
            children: [
              // Botão de adicionar foto
              GestureDetector(
                onTap: _selectedImages.length < 4 ? _pickImages : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedImages.isEmpty
                        ? colors.surfaceContainerHighest
                        : colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedImages.isEmpty
                          ? colors.outline.withOpacity(0.2)
                          : colors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: _selectedImages.isEmpty
                            ? colors.onSurfaceVariant
                            : colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedImages.isEmpty
                            ? 'Adicionar foto'
                            : '${_selectedImages.length}/4 fotos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _selectedImages.isEmpty
                              ? colors.onSurfaceVariant
                              : colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Contador de caracteres
              Text(
                '${_contentController.text.length}/1000',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
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
        // Título
        Row(
          children: [
            Icon(Icons.tag_rounded, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_tags.length}/5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Tags selecionadas
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.15),
                      colors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Tags populares para adicionar
        Text(
          'Sugestões',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularTags
              .where((tag) => !_tags.contains(tag))
              .take(10)
              .map((tag) {
                return GestureDetector(
                  onTap: () {
                    if (_tags.length < 5) {
                      HapticFeedback.selectionClick();
                      _addTag(tag);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
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

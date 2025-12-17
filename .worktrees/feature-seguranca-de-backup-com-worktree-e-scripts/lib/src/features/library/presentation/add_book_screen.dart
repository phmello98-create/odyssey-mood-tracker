import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/library/data/synced_book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/data/open_library_api.dart';
import 'package:odyssey/src/features/library/data/book_cover_service.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  final Book? bookToEdit;

  const AddBookScreen({super.key, this.bookToEdit});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _currentPageController = TextEditingController();
  final _yearController = TextEditingController();
  final _isbnController = TextEditingController();
  final _genreController = TextEditingController();
  final _notesController = TextEditingController();
  final _reviewController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _openLibraryApi = OpenLibraryApi();

  // Predefined genres
  static const List<Map<String, dynamic>> _genres = [
    {'name': 'Ficção', 'icon': '📚', 'en': 'Fiction'},
    {'name': 'Não-Ficção', 'icon': '📖', 'en': 'Non-Fiction'},
    {'name': 'Ficção Científica', 'icon': '🚀', 'en': 'Sci-Fi'},
    {'name': 'Fantasia', 'icon': '🧙', 'en': 'Fantasy'},
    {'name': 'Mistério', 'icon': '🔍', 'en': 'Mystery'},
    {'name': 'Thriller', 'icon': '😱', 'en': 'Thriller'},
    {'name': 'Romance', 'icon': '💕', 'en': 'Romance'},
    {'name': 'Terror', 'icon': '👻', 'en': 'Horror'},
    {'name': 'Biografia', 'icon': '👤', 'en': 'Biography'},
    {'name': 'História', 'icon': '🏛️', 'en': 'History'},
    {'name': 'Ciência', 'icon': '🔬', 'en': 'Science'},
    {'name': 'Filosofia', 'icon': '🤔', 'en': 'Philosophy'},
    {'name': 'Psicologia', 'icon': '🧠', 'en': 'Psychology'},
    {'name': 'Autoajuda', 'icon': '💪', 'en': 'Self-Help'},
    {'name': 'Negócios', 'icon': '💼', 'en': 'Business'},
    {'name': 'Tecnologia', 'icon': '💻', 'en': 'Technology'},
    {'name': 'Arte', 'icon': '🎨', 'en': 'Art'},
    {'name': 'Poesia', 'icon': '✨', 'en': 'Poetry'},
    {'name': 'Religião', 'icon': '🙏', 'en': 'Religion'},
    {'name': 'Viagem', 'icon': '✈️', 'en': 'Travel'},
    {'name': 'Culinária', 'icon': '🍳', 'en': 'Cooking'},
    {'name': 'Infantil', 'icon': '🧒', 'en': 'Children'},
    {'name': 'Jovem Adulto', 'icon': '🎒', 'en': 'Young Adult'},
    {'name': 'Quadrinhos', 'icon': '💥', 'en': 'Comics'},
    {'name': 'Outro', 'icon': '📝', 'en': 'Other'},
  ];

  BookStatus _status = BookStatus.forLater;
  BookFormat _format = BookFormat.paperback;
  int? _rating;
  bool _favourite = false;
  DateTime? _startDate;
  DateTime? _finishDate;
  String? _coverUrl;
  Uint8List? _coverBytes; // Cover bytes to save
  String? _localCoverPath; // Existing local cover path
  // bool _isSearching = false;

  bool get _isEditing => widget.bookToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadBookData();
    }
  }

  void _loadBookData() {
    final book = widget.bookToEdit!;
    _titleController.text = book.title;
    _subtitleController.text = book.subtitle ?? '';
    _authorController.text = book.author;
    _pagesController.text = book.pages?.toString() ?? '';
    _currentPageController.text = book.currentPage.toString();
    _yearController.text = book.publicationYear?.toString() ?? '';
    _isbnController.text = book.isbn ?? '';
    _genreController.text = book.genre ?? '';
    _notesController.text = book.notes ?? '';
    _reviewController.text = book.myReview ?? '';
    _highlightsController.text = book.highlights ?? '';
    _status = book.status;
    _format = book.bookFormat;
    _rating = book.rating;
    _favourite = book.favourite;
    _startDate = book.latestStartDate;
    _finishDate = book.latestFinishDate;
    _localCoverPath = book.coverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _currentPageController.dispose();
    _yearController.dispose();
    _isbnController.dispose();
    _genreController.dispose();
    _notesController.dispose();
    _reviewController.dispose();
    _highlightsController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchBookDialog(
        api: _openLibraryApi,
        onBookSelected: (book) {
          setState(() {
            _titleController.text = book.title;
            _subtitleController.text = book.subtitle ?? '';
            _authorController.text = book.authors.isNotEmpty ? book.authors.first : '';
            if (book.numberOfPages != null) {
              _pagesController.text = book.numberOfPages.toString();
            }
            if (book.firstPublishYear != null) {
              _yearController.text = book.firstPublishYear!;
            }
            if (book.isbn.isNotEmpty) {
              _isbnController.text = book.isbn.first;
            }
            _coverUrl = book.coverUrl;
          });
        },
      ),
    );
  }

  void _showCoverPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context)!.chooseCover,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Gallery option
              _buildCoverOption(
                icon: Icons.photo_library_outlined,
                label: 'Escolher da Galeria',
                subtitle: 'Selecione uma imagem do seu dispositivo',
                onTap: () async {
                  Navigator.pop(context);
                  final bytes = await BookCoverService.pickFromGallery();
                  if (bytes != null) {
                    setState(() {
                      _coverBytes = bytes;
                      _coverUrl = null; // Clear URL when using local file
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              
              // Camera option
              _buildCoverOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tirar Foto',
                subtitle: 'Use a câmera para fotografar a capa',
                onTap: () async {
                  Navigator.pop(context);
                  final bytes = await BookCoverService.pickFromCamera();
                  if (bytes != null) {
                    setState(() {
                      _coverBytes = bytes;
                      _coverUrl = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              
              // Search online option
              _buildCoverOption(
                icon: Icons.cloud_download_outlined,
                label: 'Buscar Online',
                subtitle: 'Encontre a capa na Open Library',
                onTap: () {
                  Navigator.pop(context);
                  _showOnlineCoverSearch();
                },
              ),
              const SizedBox(height: 12),
              
              // Remove cover option (if has cover)
              if (_coverBytes != null || _coverUrl != null || _localCoverPath != null)
                _buildCoverOption(
                  icon: Icons.delete_outline,
                  label: 'Remover Capa',
                  subtitle: 'Usar placeholder padrão',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _coverBytes = null;
                      _coverUrl = null;
                      _localCoverPath = null;
                    });
                  },
                ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive 
              ? colorScheme.error.withValues(alpha: 0.1)
              : (isDark 
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
          border: isDark ? null : Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isDestructive ? colorScheme.error : colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showOnlineCoverSearch() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final isbn = _isbnController.text.trim();
    
    showDialog(
      context: context,
      builder: (context) => _CoverSearchDialog(
        initialQuery: title.isNotEmpty ? '$title $author' : (isbn.isNotEmpty ? isbn : ''),
        onCoverSelected: (url) async {
          // Download and set cover
          final bytes = await BookCoverService.downloadFromUrl(url);
          if (bytes != null && mounted) {
            setState(() {
              _coverBytes = bytes;
              _coverUrl = url;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(_isEditing ? AppLocalizations.of(context)!.editBook : AppLocalizations.of(context)!.addBook),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
              tooltip: 'Buscar online',
            ),
          TextButton(
            onPressed: _saveBook,
            child: Text(
              AppLocalizations.of(context)!.save,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cover placeholder
            Center(
              child: GestureDetector(
                onTap: _showCoverPicker,
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildCoverPreview(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Título *',
              icon: Icons.book_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o título do livro';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subtitle
            _buildTextField(
              controller: _subtitleController,
              label: 'Subtítulo',
              icon: Icons.short_text,
            ),
            const SizedBox(height: 16),

            // Author
            _buildTextField(
              controller: _authorController,
              label: 'Autor *',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome do autor';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Divider
            const Divider(),
            const SizedBox(height: 16),

            // Status
            Text(AppLocalizations.of(context)!.status,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusSelector(),
            const SizedBox(height: 20),

            // Rating
            Text(
              AppLocalizations.of(context)!.rating,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRatingSelector(),
            const SizedBox(height: 20),

            // Dates row
            if (_status == BookStatus.inProgress || _status == BookStatus.read) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Início',
                      date: _startDate,
                      onTap: () => _selectDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_status == BookStatus.read)
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Término',
                        date: _finishDate,
                        onTap: () => _selectDate(isStart: false),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Divider
            const Divider(),
            const SizedBox(height: 16),

            // Format
            Text(AppLocalizations.of(context)!.format,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildFormatSelector(),
            const SizedBox(height: 20),

            // Pages row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _pagesController,
                    label: 'Total de Páginas',
                    icon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _currentPageController,
                    label: 'Página Atual',
                    icon: Icons.bookmark_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Year and ISBN row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _yearController,
                    label: 'Ano de Publicação',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _isbnController,
                    label: 'ISBN',
                    icon: Icons.qr_code,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Genre with predefined options
            _buildGenreSelector(),
            const SizedBox(height: 24),

            // Divider
            const Divider(),
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: AppLocalizations.of(context)!.notes,
              icon: Icons.note_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Highlights / Best quotes
            _buildTextField(
              controller: _highlightsController,
              label: '✨ Melhores Trechos',
              icon: Icons.format_quote_outlined,
              maxLines: 6,
            ),
            const SizedBox(height: 16),

            // Review
            _buildTextField(
              controller: _reviewController,
              label: 'Minha Resenha',
              icon: Icons.rate_review_outlined,
              maxLines: 6,
            ),
            const SizedBox(height: 24),

            // Favourite toggle
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.addToFavorites),
              subtitle: Text(AppLocalizations.of(context)!.markAsFavorite),
              value: _favourite,
              onChanged: (value) => setState(() => _favourite = value),
              secondary: Icon(
                _favourite ? Icons.favorite : Icons.favorite_border,
                color: _favourite ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isDark ? 0 : 2,
                ),
                child: Text(
                  _isEditing ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.addBook,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    // Priority: local bytes > network URL > existing local path > placeholder
    if (_coverBytes != null) {
      return Image.memory(
        _coverBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
      );
    }
    
    if (_coverUrl != null) {
      return Image.network(
        _coverUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
      );
    }
    
    if (_localCoverPath != null) {
      final file = File(_localCoverPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
        );
      }
    }
    
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.addCover,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark 
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark 
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark 
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = [
      {'status': BookStatus.forLater, 'label': 'Para Ler', 'icon': Icons.bookmark_outline},
      {'status': BookStatus.inProgress, 'label': AppLocalizations.of(context)!.reading, 'icon': Icons.auto_stories_outlined},
      {'status': BookStatus.read, 'label': AppLocalizations.of(context)!.read, 'icon': Icons.check_circle_outline},
      {'status': BookStatus.unfinished, 'label': AppLocalizations.of(context)!.abandoned, 'icon': Icons.cancel_outlined},
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((item) {
        final isSelected = _status == item['status'];
        final status = item['status'] as BookStatus;
        
        // Different colors for each status
        final accentGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
        final statusColor = switch (status) {
          BookStatus.forLater => colorScheme.tertiary,
          BookStatus.inProgress => colorScheme.primary,
          BookStatus.read => accentGreen,
          BookStatus.unfinished => colorScheme.error,
        };
        
        return GestureDetector(
          onTap: () => setState(() => _status = status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.85)])
                  : null,
              color: isSelected ? null : (isDark 
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Colors.transparent 
                    : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.3),
                width: 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : (isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [
      {'format': BookFormat.paperback, 'label': '📖 Físico'},
      {'format': BookFormat.hardcover, 'label': '📕 Capa Dura'},
      {'format': BookFormat.ebook, 'label': '📱 E-book'},
      {'format': BookFormat.audiobook, 'label': '🎧 Audiobook'},
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((item) {
        final isSelected = _format == item['format'];
        return GestureDetector(
          onTap: () => setState(() => _format = item['format'] as BookFormat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.85)])
                  : null,
              color: isSelected ? null : (isDark 
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Colors.transparent 
                    : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.3),
                width: 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : (isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]),
            ),
            child: Text(
              item['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = (index + 1) * 10;
        final isFilled = _rating != null && _rating! >= starValue;
        final isHalf = _rating != null && _rating! >= starValue - 5 && _rating! < starValue;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (_rating == starValue) {
                _rating = starValue - 5; // Half star
              } else if (_rating == starValue - 5) {
                _rating = null; // Clear
              } else {
                _rating = starValue; // Full star
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : (isHalf ? Icons.star_half : Icons.star_border),
              color: Colors.amber,
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? null : Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Selecionar',
                    style: TextStyle(
                      color: date != null 
                          ? Theme.of(context).colorScheme.onSurface 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _finishDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _finishDate = picked;
        }
      });
    }
  }

  Widget _buildGenreSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.genre,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected genre display or text field for custom
        if (_genreController.text.isNotEmpty && 
            !_genres.any((g) => g['name'] == _genreController.text))
          // Custom genre entered
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '📝 ${_genreController.text}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _genreController.clear()),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          )
        else
          // Genre chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) {
              final isSelected = _genreController.text == genre['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _genreController.clear();
                    } else {
                      _genreController.text = genre['name'];
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(colors: [
                            colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                            colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                          ])
                        : null,
                    color: isSelected 
                        ? null
                        : (isDark 
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                            : colorScheme.surface),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected 
                          ? colorScheme.primary.withValues(alpha: 0.6)
                          : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        genre['icon'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        genre['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? colorScheme.primary 
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        
        const SizedBox(height: 12),
        
        // Custom genre input
        GestureDetector(
          onTap: () => _showCustomGenreDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark 
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2),
                style: BorderStyle.solid,
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Adicionar gênero personalizado',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomGenreDialog() {
    final customController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogColorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: dialogColorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.generoPersonalizado),
          content: TextField(
            controller: customController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Digite o gênero',
              filled: true,
              fillColor: dialogColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final text = customController.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _genreController.text = text);
                }
                Navigator.pop(dialogContext);
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(syncedBookRepositoryProvider);
    final now = DateTime.now();
    final bookId = widget.bookToEdit?.id ?? now.millisecondsSinceEpoch.toString();

    // Build readings data
    String? readingsData;
    if (_startDate != null || _finishDate != null) {
      readingsData = '${_startDate?.toIso8601String() ?? ''}|${_finishDate?.toIso8601String() ?? ''}|';
    }

    // Save cover if we have new bytes
    String? coverPath = _localCoverPath;
    bool hasCover = coverPath != null;
    
    if (_coverBytes != null) {
      final savedPath = await BookCoverService.saveCover(bookId, _coverBytes!);
      if (savedPath != null) {
        coverPath = savedPath;
        hasCover = true;
      }
    } else if (_coverBytes == null && _coverUrl == null && _localCoverPath == null) {
      // Cover was removed
      await BookCoverService.deleteCover(bookId);
      coverPath = null;
      hasCover = false;
    }

    final book = Book(
      id: bookId,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
      author: _authorController.text.trim(),
      pages: int.tryParse(_pagesController.text),
      currentPage: int.tryParse(_currentPageController.text) ?? 0,
      publicationYear: int.tryParse(_yearController.text),
      isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
      genre: _genreController.text.trim().isEmpty ? null : _genreController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      myReview: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      highlights: _highlightsController.text.trim().isEmpty ? null : _highlightsController.text.trim(),
      statusIndex: _status.index,
      formatIndex: _format.index,
      rating: _rating,
      favourite: _favourite,
      readingsData: readingsData,
      dateAdded: widget.bookToEdit?.dateAdded ?? now,
      dateModified: now,
      coverPath: coverPath,
      hasCover: hasCover,
      totalReadingTimeSeconds: widget.bookToEdit?.totalReadingTimeSeconds ?? 0,
    );

    if (_isEditing) {
      await repo.updateBook(book);
      FeedbackService.showSuccess(context, '📚 Livro atualizado!');
    } else {
      await repo.addBook(book);
      FeedbackService.showSuccess(context, '📖 "${book.title}" adicionado!');
    }

    Navigator.pop(context);
  }
}

class _SearchBookDialog extends StatefulWidget {
  final OpenLibraryApi api;
  final Function(OpenLibraryBook) onBookSelected;

  const _SearchBookDialog({
    required this.api,
    required this.onBookSelected,
  });

  @override
  State<_SearchBookDialog> createState() => _SearchBookDialogState();
}

class _SearchBookDialogState extends State<_SearchBookDialog> {
  final _searchController = TextEditingController();
  List<OpenLibraryBook> _results = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.api.searchBooks(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          if (results.isEmpty) {
            _error = 'Nenhum livro encontrado';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao buscar livros';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: UltravioletColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.searchBookOnline,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Título, autor ou ISBN',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final book = _results[index];
                            return ListTile(
                              leading: book.coverUrl != null
                                  ? Image.network(
                                      book.coverUrl!,
                                      width: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.book),
                                    )
                                  : const Icon(Icons.book),
                              title: Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                book.authors.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                widget.onBookSelected(book);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for searching book covers online
class _CoverSearchDialog extends StatefulWidget {
  final String initialQuery;
  final Function(String url) onCoverSelected;

  const _CoverSearchDialog({
    required this.initialQuery,
    required this.onCoverSelected,
  });

  @override
  State<_CoverSearchDialog> createState() => _CoverSearchDialogState();
}

class _CoverSearchDialogState extends State<_CoverSearchDialog> {
  final _searchController = TextEditingController();
  final _openLibraryApi = OpenLibraryApi();
  List<String> _coverUrls = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _search();
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _coverUrls = [];
    });

    try {
      final results = await _openLibraryApi.searchBooks(query);
      if (mounted) {
        final urls = results
            .where((b) => b.coverUrl != null)
            .map((b) => b.coverUrl!)
            .toList();
        
        setState(() {
          _coverUrls = urls;
          _isLoading = false;
          if (urls.isEmpty) {
            _error = 'Nenhuma capa encontrada';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao buscar capas';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: UltravioletColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.searchCoverOnline,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.selectCoverFromOpenLibrary,
              style: const TextStyle(
                color: UltravioletColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Título ou autor',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: UltravioletColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(_error!),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.67,
                          ),
                          itemCount: _coverUrls.length,
                          itemBuilder: (context, index) {
                            final url = _coverUrls[index];
                            return GestureDetector(
                              onTap: () {
                                widget.onCoverSelected(url);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: UltravioletColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: UltravioletColors.surfaceVariant,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: UltravioletColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
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
}

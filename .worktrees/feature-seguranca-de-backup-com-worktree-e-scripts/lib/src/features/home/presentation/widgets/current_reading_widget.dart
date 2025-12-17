import 'dart:io';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';

class CurrentReadingWidget extends StatefulWidget {
  const CurrentReadingWidget({super.key});

  @override
  State<CurrentReadingWidget> createState() => _CurrentReadingWidgetState();
}

class _CurrentReadingWidgetState extends State<CurrentReadingWidget> {
  Box<Book>? _booksBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      if (Hive.isBoxOpen('books_v3')) {
        _booksBox = Hive.box<Book>('books_v3');
      } else {
        _booksBox = await Hive.openBox<Book>('books_v3');
      }
    } catch (e) {
      debugPrint('Error opening books box: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return _buildContainer(colors, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_booksBox == null) {
      return _buildContainer(colors, child: _buildEmptyState(colors));
    }

    return ValueListenableBuilder<Box<Book>>(
      valueListenable: _booksBox!.listenable(),
      builder: (context, box, _) {
        // Encontrar livro em leitura (statusIndex 1 = inProgress)
        final readingBooks = box.values
            .where((book) => !book.deleted && book.statusIndex == 1)
            .toList();

        if (readingBooks.isEmpty) {
          return _buildContainer(colors, child: _buildEmptyState(colors));
        }

        final book = readingBooks.first;
        final title = book.title;
        final author = book.author;
        final currentPage = book.currentPage;
        final totalPages = book.pages ?? 1;
        final coverPath = book.coverPath;
        final progress = totalPages > 0 ? currentPage / totalPages : 0.0;

        return _buildContainer(
          colors,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF8D6E63), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.lendoAgora, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Cover
                    Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        image: coverPath != null && File(coverPath).existsSync()
                            ? DecorationImage(image: FileImage(File(coverPath)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: coverPath == null || !File(coverPath).existsSync()
                          ? Icon(Icons.book, color: colors.onSurfaceVariant, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            author,
                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: colors.surfaceContainerHighest,
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF8D6E63)),
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8D6E63)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF8D6E63), size: 18),
              ),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.leituraAtual, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.library_add_outlined, color: colors.onSurfaceVariant, size: 20),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.nenhumLivroEmLeitura, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
              ],
            ),
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
        boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

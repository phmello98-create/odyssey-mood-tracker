import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class BookCardList extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleFavourite;

  const BookCardList({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context);
    final statusLabel = _getStatusLabel(context);
    final formatLabel = _getFormatLabel();

    return OdysseyCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      backgroundColor: colors.surface,
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          Hero(
            tag: 'book_cover_list_${book.id}',
            child: _buildCover(context, statusColor),
          ),
          const SizedBox(width: 14),

          // Book Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with favourite
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book.subtitle != null &&
                              book.subtitle!.isNotEmpty)
                            Text(
                              book.subtitle!,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (onToggleFavourite != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onToggleFavourite!();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: book.favourite
                                  ? colors.error.withValues(alpha: 0.15)
                                  : colors.surfaceContainerHighest.withValues(
                                      alpha: 0.3,
                                    ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              book.favourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: book.favourite
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Author
                Text(
                  book.author,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Status chip
                    _buildChip(
                      statusLabel,
                      statusColor.withValues(alpha: 0.15),
                      statusColor,
                    ),

                    // Format chip
                    _buildChip(
                      formatLabel,
                      colors.surfaceContainerHighest,
                      colors.onSurfaceVariant,
                    ),

                    // Genre chip
                    if (book.genre != null && book.genre!.isNotEmpty)
                      _buildChip(
                        book.genre!,
                        colors.tertiary.withValues(alpha: 0.15),
                        colors.tertiary,
                      ),

                    // Pages
                    if (book.pages != null)
                      _buildChip(
                        '${book.pages} pág',
                        Colors.transparent,
                        colors.onSurfaceVariant,
                      ),
                  ],
                ),

                // Progress bar for in-progress books
                if (book.status == BookStatus.inProgress &&
                    book.pages != null &&
                    book.pages! > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.progress,
                            backgroundColor: colors.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${book.currentPage}/${book.pages}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Rating
                if (book.rating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final starValue = (index + 1) * 10;
                        final color = const Color(0xFFFFB800);
                        if (book.rating! >= starValue) {
                          return Icon(Icons.star, color: color, size: 16);
                        } else if (book.rating! >= starValue - 5) {
                          return Icon(Icons.star_half, color: color, size: 16);
                        } else {
                          return Icon(
                            Icons.star_border,
                            color: color.withValues(alpha: 0.5),
                            size: 16,
                          );
                        }
                      }),
                      const SizedBox(width: 6),
                      Text(
                        (book.rating! / 10).toStringAsFixed(1),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context, Color statusColor) {
    return Container(
      width: 70,
      height: 105,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildCoverContent(context, statusColor),
      ),
    );
  }

  Widget _buildCoverContent(BuildContext context, Color statusColor) {
    if (book.coverPath != null) {
      final file = File(book.coverPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderCover(statusColor),
        );
      }
    }

    return _buildPlaceholderCover(statusColor);
  }

  Widget _buildPlaceholderCover(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        ),
      ),
      child: Center(child: Icon(Icons.menu_book, color: color, size: 28)),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (book.status) {
      case BookStatus.inProgress:
        return colors.primary;
      case BookStatus.forLater:
        return colors.secondary;
      case BookStatus.read:
        return const Color(0xFF10B981); // Success Green
      case BookStatus.unfinished:
        return colors.error;
    }
  }

  String _getStatusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (book.status) {
      case BookStatus.inProgress:
        return l10n.reading;
      case BookStatus.forLater:
        return l10n.toRead;
      case BookStatus.read:
        return l10n.read;
      case BookStatus.unfinished:
        return l10n.abandoned;
    }
  }

  String _getFormatLabel() {
    switch (book.bookFormat) {
      case BookFormat.paperback:
        return '📖 Físico';
      case BookFormat.hardcover:
        return '📕 Capa Dura';
      case BookFormat.ebook:
        return '📱 E-book';
      case BookFormat.audiobook:
        return '🎧 Audiobook';
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/library/data/synced_book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/library/presentation/add_book_screen.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  // Reading timer
  Timer? _readingTimer;
  int _currentSessionSeconds = 0;
  bool _isReading = false;
  DateTime? _sessionStartTime;

  @override
  void dispose() {
    _stopReadingTimer();
    super.dispose();
  }

  void _startReadingTimer(Book book) {
    if (_isReading) return;
    
    setState(() {
      _isReading = true;
      _sessionStartTime = DateTime.now();
    });
    
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSessionSeconds++;
      });
    });
    
    HapticFeedback.mediumImpact();
    FeedbackService.showInfo(context, '📖 Sessão de leitura iniciada!');
  }

  void _stopReadingTimer() {
    _readingTimer?.cancel();
    _readingTimer = null;
  }

  Future<void> _pauseAndSaveReading(Book book) async {
    if (!_isReading || _sessionStartTime == null) return;
    
    _stopReadingTimer();
    
    final bookRepo = ref.read(syncedBookRepositoryProvider);
    final timeRepo = ref.read(syncedTimeTrackingRepositoryProvider);
    final now = DateTime.now();
    
    // 1. Update book's total reading time
    await bookRepo.addReadingTime(book.id, _currentSessionSeconds);
    
    // 2. Create TimeTrackingRecord for the log
    final readingRecord = TimeTrackingRecord(
      id: now.millisecondsSinceEpoch.toString(),
      activityName: '📖 Leitura: ${book.title}',
      iconCode: Icons.menu_book.codePoint,
      startTime: _sessionStartTime!,
      endTime: now,
      duration: Duration(seconds: _currentSessionSeconds),
      notes: 'Sessão de leitura - ${book.author}',
      category: 'Leitura',
      project: book.title,
      isCompleted: true,
      colorValue: UltravioletColors.accentGreen.toARGB32(),
    );
    
    await timeRepo.addTimeTrackingRecord(readingRecord);
    
    final duration = _formatDuration(_currentSessionSeconds);
    
    setState(() {
      _isReading = false;
      _currentSessionSeconds = 0;
      _sessionStartTime = null;
    });
    
    HapticFeedback.mediumImpact();
    FeedbackService.showSuccess(context, '⏱️ Sessão salva: $duration');
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(syncedBookRepositoryProvider);
    
    return ValueListenableBuilder(
      valueListenable: repo.box.listenable(keys: [widget.bookId]),
      builder: (context, Box<Book> box, _) {
        final book = box.get(widget.bookId);
        
        if (book == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            body: Center(
              child: Text(AppLocalizations.of(context)!.livroNaoEncontrado),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // App Bar with cover
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                actions: [
                  IconButton(
                    icon: Icon(
                      book.favourite ? Icons.favorite : Icons.favorite_border,
                      color: book.favourite ? Colors.red : null,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await repo.toggleFavourite(book.id);
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, book),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                      PopupMenuItem(value: 'share', child: Text(AppLocalizations.of(context)!.compartilhar)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getStatusColor(book).withValues(alpha: 0.3),
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      // Cover
                      SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Hero(
                              tag: 'book_cover_${book.id}',
                              child: Container(
                                width: 160,
                                height: 240,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildCover(book),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Book content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and author
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (book.subtitle != null && book.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          book.subtitle!,
                          style: const TextStyle(
                            color: UltravioletColors.onSurfaceVariant,
                            fontSize: 16,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            book.author,
                            style: const TextStyle(
                              color: UltravioletColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      if (book.rating != null)
                        Center(child: _buildRating(book.rating!)),
                      const SizedBox(height: 24),

                      // Status and progress
                      _buildStatusCard(book),
                      const SizedBox(height: 16),

                      // Reading Timer (for in-progress books)
                      if (book.status == BookStatus.inProgress)
                        _ReadingTimerCard(
                          book: book,
                          isReading: _isReading,
                          currentSessionSeconds: _currentSessionSeconds,
                          formatDuration: _formatDuration,
                          onStart: () => _startReadingTimer(book),
                          onPause: () => _pauseAndSaveReading(book),
                        ),
                      const SizedBox(height: 20),

                      // Info chips
                      _buildInfoChips(book),
                      const SizedBox(height: 32),

                      // Reading dates
                      if (book.readings.isNotEmpty)
                        _buildReadingDates(book),

                      // Highlights / Best Quotes
                      if (book.highlights != null && book.highlights!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('✨ Melhores Trechos'),
                        const SizedBox(height: 12),
                        OdysseyCard(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.amber.withValues(alpha: 0.1),
                          borderColor: Colors.amber.withValues(alpha: 0.3),
                          child: Text(
                            book.highlights!,
                            style: const TextStyle(
                              color: UltravioletColors.onSurface,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      // Description
                      if (book.description != null && book.description!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Sinopse'),
                        const SizedBox(height: 12),
                        Text(
                          book.description!,
                          style: const TextStyle(
                            color: UltravioletColors.onSurfaceVariant,
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ],

                      // Notes
                      if (book.notes != null && book.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle(AppLocalizations.of(context)!.notes),
                        const SizedBox(height: 12),
                        OdysseyCard(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                          child: Text(
                            book.notes!,
                            style: const TextStyle(
                              color: UltravioletColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // My review
                      if (book.myReview != null && book.myReview!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Minha Resenha'),
                        const SizedBox(height: 12),
                        OdysseyCard(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: UltravioletColors.primary.withValues(alpha: 0.1),
                          borderColor: UltravioletColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            book.myReview!,
                            style: const TextStyle(
                              color: UltravioletColors.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // Tags
                      if (book.tagsList.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Tags'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: book.tagsList.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: UltravioletColors.tertiary.withValues(alpha: 0.15),
                              labelStyle: const TextStyle(color: UltravioletColors.tertiary),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: book.status == BookStatus.inProgress
              ? FloatingActionButton.extended(
                  onPressed: () => _showProgressDialog(book),
                  backgroundColor: UltravioletColors.primary,
                  icon: const Icon(Icons.bookmark_added, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.atualizarProgresso, style: const TextStyle(color: Colors.white)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: UltravioletColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCover(Book book) {
    if (book.coverPath != null) {
      final file = File(book.coverPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    final color = _getStatusColor(book);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          color: color,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildRating(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            final starValue = (index + 1) * 10;
            if (rating >= starValue) {
              return const Icon(Icons.star_rounded, color: Colors.amber, size: 24);
            } else if (rating >= starValue - 5) {
              return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 24);
            } else {
              return Icon(Icons.star_border_rounded, color: Colors.amber.withValues(alpha: 0.5), size: 24);
            }
          }),
          const SizedBox(width: 8),
          Text(
            (rating / 10).toStringAsFixed(1),
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Book book) {
    final color = _getStatusColor(book);
    final label = _getStatusLabel(book.status);

    return OdysseyCard(
      padding: const EdgeInsets.all(20),
      gradientColors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
      borderColor: color.withValues(alpha: 0.3),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status badge - tappable to change
              GestureDetector(
                onTap: () => _showStatusPicker(book),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              if (book.pages != null)
                Text(
                  '${book.currentPage} de ${book.pages} páginas',
                  style: const TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          
          // Total reading time
          if (book.totalReadingTimeSeconds > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: UltravioletColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Tempo de leitura: ${book.formattedReadingTime}',
                  style: const TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          
          if (book.status == BookStatus.inProgress && book.pages != null && book.pages! > 0) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: book.progress,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(book.progress * 100).toInt()}% concluído',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusPicker(Book book) {
    final repo = ref.read(syncedBookRepositoryProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mover para...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...BookStatus.values.map((status) {
                final isSelected = book.status == status;
                final color = _getStatusColorFromStatus(status);
                final label = _getStatusLabel(status);
                final icon = _getStatusIcon(status);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: isSelected ? null : () async {
                      Navigator.pop(context);
                      await repo.changeStatus(book.id, status);
                      HapticFeedback.mediumImpact();
                      FeedbackService.showSuccess(
                        context, 
                        '📚 Movido para "$label"',
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? color.withValues(alpha: 0.2) 
                            : UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                            ? Border.all(color: color, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColorFromStatus(BookStatus status) {
    switch (status) {
      case BookStatus.inProgress:
        return UltravioletColors.primary;
      case BookStatus.forLater:
        return UltravioletColors.secondary;
      case BookStatus.read:
        return UltravioletColors.accentGreen;
      case BookStatus.unfinished:
        return UltravioletColors.error;
    }
  }

  IconData _getStatusIcon(BookStatus status) {
    switch (status) {
      case BookStatus.forLater:
        return Icons.bookmark_outline;
      case BookStatus.inProgress:
        return Icons.auto_stories_outlined;
      case BookStatus.read:
        return Icons.check_circle_outline;
      case BookStatus.unfinished:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildInfoChips(Book book) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (book.genre != null)
          _buildChip(book.genre!, Icons.category_outlined, UltravioletColors.tertiary),
        _buildChip(_getFormatLabel(book.bookFormat), Icons.book_outlined, UltravioletColors.secondary),
        if (book.publicationYear != null)
          _buildChip(book.publicationYear.toString(), Icons.calendar_today_outlined, UltravioletColors.onSurfaceVariant),
        if (book.isbn != null)
          _buildChip('ISBN: ${book.isbn}', Icons.qr_code, UltravioletColors.onSurfaceVariant),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingDates(Book book) {
    return _ReadingHistorySection(book: book);
  }

  void _handleMenuAction(String action, Book book) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddBookScreen(bookToEdit: book),
          ),
        );
        break;
      case 'share':
        // TODO: Implement share
        FeedbackService.showInfo(context, 'Em breve: Compartilhar');
        break;
      case 'delete':
        _confirmDelete(book);
        break;
    }
  }

  void _confirmDelete(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UltravioletColors.surface,
        title: Text(AppLocalizations.of(context)!.excluirLivro),
        content: Text(AppLocalizations.of(context)!.confirmDeleteBook(book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              final repo = ref.read(syncedBookRepositoryProvider);
              await repo.deleteBook(book.id);
              FeedbackService.showWarning(context, 'Livro removido');
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog(Book book) {
    int currentPage = book.currentPage;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.atualizarProgresso,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (currentPage >= 10) {
                        setModalState(() => currentPage -= 10);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$currentPage',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: UltravioletColors.primary,
                    ),
                  ),
                  Text(
                    ' / ${book.pages ?? 0}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: UltravioletColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      if (book.pages == null || currentPage < book.pages!) {
                        setModalState(() => currentPage += 10);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (book.pages != null && book.pages! > 0)
                Slider(
                  value: currentPage.toDouble().clamp(0, book.pages!.toDouble()),
                  min: 0,
                  max: book.pages!.toDouble(),
                  onChanged: (value) => setModalState(() => currentPage = value.toInt()),
                  activeColor: UltravioletColors.primary,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(syncedBookRepositoryProvider);
                    await repo.updateProgress(book.id, currentPage);
                    Navigator.pop(context);
                    
                    if (book.pages != null && currentPage >= book.pages!) {
                      FeedbackService.showAchievement(
                        context,
                        '📖 Livro Finalizado!',
                        'Parabéns por concluir "${book.title}"',
                      );
                    } else {
                      FeedbackService.showSuccess(
                        context,
                        '📚 Progresso atualizado!',
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(Book book) {
    switch (book.status) {
      case BookStatus.inProgress:
        return UltravioletColors.primary;
      case BookStatus.forLater:
        return UltravioletColors.secondary;
      case BookStatus.read:
        return UltravioletColors.accentGreen;
      case BookStatus.unfinished:
        return UltravioletColors.error;
    }
  }

  String _getStatusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.inProgress:
        return AppLocalizations.of(context)!.reading;
      case BookStatus.forLater:
        return 'Para Ler';
      case BookStatus.read:
        return AppLocalizations.of(context)!.read;
      case BookStatus.unfinished:
        return AppLocalizations.of(context)!.abandoned;
    }
  }

  String _getFormatLabel(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
        return 'Físico';
      case BookFormat.hardcover:
        return 'Capa Dura';
      case BookFormat.ebook:
        return 'E-book';
      case BookFormat.audiobook:
        return 'Audiobook';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Separate widget for the reading timer card to ensure proper rebuilds
class _ReadingTimerCard extends StatelessWidget {
  final Book book;
  final bool isReading;
  final int currentSessionSeconds;
  final String Function(int) formatDuration;
  final VoidCallback onStart;
  final VoidCallback onPause;

  const _ReadingTimerCard({
    required this.book,
    required this.isReading,
    required this.currentSessionSeconds,
    required this.formatDuration,
    required this.onStart,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return OdysseyCard(
      padding: const EdgeInsets.all(20),
      gradientColors: [
        UltravioletColors.accentGreen.withValues(alpha: 0.15), 
        UltravioletColors.accentGreen.withValues(alpha: 0.05)
      ],
      borderColor: isReading 
          ? UltravioletColors.accentGreen 
          : UltravioletColors.accentGreen.withValues(alpha: 0.3),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isReading ? Icons.menu_book : Icons.play_circle_outline,
                    color: UltravioletColors.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReading ? 'Lendo agora...' : 'Sessão de Leitura',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: UltravioletColors.accentGreen,
                          fontSize: 16,
                        ),
                      ),
                      if (isReading)
                        Text(
                          formatDuration(currentSessionSeconds),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: UltravioletColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Play/Pause button
              GestureDetector(
                onTap: isReading ? onPause : onStart,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isReading 
                        ? Colors.orange 
                        : UltravioletColors.accentGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isReading ? Colors.orange : UltravioletColors.accentGreen)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isReading ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (!isReading) ...[
            const SizedBox(height: 12),
            const Text(
              'Toque no play para iniciar a sessão de leitura',
              style: TextStyle(
                color: UltravioletColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying reading history with sessions
class _ReadingHistorySection extends ConsumerStatefulWidget {
  final Book book;

  const _ReadingHistorySection({required this.book});

  @override
  ConsumerState<_ReadingHistorySection> createState() => _ReadingHistorySectionState();
}

class _ReadingHistorySectionState extends ConsumerState<_ReadingHistorySection> {
  bool _isExpanded = false;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
    
    // Get reading sessions for this book from TimeTrackingRepository
    final readingSessions = timeRepo.box.values
        .cast<TimeTrackingRecord>()
        .where((r) => r.category == 'Leitura' && r.project == widget.book.title)
        .toList();
    
    // Sort by date descending
    readingSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    // Calculate total reading time from sessions
    final totalSessionTime = readingSessions.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    
    final hasReadingPeriods = widget.book.readings.isNotEmpty;
    final hasSessions = readingSessions.isNotEmpty;
    
    if (!hasReadingPeriods && !hasSessions) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: UltravioletColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Histórico de Leitura',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Summary badge
              if (hasSessions)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: UltravioletColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${readingSessions.length} sessões',
                    style: const TextStyle(
                      color: UltravioletColors.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: UltravioletColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Summary card (always visible)
        OdysseyCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: 16,
          child: Row(
            children: [
              // Total time
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.timer_outlined, color: UltravioletColors.accentGreen, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(totalSessionTime),
                      style: const TextStyle(
                        color: UltravioletColors.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Tempo total',
                      style: TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: UltravioletColors.outline.withValues(alpha: 0.2),
              ),
              // Sessions count
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.history, color: UltravioletColors.primary, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${readingSessions.length}',
                      style: const TextStyle(
                        color: UltravioletColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.sessions,
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasReadingPeriods) ...[
                Container(
                  width: 1,
                  height: 40,
                  color: UltravioletColors.outline.withValues(alpha: 0.2),
                ),
                // Reading periods
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book, color: UltravioletColors.secondary, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.book.readings.length}',
                        style: const TextStyle(
                          color: UltravioletColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Leituras',
                        style: TextStyle(
                          color: UltravioletColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Expandable details
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Reading sessions
              if (hasSessions) ...[
                const Text(
                  '📖 Sessões de Leitura',
                  style: TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...readingSessions.take(10).map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: UltravioletColors.accentGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UltravioletColors.accentGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: UltravioletColors.accentGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: UltravioletColors.accentGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(session.startTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                                  style: const TextStyle(
                                    color: UltravioletColors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: UltravioletColors.accentGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(session.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (readingSessions.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${readingSessions.length - 10} sessões anteriores',
                      style: const TextStyle(
                        color: UltravioletColors.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              
              // Reading periods (start/finish dates)
              if (hasReadingPeriods) ...[
                const SizedBox(height: 16),
                const Text(
                  '📅 Períodos de Leitura',
                  style: TextStyle(
                    color: UltravioletColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.book.readings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reading = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: UltravioletColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UltravioletColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: UltravioletColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: UltravioletColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (reading.startDate != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.play_arrow_rounded, size: 14, color: UltravioletColors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Início: ${_formatDate(reading.startDate!)}',
                                        style: const TextStyle(
                                          color: UltravioletColors.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (reading.finishDate != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: UltravioletColors.accentGreen),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Término: ${_formatDate(reading.finishDate!)}',
                                        style: const TextStyle(
                                          color: UltravioletColors.accentGreen,
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
                    ),
                  );
                }),
              ],
            ],
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

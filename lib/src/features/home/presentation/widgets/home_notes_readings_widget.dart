// lib/src/features/home/presentation/widgets/home_notes_readings_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';

/// Widget de acesso rápido a Notas e Leituras
///
/// Exibe dois pills horizontais mostrando:
/// - Contagem de notas com navegação para NotesScreen
/// - Contagem de livros em leitura com navegação para LibraryScreen
class HomeNotesReadingsWidget extends StatelessWidget {
  const HomeNotesReadingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildNotesPill(context)),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 32,
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildReadingsPill(context)),
        ],
      ),
    );
  }

  Widget _buildNotesPill(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.openBox('notes'),
      builder: (context, snapshot) {
        int noteCount = 0;
        if (snapshot.hasData) {
          noteCount = snapshot.data!.length;
        }

        return _PillItem(
          label: 'Notas',
          count: noteCount.toString(),
          icon: Icons.sticky_note_2_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildReadingsPill(BuildContext context) {
    return FutureBuilder<Box<Book>>(
      future: _openBooksBox(),
      builder: (context, snapshot) {
        int readingCount = 0;
        if (snapshot.hasData) {
          final box = snapshot.data!;
          readingCount = box.values
              .where((b) => b.status == BookStatus.inProgress)
              .length;
        }

        return _PillItem(
          label: 'Lendo',
          count: readingCount.toString(),
          icon: Icons.menu_book_rounded,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            );
          },
        );
      },
    );
  }

  Future<Box<Book>> _openBooksBox() async {
    if (!Hive.isAdapterRegistered(BookAdapter().typeId)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(ReadingPeriodAdapter().typeId)) {
      Hive.registerAdapter(ReadingPeriodAdapter());
    }
    if (Hive.isBoxOpen('books_v3')) {
      return Hive.box<Book>('books_v3');
    }
    return await Hive.openBox<Book>('books_v3');
  }
}

/// Item pill individual para notas/leituras
class _PillItem extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

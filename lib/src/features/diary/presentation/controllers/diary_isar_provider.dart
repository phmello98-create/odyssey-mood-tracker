import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/diary_entry_isar.dart';
import '../../data/repositories/diary_isar_repository.dart';

final diaryIsarStreamProvider =
    StreamProvider.autoDispose<List<DiaryEntryIsar>>((ref) {
      final repository = ref.watch(diaryIsarRepositoryProvider);
      return repository.watchAll();
    });

// Provider para filtrar favoritos (futuro)
final diaryIsarStarredStreamProvider =
    StreamProvider.autoDispose<List<DiaryEntryIsar>>((ref) {
      final repository = ref.read(diaryIsarRepositoryProvider);
      // Isar repo watchAll já retorna todos, filtrar no client ou criar query especifica no repo
      // Vou criar um provider filtrado no client por enquanto para simplificar
      return repository.watchAll().map(
        (list) => list.where((e) => e.isStarred).toList(),
      );
    });

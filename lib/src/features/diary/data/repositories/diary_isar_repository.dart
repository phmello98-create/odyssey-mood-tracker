import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/data/isar_service.dart';
import '../models/diary_entry_isar.dart';

// Provider global do repositório Isar
final diaryIsarRepositoryProvider = Provider<DiaryIsarRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return DiaryIsarRepository(isar);
});

class DiaryIsarRepository {
  final Isar _isar;

  DiaryIsarRepository(this._isar);

  // Criar ou Atualizar
  Future<int> saveEntry(DiaryEntryIsar entry) async {
    return _isar.writeTxn(() async {
      return await _isar.diaryEntryIsars.put(entry);
    });
  }

  // Ler todos
  Future<List<DiaryEntryIsar>> getAll({int limit = 50, int offset = 0}) async {
    return _isar.diaryEntryIsars
        .where()
        .sortByEntryDateDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  // Observar todos (Reactive)
  Stream<List<DiaryEntryIsar>> watchAll() {
    return _isar.diaryEntryIsars.where().sortByEntryDateDesc().watch(
      fireImmediately: true,
    );
  }

  // Buscar por ID
  Future<DiaryEntryIsar?> getById(int id) async {
    return _isar.diaryEntryIsars.get(id);
  }

  // Buscar por Texto (Full Text simplificado)
  Future<List<DiaryEntryIsar>> search(String query) async {
    if (query.isEmpty) return getAll();

    return _isar.diaryEntryIsars
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .searchableTextContains(query, caseSensitive: false)
        .or()
        .tagsElementContains(query, caseSensitive: false)
        .sortByEntryDateDesc()
        .findAll();
  }

  // Filtrar Favoritos
  Future<List<DiaryEntryIsar>> getStarred() async {
    return _isar.diaryEntryIsars
        .filter()
        .isStarredEqualTo(true)
        .sortByEntryDateDesc()
        .findAll();
  }

  // Deletar
  Future<bool> delete(int id) async {
    return _isar.writeTxn(() async {
      return await _isar.diaryEntryIsars.delete(id);
    });
  }

  // Toggle Star
  Future<void> toggleStar(int id) async {
    final entry = await getById(id);
    if (entry != null) {
      entry.isStarred = !entry.isStarred;
      await saveEntry(entry);
    }
  }

  // Get Count
  Future<int> count() async {
    return _isar.diaryEntryIsars.count();
  }
}

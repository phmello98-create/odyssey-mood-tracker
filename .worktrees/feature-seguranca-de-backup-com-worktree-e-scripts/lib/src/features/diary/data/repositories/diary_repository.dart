import 'package:hive/hive.dart';
import '../models/diary_entry.dart';

/// Repository para gerenciar entradas de diário usando Hive
class DiaryRepository {
  static const String _boxName = 'diary_entries';
  Box<DiaryEntry>? _box;

  /// Inicializa o Hive box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<DiaryEntry>(_boxName);
    }
  }

  /// Garante que o box está aberto
  Future<Box<DiaryEntry>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Retorna todas as entradas de diário, ordenadas por data (mais recentes primeiro)
  Future<List<DiaryEntry>> getAllEntries() async {
    final box = await _getBox();
    final entries = box.values.toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna entradas de um ano específico
  Future<List<DiaryEntry>> getEntriesByYear(int year) async {
    final box = await _getBox();
    final entries = box.values
        .where((entry) => entry.entryDate.year == year)
        .toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna uma entrada específica por ID
  Future<DiaryEntry?> getEntry(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  /// Busca entradas por texto (busca em título e conteúdo)
  Future<List<DiaryEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) {
      return getAllEntries();
    }

    final box = await _getBox();
    final lowerQuery = query.toLowerCase();

    final entries = box.values.where((entry) {
      final titleMatch =
          entry.title?.toLowerCase().contains(lowerQuery) ?? false;
      final contentMatch =
          entry.searchableText?.toLowerCase().contains(lowerQuery) ?? false;
      return titleMatch || contentMatch;
    }).toList();

    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna entradas marcadas como favoritas
  Future<List<DiaryEntry>> getStarredEntries() async {
    final box = await _getBox();
    final entries = box.values.where((entry) => entry.starred).toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna entradas com um sentimento específico
  Future<List<DiaryEntry>> getEntriesByFeeling(String feeling) async {
    final box = await _getBox();
    final entries =
        box.values.where((entry) => entry.feeling == feeling).toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna entradas com uma tag específica
  Future<List<DiaryEntry>> getEntriesByTag(String tag) async {
    final box = await _getBox();
    final entries =
        box.values.where((entry) => entry.tags.contains(tag)).toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Retorna entradas de uma data específica
  Future<List<DiaryEntry>> getEntriesByDate(DateTime date) async {
    final box = await _getBox();
    final entries = box.values.where((entry) {
      return entry.entryDate.year == date.year &&
          entry.entryDate.month == date.month &&
          entry.entryDate.day == date.day;
    }).toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  /// Cria ou atualiza uma entrada
  Future<void> saveEntry(DiaryEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, entry);
  }

  /// Deleta uma entrada
  Future<void> deleteEntry(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// Alterna o status de favorito de uma entrada
  Future<void> toggleStarred(String id) async {
    final box = await _getBox();
    final entry = box.get(id);
    if (entry != null) {
      final updated = entry.copyWith(
        starred: !entry.starred,
        updatedAt: DateTime.now(),
      );
      await box.put(id, updated);
    }
  }

  /// Retorna a contagem total de entradas
  Future<int> getEntriesCount() async {
    final box = await _getBox();
    return box.length;
  }

  /// Retorna todas as tags únicas usadas
  Future<List<String>> getAllTags() async {
    final box = await _getBox();
    final allTags = <String>{};
    for (final entry in box.values) {
      allTags.addAll(entry.tags);
    }
    return allTags.toList()..sort();
  }

  /// Fecha o box (chamar ao fechar o app)
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}

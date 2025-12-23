import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/notes/domain/quote.dart';
import '../../features/diary/data/models/diary_entry_isar.dart';

final isarServiceProvider = Provider<Isar>((ref) {
  return IsarService.instance;
});

class IsarService {
  static Isar? _instance;

  static Future<Isar> init() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open([
      QuoteSchema,
      DiaryEntryIsarSchema,
    ], directory: dir.path);
    return _instance!;
  }

  // Compatibilidade com código antigo
  static Future<Isar> getInstance() => init();

  static Isar get instance {
    if (_instance == null) {
      throw StateError('Isar not initialized. Call init() first.');
    }
    return _instance!;
  }
}

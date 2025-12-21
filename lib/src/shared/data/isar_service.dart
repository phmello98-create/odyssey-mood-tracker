import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/notes/domain/quote.dart';

class IsarService {
  static Isar? _instance;

  static Future<Isar> getInstance() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open([QuoteSchema], directory: dir.path);
    return _instance!;
  }
}

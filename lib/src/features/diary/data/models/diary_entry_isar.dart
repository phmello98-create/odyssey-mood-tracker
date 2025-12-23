import 'package:isar/isar.dart';

part 'diary_entry_isar.g.dart';

@collection
class DiaryEntryIsar {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late DateTime entryDate;

  @Index(type: IndexType.value)
  late DateTime createdAt;

  late DateTime updatedAt;

  String? title;

  // Conteúdo em JSON (Delta do Quill)
  String? content;

  // Texto puro para busca full-text
  @Index(type: IndexType.value, caseSensitive: false)
  String? searchableText;

  String? feeling;

  List<String> tags = [];

  bool isStarred = false;

  // Caminho da imagem anexada (opcional)
  String? imagePath;

  // Metadata para sincronização futura (opcional)
  String? cloudId;
  bool isSynced = false;
}

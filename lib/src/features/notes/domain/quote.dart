import 'package:isar/isar.dart';

part 'quote.g.dart';

@collection
class Quote {
  Id id = Isar.autoIncrement;

  @Index()
  late String text;

  @Index()
  late String author;

  String? category;

  bool isFavorite = false;

  late DateTime createdAt;

  String? source;
}

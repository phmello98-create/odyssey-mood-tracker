import 'package:hive/hive.dart';

part 'suggestion_analytics.g.dart';

@HiveType(typeId: 17)
class SuggestionAnalytics extends HiveObject {
  @HiveField(0)
  final String suggestionId;

  @HiveField(1)
  bool isMarked; // Estrela marcada (favorito)

  @HiveField(2)
  bool isAdded; // Foi adicionado como hábito/tarefa

  @HiveField(3)
  DateTime? addedAt;

  @HiveField(4)
  DateTime? markedAt;

  @HiveField(5)
  int viewCount; // Quantas vezes visualizou

  @HiveField(6)
  DateTime? lastViewedAt;

  SuggestionAnalytics({
    required this.suggestionId,
    this.isMarked = false,
    this.isAdded = false,
    this.addedAt,
    this.markedAt,
    this.viewCount = 0,
    this.lastViewedAt,
  });

  void markAsFavorite() {
    isMarked = true;
    markedAt = DateTime.now();
    save();
  }

  void unmarkAsFavorite() {
    isMarked = false;
    markedAt = null;
    save();
  }

  void markAsAdded() {
    isAdded = true;
    addedAt = DateTime.now();
    save();
  }

  void unmarkAsAdded() {
    isAdded = false;
    addedAt = null;
    save();
  }

  void incrementViewCount() {
    viewCount++;
    lastViewedAt = DateTime.now();
    save();
  }
}

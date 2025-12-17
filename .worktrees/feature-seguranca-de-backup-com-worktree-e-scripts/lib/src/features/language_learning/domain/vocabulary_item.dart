import 'package:hive_flutter/hive_flutter.dart';

part 'vocabulary_item.g.dart';

@HiveType(typeId: 22)
class VocabularyItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String languageId;

  @HiveField(2)
  final String word;

  @HiveField(3)
  final String translation;

  @HiveField(4)
  final String? pronunciation; // IPA or simple phonetic

  @HiveField(5)
  final String? exampleSentence;

  @HiveField(6)
  final String? exampleTranslation;

  @HiveField(7)
  final String status; // learning, reviewing, mastered

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? lastReviewedAt;

  @HiveField(10)
  final DateTime? nextReviewAt; // For spaced repetition

  @HiveField(11)
  final int reviewCount;

  @HiveField(12)
  final int correctCount;

  @HiveField(13)
  final String? category; // nouns, verbs, phrases, etc.

  @HiveField(14)
  final String? notes;

  VocabularyItem({
    required this.id,
    required this.languageId,
    required this.word,
    required this.translation,
    this.pronunciation,
    this.exampleSentence,
    this.exampleTranslation,
    this.status = 'learning',
    required this.createdAt,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.category,
    this.notes,
  });

  VocabularyItem copyWith({
    String? id,
    String? languageId,
    String? word,
    String? translation,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    String? status,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? reviewCount,
    int? correctCount,
    String? category,
    String? notes,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  double get accuracy {
    if (reviewCount == 0) return 0;
    return correctCount / reviewCount;
  }

  bool get needsReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  // Calcular próxima data de revisão baseado em spaced repetition simples
  DateTime calculateNextReview(bool wasCorrect) {
    final now = DateTime.now();
    int daysUntilNext;

    if (!wasCorrect) {
      daysUntilNext = 1; // Review tomorrow
    } else {
      // Exponential backoff: 1, 2, 4, 7, 14, 30 days
      final successStreak = correctCount + 1;
      if (successStreak <= 1) {
        daysUntilNext = 1;
      } else if (successStreak <= 2) daysUntilNext = 2;
      else if (successStreak <= 3) daysUntilNext = 4;
      else if (successStreak <= 4) daysUntilNext = 7;
      else if (successStreak <= 5) daysUntilNext = 14;
      else daysUntilNext = 30;
    }

    return now.add(Duration(days: daysUntilNext));
  }
}

// Status possíveis para vocabulário
class VocabularyStatus {
  static const String learning = 'learning';
  static const String reviewing = 'reviewing';
  static const String mastered = 'mastered';

  static String getDisplayName(String status) {
    switch (status) {
      case learning: return 'Aprendendo';
      case reviewing: return 'Revisando';
      case mastered: return 'Dominado';
      default: return 'Aprendendo';
    }
  }

  static int getColor(String status) {
    switch (status) {
      case learning: return 0xFFF59E0B; // Amber
      case reviewing: return 0xFF3B82F6; // Blue
      case mastered: return 0xFF10B981; // Green
      default: return 0xFFF59E0B;
    }
  }
}

// Categorias de vocabulário
class VocabularyCategories {
  static const List<String> all = [
    'Substantivos',
    'Verbos',
    'Adjetivos',
    'Advérbios',
    'Frases',
    'Expressões',
    'Gírias',
    'Técnico',
    'Viagem',
    'Comida',
    'Trabalho',
    'Outro',
  ];
}

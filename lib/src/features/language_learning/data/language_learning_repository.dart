import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/language_learning/domain/language.dart';
import 'package:odyssey/src/features/language_learning/domain/study_session.dart';
import 'package:odyssey/src/features/language_learning/domain/vocabulary_item.dart';
import 'package:odyssey/src/features/language_learning/domain/immersion_log.dart';

final languageLearningRepositoryProvider = Provider<LanguageLearningRepository>(
  (ref) {
    return LanguageLearningRepository();
  },
);

class LanguageLearningRepository {
  static const String _languagesBoxName = 'languages';
  static const String _sessionsBoxName = 'study_sessions';
  static const String _vocabularyBoxName = 'vocabulary_items';

  late Box<Language> _languagesBox;
  late Box<StudySession> _sessionsBox;
  late Box<VocabularyItem> _vocabularyBox;
  bool _isInitialized = false;

  Box<Language> get languagesBox => _languagesBox;
  Box<StudySession> get sessionsBox => _sessionsBox;
  Box<VocabularyItem> get vocabularyBox => _vocabularyBox;

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

  Future<void> init() async {
    if (_isInitialized) return;

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(LanguageAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(StudySessionAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(VocabularyItemAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(ImmersionLogAdapter());
    }

    _languagesBox = await Hive.openBox<Language>(_languagesBoxName);
    _sessionsBox = await Hive.openBox<StudySession>(_sessionsBoxName);
    _vocabularyBox = await Hive.openBox<VocabularyItem>(_vocabularyBoxName);

    _isInitialized = true;
    debugPrint('✅ LanguageLearningRepository initialized');
  }

  // ==================== LANGUAGES ====================

  List<Language> getAllLanguages() {
    final languages = _languagesBox.values.toList();
    languages.sort((a, b) => a.order.compareTo(b.order));
    return languages;
  }

  Language? getLanguage(String id) {
    return _languagesBox.get(id);
  }

  Future<void> addLanguage(Language language) async {
    await _languagesBox.put(language.id, language);
  }

  Future<Language> createLanguage({
    required String name,
    required String flag,
    required int colorValue,
    String level = 'A1',
    String? notes,
  }) async {
    final id = _generateId();
    final order = _languagesBox.length;
    final language = Language(
      id: id,
      name: name,
      flag: flag,
      colorValue: colorValue,
      level: level,
      notes: notes,
      createdAt: DateTime.now(),
      order: order,
    );
    await _languagesBox.put(id, language);
    return language;
  }

  Future<void> updateLanguage(Language language) async {
    await _languagesBox.put(language.id, language);
  }

  Future<void> deleteLanguage(String id) async {
    // Delete all sessions and vocabulary for this language
    final sessionsToDelete = _sessionsBox.values
        .where((s) => s.languageId == id)
        .toList();
    for (final session in sessionsToDelete) {
      await _sessionsBox.delete(session.id);
    }

    final vocabToDelete = _vocabularyBox.values
        .where((v) => v.languageId == id)
        .toList();
    for (final vocab in vocabToDelete) {
      await _vocabularyBox.delete(vocab.id);
    }

    await _languagesBox.delete(id);
  }

  Future<void> reorderLanguages(int oldIndex, int newIndex) async {
    final languages = getAllLanguages();
    final language = languages.removeAt(oldIndex);
    languages.insert(newIndex, language);

    for (int i = 0; i < languages.length; i++) {
      await _languagesBox.put(languages[i].id, languages[i].copyWith(order: i));
    }
  }

  // ==================== STUDY SESSIONS ====================

  List<StudySession> getAllSessions() {
    final sessions = _sessionsBox.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  List<StudySession> getSessionsForLanguage(String languageId) {
    return getAllSessions().where((s) => s.languageId == languageId).toList();
  }

  List<StudySession> getSessionsForDate(DateTime date) {
    return getAllSessions()
        .where(
          (s) =>
              s.startTime.year == date.year &&
              s.startTime.month == date.month &&
              s.startTime.day == date.day,
        )
        .toList();
  }

  List<StudySession> getSessionsForDateRange(DateTime start, DateTime end) {
    return getAllSessions()
        .where(
          (s) =>
              s.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
              s.startTime.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  Future<StudySession> addSession({
    required String languageId,
    required int durationMinutes,
    required String activityType,
    String? notes,
    int? rating,
    String? resource,
  }) async {
    final id = _generateId();
    final session = StudySession(
      id: id,
      languageId: languageId,
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      activityType: activityType,
      notes: notes,
      rating: rating,
      resource: resource,
    );
    await _sessionsBox.put(id, session);

    // Update language stats
    await _updateLanguageStats(languageId, durationMinutes);

    return session;
  }

  Future<void> deleteSession(String id) async {
    final session = _sessionsBox.get(id);
    if (session != null) {
      // Update language stats (subtract time)
      final language = _languagesBox.get(session.languageId);
      if (language != null) {
        await _languagesBox.put(
          language.id,
          language.copyWith(
            totalMinutesStudied:
                (language.totalMinutesStudied - session.durationMinutes).clamp(
                  0,
                  999999,
                ),
          ),
        );
      }
    }
    await _sessionsBox.delete(id);
  }

  Future<void> _updateLanguageStats(String languageId, int minutesAdded) async {
    final language = _languagesBox.get(languageId);
    if (language == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStudied = language.lastStudiedAt;

    int newStreak = language.currentStreak;

    if (lastStudied == null) {
      newStreak = 1;
    } else {
      final lastStudiedDate = DateTime(
        lastStudied.year,
        lastStudied.month,
        lastStudied.day,
      );
      final yesterday = today.subtract(const Duration(days: 1));

      if (lastStudiedDate == today) {
        // Already studied today, streak stays the same
      } else if (lastStudiedDate == yesterday) {
        // Studied yesterday, increment streak
        newStreak = language.currentStreak + 1;
      } else {
        // Missed a day, reset streak
        newStreak = 1;
      }
    }

    final newBestStreak = newStreak > language.bestStreak
        ? newStreak
        : language.bestStreak;

    await _languagesBox.put(
      languageId,
      language.copyWith(
        totalMinutesStudied: language.totalMinutesStudied + minutesAdded,
        lastStudiedAt: now,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
      ),
    );
  }

  // ==================== VOCABULARY ====================

  List<VocabularyItem> getAllVocabulary() {
    return _vocabularyBox.values.toList();
  }

  List<VocabularyItem> getVocabularyForLanguage(String languageId) {
    return _vocabularyBox.values
        .where((v) => v.languageId == languageId)
        .toList();
  }

  List<VocabularyItem> getVocabularyNeedingReview(String languageId) {
    return getVocabularyForLanguage(
      languageId,
    ).where((v) => v.needsReview).toList();
  }

  List<VocabularyItem> getVocabularyByStatus(String languageId, String status) {
    return getVocabularyForLanguage(
      languageId,
    ).where((v) => v.status == status).toList();
  }

  Future<VocabularyItem> addVocabularyItem({
    required String languageId,
    required String word,
    required String translation,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    String? category,
    String? notes,
  }) async {
    final id = _generateId();
    final item = VocabularyItem(
      id: id,
      languageId: languageId,
      word: word,
      translation: translation,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      category: category,
      notes: notes,
      createdAt: DateTime.now(),
      nextReviewAt: DateTime.now().add(const Duration(days: 1)),
    );
    await _vocabularyBox.put(id, item);
    return item;
  }

  Future<void> updateVocabularyItem(VocabularyItem item) async {
    await _vocabularyBox.put(item.id, item);
  }

  Future<void> deleteVocabularyItem(String id) async {
    await _vocabularyBox.delete(id);
  }

  Future<void> reviewVocabularyItem(String id, bool wasCorrect) async {
    final item = _vocabularyBox.get(id);
    if (item == null) return;

    final nextReview = item.calculateNextReview(wasCorrect);
    String newStatus = item.status;

    // Update status based on performance
    if (wasCorrect && item.correctCount >= 5) {
      newStatus = VocabularyStatus.mastered;
    } else if (item.reviewCount >= 2) {
      newStatus = VocabularyStatus.reviewing;
    }

    await _vocabularyBox.put(
      id,
      item.copyWith(
        reviewCount: item.reviewCount + 1,
        correctCount: wasCorrect ? item.correctCount + 1 : item.correctCount,
        lastReviewedAt: DateTime.now(),
        nextReviewAt: nextReview,
        status: newStatus,
      ),
    );
  }

  // ==================== STATISTICS ====================

  int getTotalMinutesStudied() {
    return getAllLanguages().fold(
      0,
      (sum, lang) => sum + lang.totalMinutesStudied,
    );
  }

  int getTotalVocabularyCount() {
    return _vocabularyBox.length;
  }

  int getMasteredVocabularyCount() {
    return _vocabularyBox.values
        .where((v) => v.status == VocabularyStatus.mastered)
        .length;
  }

  Map<String, int> getMinutesPerActivityType(String languageId) {
    final sessions = getSessionsForLanguage(languageId);
    final map = <String, int>{};
    for (final session in sessions) {
      map[session.activityType] =
          (map[session.activityType] ?? 0) + session.durationMinutes;
    }
    return map;
  }

  // Get study minutes for last 7 days
  Map<int, int> getWeeklyStudyMinutes() {
    final now = DateTime.now();
    final result = <int, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final sessions = getSessionsForDate(date);
      result[6 - i] = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    }

    return result;
  }

  // Check if user studied today across all languages
  bool hasStudiedToday() {
    final sessions = getSessionsForDate(DateTime.now());
    return sessions.isNotEmpty;
  }
}

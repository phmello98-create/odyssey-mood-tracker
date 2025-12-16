// lib/src/features/auth/services/sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/library/domain/book.dart';

/// Status de uma operação de sincronização
enum SyncOperationStatus {
  idle,
  syncing,
  success,
  error,
}

/// Resultado de uma operação de sincronização
class SyncResult {
  final bool success;
  final int itemsSynced;
  final String? errorMessage;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.itemsSynced = 0,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncResult.success(int itemsSynced) => SyncResult(
        success: true,
        itemsSynced: itemsSynced,
      );

  factory SyncResult.error(String message) => SyncResult(
        success: false,
        errorMessage: message,
      );
}

/// Serviço de sincronização entre Hive (local) e Firestore (cloud)
class SyncService {
  final FirebaseFirestore _firestore;
  final String userId;

  // Nomes dos boxes Hive
  static const String _moodRecordsBoxName = 'mood_records';
  static const String _tasksBoxName = 'tasks';
  static const String _habitsBoxName = 'habits';
  static const String _notesBoxName = 'notes_v2';
  static const String _quotesBoxName = 'quotes';
  static const String _gamificationBoxName = 'gamification';
  static const String _timeTrackingBoxName = 'time_tracking_records';
  static const String _booksBoxName = 'books_v3';

  // Batch limit do Firestore (máximo 500 operações por batch)
  static const int _batchLimit = 450;

  SyncService({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  // ============================================
  // SYNC MOODS
  // ============================================

  /// Sincroniza mood records locais com o Firestore
  Future<SyncResult> syncMoods() async {
    try {
      final box = await Hive.openBox<MoodRecord>(_moodRecordsBoxName);
      final moods = box.toMap();

      if (moods.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('moods');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final entry in moods.entries) {
        final key = entry.key.toString();
        final mood = entry.value;
        final docRef = collection.doc(key);

        // Converter MoodRecord para Map
        final moodData = _moodRecordToMap(mood, key);
        batch.set(docRef, moodData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        // Commit batch se atingir o limite
        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Commit batch final
      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount mood records');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing moods: $e');
      return SyncResult.error('Erro ao sincronizar humores: $e');
    }
  }

  Map<String, dynamic> _moodRecordToMap(MoodRecord mood, String key) {
    return {
      'id': key,
      'label': mood.label,
      'score': mood.score,
      'iconPath': mood.iconPath,
      'color': mood.color,
      'date': mood.date.toIso8601String(),
      'note': mood.note,
      'activities': mood.activities.map((a) => {
            'activityName': a.activityName,
            'iconCode': a.iconCode,
          }).toList(),
      // Timestamps para resolução de conflitos
      '_localModifiedAt': mood.date.toIso8601String(),
      '_syncedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================
  // SYNC TASKS
  // ============================================

  /// Sincroniza tasks locais com o Firestore
  Future<SyncResult> syncTasks() async {
    try {
      final box = await Hive.openBox(_tasksBoxName);
      
      if (box.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is! Map) continue;

        final taskData = Map<String, dynamic>.from(value);
        taskData['id'] = key.toString();
        taskData['syncedAt'] = FieldValue.serverTimestamp();

        final docRef = collection.doc(key.toString());
        batch.set(docRef, taskData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount tasks');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing tasks: $e');
      return SyncResult.error('Erro ao sincronizar tarefas: $e');
    }
  }

  // ============================================
  // SYNC HABITS
  // ============================================

  /// Sincroniza habits locais com o Firestore
  Future<SyncResult> syncHabits() async {
    try {
      final box = await Hive.openBox<Habit>(_habitsBoxName);
      final habits = box.values.toList();

      if (habits.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('habits');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final habit in habits) {
        final docRef = collection.doc(habit.id);
        final habitData = _habitToMap(habit);
        batch.set(docRef, habitData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount habits');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing habits: $e');
      return SyncResult.error('Erro ao sincronizar hábitos: $e');
    }
  }

  Map<String, dynamic> _habitToMap(Habit habit) {
    // Usar a data mais recente de completedDates ou createdAt como referência
    final latestDate = habit.completedDates.isNotEmpty 
        ? habit.completedDates.reduce((a, b) => a.isAfter(b) ? a : b)
        : habit.createdAt;
    
    return {
      'id': habit.id,
      'name': habit.name,
      'iconCode': habit.iconCode,
      'colorValue': habit.colorValue,
      'scheduledTime': habit.scheduledTime,
      'daysOfWeek': habit.daysOfWeek,
      'completedDates': habit.completedDates.map((d) => d.toIso8601String()).toList(),
      'currentStreak': habit.currentStreak,
      'bestStreak': habit.bestStreak,
      'createdAt': habit.createdAt.toIso8601String(),
      'order': habit.order,
      // Timestamps para resolução de conflitos
      '_localModifiedAt': latestDate.toIso8601String(),
      '_syncedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================
  // SYNC NOTES
  // ============================================

  /// Sincroniza notes locais com o Firestore
  Future<SyncResult> syncNotes() async {
    try {
      final box = await Hive.openBox(_notesBoxName);

      if (box.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is! Map) continue;

        final noteData = Map<String, dynamic>.from(value);
        noteData['id'] = key.toString();
        noteData['syncedAt'] = FieldValue.serverTimestamp();

        final docRef = collection.doc(key.toString());
        batch.set(docRef, noteData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount notes');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing notes: $e');
      return SyncResult.error('Erro ao sincronizar notas: $e');
    }
  }

  // ============================================
  // SYNC QUOTES
  // ============================================

  /// Sincroniza quotes locais com o Firestore
  Future<SyncResult> syncQuotes() async {
    try {
      final box = await Hive.openBox(_quotesBoxName);

      if (box.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('quotes');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is! Map) continue;

        final quoteData = Map<String, dynamic>.from(value);
        quoteData['id'] = key.toString();
        quoteData['syncedAt'] = FieldValue.serverTimestamp();

        final docRef = collection.doc(key.toString());
        batch.set(docRef, quoteData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount quotes');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing quotes: $e');
      return SyncResult.error('Erro ao sincronizar citações: $e');
    }
  }

  // ============================================
  // SYNC GAMIFICATION
  // ============================================

  /// Sincroniza dados de gamificação (stats e skills) com o Firestore
  Future<SyncResult> syncGamification() async {
    try {
      final box = await Hive.openBox(_gamificationBoxName);
      
      final userStatsData = box.get('user_stats');
      final skillsProgressData = box.get('user_skills_progress');
      
      if (userStatsData == null && skillsProgressData == null) {
        return SyncResult.success(0);
      }

      final gamificationDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('data');

      int syncedCount = 0;
      final dataToSync = <String, dynamic>{
        'syncedAt': FieldValue.serverTimestamp(),
      };

      // Sync user stats
      if (userStatsData != null) {
        if (userStatsData is Map) {
          dataToSync['stats'] = Map<String, dynamic>.from(userStatsData);
        }
        syncedCount++;
      }

      // Sync skills progress
      if (skillsProgressData != null) {
        if (skillsProgressData is Map) {
          // Convert nested maps properly
          final skillsMap = <String, dynamic>{};
          for (final entry in (skillsProgressData).entries) {
            final key = entry.key.toString();
            if (entry.value is Map) {
              skillsMap[key] = Map<String, dynamic>.from(entry.value as Map);
            } else {
              skillsMap[key] = entry.value;
            }
          }
          dataToSync['skills'] = skillsMap;
        }
        syncedCount++;
      }

      await gamificationDoc.set(dataToSync, SetOptions(merge: true));

      debugPrint('[SyncService] Synced gamification data (stats + skills)');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing gamification: $e');
      return SyncResult.error('Erro ao sincronizar gamificação: $e');
    }
  }

  // ============================================
  // SYNC TIME TRACKING
  // ============================================

  /// Sincroniza time tracking records locais com o Firestore
  Future<SyncResult> syncTimeTracking() async {
    try {
      final box = await Hive.openBox<TimeTrackingRecord>(_timeTrackingBoxName);
      final records = box.values.toList();

      if (records.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('timeTracking');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final record in records) {
        final docRef = collection.doc(record.id);
        final recordData = _timeTrackingRecordToMap(record);
        batch.set(docRef, recordData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount time tracking records');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing time tracking: $e');
      return SyncResult.error('Erro ao sincronizar time tracking: $e');
    }
  }

  Map<String, dynamic> _timeTrackingRecordToMap(TimeTrackingRecord record) {
    return {
      'id': record.id,
      'activityName': record.activityName,
      'iconCode': record.iconCode,
      'startTime': record.startTime.toIso8601String(),
      'endTime': record.endTime.toIso8601String(),
      'durationInSeconds': record.durationInSeconds,
      'notes': record.notes,
      'category': record.category,
      'project': record.project,
      'isCompleted': record.isCompleted,
      'colorValue': record.colorValue,
      // Timestamps para resolução de conflitos
      '_localModifiedAt': record.endTime.toIso8601String(),
      '_syncedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================
  // SYNC BOOKS
  // ============================================

  /// Sincroniza livros locais com o Firestore
  Future<SyncResult> syncBooks() async {
    try {
      final box = await Hive.openBox<Book>(_booksBoxName);
      final books = box.values.toList();

      if (books.isEmpty) {
        return SyncResult.success(0);
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('books');

      int syncedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final book in books) {
        final docRef = collection.doc(book.id);
        final bookData = _bookToMap(book);
        batch.set(docRef, bookData, SetOptions(merge: true));

        batchCount++;
        syncedCount++;

        if (batchCount >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('[SyncService] Synced $syncedCount books');
      return SyncResult.success(syncedCount);
    } catch (e) {
      debugPrint('[SyncService] Error syncing books: $e');
      return SyncResult.error('Erro ao sincronizar livros: $e');
    }
  }

  Map<String, dynamic> _bookToMap(Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'subtitle': book.subtitle,
      'author': book.author,
      'description': book.description,
      'statusIndex': book.statusIndex,
      'favourite': book.favourite,
      'deleted': book.deleted,
      'rating': book.rating,
      'pages': book.pages,
      'publicationYear': book.publicationYear,
      'isbn': book.isbn,
      'olid': book.olid,
      'tags': book.tags,
      'myReview': book.myReview,
      'notes': book.notes,
      'blurHash': book.blurHash,
      'formatIndex': book.formatIndex,
      'hasCover': book.hasCover,
      'readingsData': book.readingsData,
      'dateAdded': book.dateAdded.toIso8601String(),
      'dateModified': book.dateModified.toIso8601String(),
      'currentPage': book.currentPage,
      'coverPath': book.coverPath,
      'genre': book.genre,
      'highlights': book.highlights,
      'totalReadingTimeSeconds': book.totalReadingTimeSeconds,
      // Timestamps para resolução de conflitos
      '_localModifiedAt': book.dateModified.toIso8601String(),
      '_syncedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================
  // SYNC ALL
  // ============================================

  /// Sincroniza todos os dados locais com o Firestore
  Future<Map<String, SyncResult>> syncAll({
    void Function(String category, SyncOperationStatus status)? onProgress,
  }) async {
    final results = <String, SyncResult>{};

    // Sync moods
    onProgress?.call('moods', SyncOperationStatus.syncing);
    results['moods'] = await syncMoods();
    onProgress?.call('moods', results['moods']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync tasks
    onProgress?.call('tasks', SyncOperationStatus.syncing);
    results['tasks'] = await syncTasks();
    onProgress?.call('tasks', results['tasks']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync habits
    onProgress?.call('habits', SyncOperationStatus.syncing);
    results['habits'] = await syncHabits();
    onProgress?.call('habits', results['habits']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync notes
    onProgress?.call('notes', SyncOperationStatus.syncing);
    results['notes'] = await syncNotes();
    onProgress?.call('notes', results['notes']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync quotes
    onProgress?.call('quotes', SyncOperationStatus.syncing);
    results['quotes'] = await syncQuotes();
    onProgress?.call('quotes', results['quotes']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync gamification
    onProgress?.call('gamification', SyncOperationStatus.syncing);
    results['gamification'] = await syncGamification();
    onProgress?.call('gamification', results['gamification']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync time tracking
    onProgress?.call('timeTracking', SyncOperationStatus.syncing);
    results['timeTracking'] = await syncTimeTracking();
    onProgress?.call('timeTracking', results['timeTracking']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Sync books
    onProgress?.call('books', SyncOperationStatus.syncing);
    results['books'] = await syncBooks();
    onProgress?.call('books', results['books']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    // Update last sync timestamp
    await _updateLastSyncTimestamp();

    return results;
  }

  // ============================================
  // DOWNLOAD FROM FIRESTORE
  // ============================================

  /// Baixa todos os dados do Firestore para o Hive local
  Future<Map<String, SyncResult>> downloadAll({
    void Function(String category, SyncOperationStatus status)? onProgress,
  }) async {
    final results = <String, SyncResult>{};

    onProgress?.call('moods', SyncOperationStatus.syncing);
    results['moods'] = await downloadMoods();
    onProgress?.call('moods', results['moods']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('tasks', SyncOperationStatus.syncing);
    results['tasks'] = await downloadTasks();
    onProgress?.call('tasks', results['tasks']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('habits', SyncOperationStatus.syncing);
    results['habits'] = await downloadHabits();
    onProgress?.call('habits', results['habits']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('notes', SyncOperationStatus.syncing);
    results['notes'] = await downloadNotes();
    onProgress?.call('notes', results['notes']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('quotes', SyncOperationStatus.syncing);
    results['quotes'] = await downloadQuotes();
    onProgress?.call('quotes', results['quotes']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('gamification', SyncOperationStatus.syncing);
    results['gamification'] = await downloadGamification();
    onProgress?.call('gamification', results['gamification']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('timeTracking', SyncOperationStatus.syncing);
    results['timeTracking'] = await downloadTimeTracking();
    onProgress?.call('timeTracking', results['timeTracking']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    onProgress?.call('books', SyncOperationStatus.syncing);
    results['books'] = await downloadBooks();
    onProgress?.call('books', results['books']!.success 
        ? SyncOperationStatus.success 
        : SyncOperationStatus.error);

    return results;
  }

  /// Baixa mood records do Firestore
  Future<SyncResult> downloadMoods() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox<MoodRecord>(_moodRecordsBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final moodRecord = _mapToMoodRecord(data);
        
        // Usa o key numérico se possível, senão usa hash do id
        final key = int.tryParse(doc.id) ?? doc.id.hashCode;
        await box.put(key, moodRecord);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount mood records');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading moods: $e');
      return SyncResult.error('Erro ao baixar humores: $e');
    }
  }

  MoodRecord _mapToMoodRecord(Map<String, dynamic> data) {
    final activities = (data['activities'] as List<dynamic>?)
        ?.map((a) => Activity(
              activityName: a['activityName'] ?? '',
              iconCode: a['iconCode'] ?? 0,
            ))
        .toList() ?? [];

    return MoodRecord(
      label: data['label'] ?? '',
      score: data['score'] ?? 3,
      iconPath: data['iconPath'] ?? '',
      color: data['color'] ?? 0,
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      note: data['note'],
      activities: activities,
    );
  }

  /// Baixa tasks do Firestore
  Future<SyncResult> downloadTasks() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox(_tasksBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        // Remove campos de sync do Firestore
        data.remove('syncedAt');
        await box.put(doc.id, data);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount tasks');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading tasks: $e');
      return SyncResult.error('Erro ao baixar tarefas: $e');
    }
  }

  /// Baixa habits do Firestore
  Future<SyncResult> downloadHabits() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox<Habit>(_habitsBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final habit = _mapToHabit(data);
        await box.put(habit.id, habit);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount habits');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading habits: $e');
      return SyncResult.error('Erro ao baixar hábitos: $e');
    }
  }

  Habit _mapToHabit(Map<String, dynamic> data) {
    final completedDates = (data['completedDates'] as List<dynamic>?)
        ?.map((d) => DateTime.tryParse(d.toString()) ?? DateTime.now())
        .toList() ?? [];

    return Habit(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      iconCode: data['iconCode'] ?? 0,
      colorValue: data['colorValue'] ?? 0,
      scheduledTime: data['scheduledTime'],
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? []),
      completedDates: completedDates,
      currentStreak: data['currentStreak'] ?? 0,
      bestStreak: data['bestStreak'] ?? 0,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      order: data['order'] ?? 0,
    );
  }

  /// Baixa notes do Firestore
  Future<SyncResult> downloadNotes() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox(_notesBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('syncedAt');
        await box.put(doc.id, data);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount notes');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading notes: $e');
      return SyncResult.error('Erro ao baixar notas: $e');
    }
  }

  /// Baixa quotes do Firestore
  Future<SyncResult> downloadQuotes() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quotes')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox(_quotesBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('syncedAt');
        await box.put(doc.id, data);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount quotes');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading quotes: $e');
      return SyncResult.error('Erro ao baixar citações: $e');
    }
  }

  /// Baixa dados de gamificação do Firestore
  Future<SyncResult> downloadGamification() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('data')
          .get();

      if (!doc.exists || doc.data() == null) {
        return SyncResult.success(0);
      }

      final data = doc.data()!;
      final box = await Hive.openBox(_gamificationBoxName);
      int downloadedCount = 0;

      // Download user stats
      if (data['stats'] != null) {
        final stats = Map<String, dynamic>.from(data['stats'] as Map);
        await box.put('user_stats', stats);
        downloadedCount++;
      }

      // Download skills progress
      if (data['skills'] != null) {
        final skills = <String, Map<String, int>>{};
        final skillsData = data['skills'] as Map;
        for (final entry in skillsData.entries) {
          final key = entry.key.toString();
          if (entry.value is Map) {
            skills[key] = Map<String, int>.from(
              (entry.value as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
            );
          }
        }
        await box.put('user_skills_progress', skills);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded gamification data');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading gamification: $e');
      return SyncResult.error('Erro ao baixar gamificação: $e');
    }
  }

  /// Baixa time tracking records do Firestore
  Future<SyncResult> downloadTimeTracking() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('timeTracking')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox<TimeTrackingRecord>(_timeTrackingBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final record = _mapToTimeTrackingRecord(data);
        
        // Encontra a key existente ou adiciona novo
        final existingKey = box.keys.cast<int?>().firstWhere(
          (k) => k != null && box.get(k)?.id == record.id,
          orElse: () => null,
        );
        
        if (existingKey != null) {
          await box.put(existingKey, record);
        } else {
          await box.add(record);
        }
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount time tracking records');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading time tracking: $e');
      return SyncResult.error('Erro ao baixar time tracking: $e');
    }
  }

  TimeTrackingRecord _mapToTimeTrackingRecord(Map<String, dynamic> data) {
    return TimeTrackingRecord(
      id: data['id'] ?? '',
      activityName: data['activityName'] ?? '',
      iconCode: data['iconCode'] ?? 0,
      startTime: DateTime.tryParse(data['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(data['endTime'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: data['durationInSeconds'] ?? 0),
      notes: data['notes'],
      category: data['category'],
      project: data['project'],
      isCompleted: data['isCompleted'] ?? false,
      colorValue: data['colorValue'],
    );
  }

  /// Baixa livros do Firestore
  Future<SyncResult> downloadBooks() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .get();

      if (snapshot.docs.isEmpty) {
        return SyncResult.success(0);
      }

      final box = await Hive.openBox<Book>(_booksBoxName);
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final book = _mapToBook(data);
        await box.put(book.id, book);
        downloadedCount++;
      }

      debugPrint('[SyncService] Downloaded $downloadedCount books');
      return SyncResult.success(downloadedCount);
    } catch (e) {
      debugPrint('[SyncService] Error downloading books: $e');
      return SyncResult.error('Erro ao baixar livros: $e');
    }
  }

  Book _mapToBook(Map<String, dynamic> data) {
    return Book(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      author: data['author'] ?? '',
      description: data['description'],
      statusIndex: data['statusIndex'] ?? 0,
      favourite: data['favourite'] ?? false,
      deleted: data['deleted'] ?? false,
      rating: data['rating'],
      pages: data['pages'],
      publicationYear: data['publicationYear'],
      isbn: data['isbn'],
      olid: data['olid'],
      tags: data['tags'],
      myReview: data['myReview'],
      notes: data['notes'],
      blurHash: data['blurHash'],
      formatIndex: data['formatIndex'] ?? 0,
      hasCover: data['hasCover'] ?? false,
      readingsData: data['readingsData'],
      dateAdded: DateTime.tryParse(data['dateAdded'] ?? '') ?? DateTime.now(),
      dateModified: DateTime.tryParse(data['dateModified'] ?? '') ?? DateTime.now(),
      currentPage: data['currentPage'] ?? 0,
      coverPath: data['coverPath'],
      genre: data['genre'],
      highlights: data['highlights'],
      totalReadingTimeSeconds: data['totalReadingTimeSeconds'] ?? 0,
    );
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Atualiza o timestamp da última sincronização
  Future<void> _updateLastSyncTimestamp() async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error updating last sync timestamp: $e');
    }
  }

  /// Obtém o timestamp da última sincronização
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final timestamp = doc.data()?['lastSyncAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      debugPrint('[SyncService] Error getting last sync timestamp: $e');
      return null;
    }
  }

  /// Verifica se há dados locais não sincronizados
  Future<bool> hasUnsyncedData() async {
    // Implementação simplificada - pode ser expandida para comparar timestamps
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return true;

    // Se última sync foi há mais de 1 hora, considera como tendo dados não sincronizados
    return DateTime.now().difference(lastSync).inHours > 1;
  }

  /// Limpa todos os dados do usuário no Firestore
  Future<void> clearCloudData() async {
    try {
      final collections = ['moods', 'tasks', 'habits', 'notes', 'quotes', 'gamification', 'timeTracking', 'books'];

      for (final collectionName in collections) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection(collectionName)
            .get();

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      debugPrint('[SyncService] Cleared all cloud data for user $userId');
    } catch (e) {
      debugPrint('[SyncService] Error clearing cloud data: $e');
    }
  }
}

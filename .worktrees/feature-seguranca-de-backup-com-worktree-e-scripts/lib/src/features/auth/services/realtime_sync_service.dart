// lib/src/features/auth/services/realtime_sync_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/library/domain/book.dart';

/// Configuração de quais coleções sincronizar
class SyncConfig {
  final bool moods;
  final bool tasks;
  final bool habits;
  final bool notes;
  final bool quotes;
  final bool gamification;
  final bool timeTracking;
  final bool books;

  const SyncConfig({
    this.moods = true,
    this.tasks = true,
    this.habits = true,
    this.notes = true,
    this.quotes = true,
    this.gamification = true,
    this.timeTracking = true,
    this.books = true,
  });

  factory SyncConfig.all() => const SyncConfig();

  factory SyncConfig.none() => const SyncConfig(
        moods: false,
        tasks: false,
        habits: false,
        notes: false,
        quotes: false,
        gamification: false,
        timeTracking: false,
        books: false,
      );

  SyncConfig copyWith({
    bool? moods,
    bool? tasks,
    bool? habits,
    bool? notes,
    bool? quotes,
    bool? gamification,
    bool? timeTracking,
    bool? books,
  }) {
    return SyncConfig(
      moods: moods ?? this.moods,
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      notes: notes ?? this.notes,
      quotes: quotes ?? this.quotes,
      gamification: gamification ?? this.gamification,
      timeTracking: timeTracking ?? this.timeTracking,
      books: books ?? this.books,
    );
  }

  Map<String, bool> toMap() => {
        'moods': moods,
        'tasks': tasks,
        'habits': habits,
        'notes': notes,
        'quotes': quotes,
        'gamification': gamification,
        'timeTracking': timeTracking,
        'books': books,
      };

  factory SyncConfig.fromMap(Map<String, dynamic> map) => SyncConfig(
        moods: map['moods'] ?? true,
        tasks: map['tasks'] ?? true,
        habits: map['habits'] ?? true,
        notes: map['notes'] ?? true,
        quotes: map['quotes'] ?? true,
        gamification: map['gamification'] ?? true,
        timeTracking: map['timeTracking'] ?? true,
        books: map['books'] ?? true,
      );
}

/// Evento de mudança recebido do Firestore
class SyncChangeEvent {
  final String collection;
  final String documentId;
  final DocumentChangeType changeType;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  SyncChangeEvent({
    required this.collection,
    required this.documentId,
    required this.changeType,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isAdded => changeType == DocumentChangeType.added;
  bool get isModified => changeType == DocumentChangeType.modified;
  bool get isRemoved => changeType == DocumentChangeType.removed;
}

/// Serviço de sincronização em tempo real (bidirecional)
/// 
/// Este serviço:
/// 1. Escuta mudanças no Firestore e aplica localmente
/// 2. Detecta conflitos baseado em timestamps
/// 3. Permite configurar quais coleções sincronizar
class RealtimeSyncService {
  final FirebaseFirestore _firestore;
  final String userId;
  SyncConfig _config;

  // Subscriptions para cada coleção
  final Map<String, StreamSubscription> _subscriptions = {};

  // Controller para eventos de sync
  final _changeController = StreamController<SyncChangeEvent>.broadcast();

  // Flags de controle
  bool _isListening = false;
  bool _isPaused = false;

  // Nomes dos boxes Hive
  static const String _moodRecordsBoxName = 'mood_records';
  static const String _tasksBoxName = 'tasks';
  static const String _habitsBoxName = 'habits';
  static const String _notesBoxName = 'notes_v2';
  static const String _quotesBoxName = 'quotes';
  static const String _gamificationBoxName = 'gamification';
  static const String _timeTrackingBoxName = 'time_tracking_records';
  static const String _booksBoxName = 'books_v3';

  RealtimeSyncService({
    required FirebaseFirestore firestore,
    required this.userId,
    SyncConfig? config,
  })  : _firestore = firestore,
        _config = config ?? SyncConfig.all();

  /// Stream de eventos de mudança
  Stream<SyncChangeEvent> get changeStream => _changeController.stream;

  /// Se está escutando mudanças
  bool get isListening => _isListening && !_isPaused;

  /// Configuração atual de sync
  SyncConfig get config => _config;

  /// Atualiza a configuração de sync
  void updateConfig(SyncConfig config) {
    _config = config;
    
    // Reiniciar listeners se já estiver ativo
    if (_isListening) {
      stopListening();
      startListening();
    }
  }

  /// Inicia a escuta de mudanças no Firestore
  Future<void> startListening() async {
    if (_isListening) return;
    
    _isListening = true;
    _isPaused = false;

    debugPrint('[RealtimeSyncService] Starting listeners for user: $userId');

    if (_config.moods) await _listenToCollection('moods', _handleMoodChange);
    if (_config.tasks) await _listenToCollection('tasks', _handleTaskChange);
    if (_config.habits) await _listenToCollection('habits', _handleHabitChange);
    if (_config.notes) await _listenToCollection('notes', _handleNoteChange);
    if (_config.quotes) await _listenToCollection('quotes', _handleQuoteChange);
    if (_config.timeTracking) await _listenToCollection('timeTracking', _handleTimeTrackingChange);
    if (_config.books) await _listenToCollection('books', _handleBookChange);
    if (_config.gamification) await _listenToGamification();

    debugPrint('[RealtimeSyncService] Listeners started: ${_subscriptions.keys.join(", ")}');
  }

  /// Para a escuta de mudanças
  void stopListening() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _isListening = false;
    debugPrint('[RealtimeSyncService] Listeners stopped');
  }

  /// Pausa temporariamente a sincronização (útil durante edição local)
  void pauseSync() {
    _isPaused = true;
    debugPrint('[RealtimeSyncService] Sync paused');
  }

  /// Retoma a sincronização
  void resumeSync() {
    _isPaused = false;
    debugPrint('[RealtimeSyncService] Sync resumed');
  }

  /// Escuta uma coleção específica
  Future<void> _listenToCollection(
    String collectionName,
    Future<void> Function(DocumentChange<Map<String, dynamic>>) handler,
  ) async {
    final collectionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName);

    final subscription = collectionRef.snapshots().listen(
      (snapshot) async {
        if (_isPaused) return;

        for (final change in snapshot.docChanges) {
          try {
            await handler(change);

            _changeController.add(SyncChangeEvent(
              collection: collectionName,
              documentId: change.doc.id,
              changeType: change.type,
              data: change.doc.data(),
            ));
          } catch (e) {
            debugPrint('[RealtimeSyncService] Error handling $collectionName change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('[RealtimeSyncService] Error listening to $collectionName: $error');
      },
    );

    _subscriptions[collectionName] = subscription;
  }

  /// Escuta mudanças de gamificação (documento único)
  Future<void> _listenToGamification() async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('gamification')
        .doc('data');

    final subscription = docRef.snapshots().listen(
      (snapshot) async {
        if (_isPaused) return;
        if (!snapshot.exists) return;

        try {
          await _handleGamificationChange(snapshot);

          _changeController.add(SyncChangeEvent(
            collection: 'gamification',
            documentId: 'data',
            changeType: DocumentChangeType.modified,
            data: snapshot.data(),
          ));
        } catch (e) {
          debugPrint('[RealtimeSyncService] Error handling gamification change: $e');
        }
      },
      onError: (error) {
        debugPrint('[RealtimeSyncService] Error listening to gamification: $error');
      },
    );

    _subscriptions['gamification'] = subscription;
  }

  // ============================================
  // HANDLERS POR COLEÇÃO
  // ============================================

  Future<void> _handleMoodChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox<MoodRecord>(_moodRecordsBoxName);
    final key = int.tryParse(change.doc.id) ?? change.doc.id.hashCode;

    if (change.type == DocumentChangeType.removed) {
      await box.delete(key);
      debugPrint('[RealtimeSyncService] Mood deleted: $key');
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    // Verificar se deve atualizar (comparar timestamps)
    final existingRecord = box.get(key);
    if (existingRecord != null && !_shouldApplyServerChange(data, existingRecord.date)) {
      return;
    }

    final moodRecord = _mapToMoodRecord(data);
    await box.put(key, moodRecord);
    debugPrint('[RealtimeSyncService] Mood synced from server: $key');
  }

  Future<void> _handleTaskChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox(_tasksBoxName);

    if (change.type == DocumentChangeType.removed) {
      await box.delete(change.doc.id);
      debugPrint('[RealtimeSyncService] Task deleted: ${change.doc.id}');
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    // Remover campos de sync antes de salvar localmente
    final localData = Map<String, dynamic>.from(data);
    localData.remove('_syncedAt');
    localData.remove('_localModifiedAt');

    await box.put(change.doc.id, localData);
    debugPrint('[RealtimeSyncService] Task synced from server: ${change.doc.id}');
  }

  Future<void> _handleHabitChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox<Habit>(_habitsBoxName);

    if (change.type == DocumentChangeType.removed) {
      await box.delete(change.doc.id);
      debugPrint('[RealtimeSyncService] Habit deleted: ${change.doc.id}');
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    final habit = _mapToHabit(data);
    await box.put(habit.id, habit);
    debugPrint('[RealtimeSyncService] Habit synced from server: ${habit.id}');
  }

  Future<void> _handleNoteChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox(_notesBoxName);

    if (change.type == DocumentChangeType.removed) {
      await box.delete(change.doc.id);
      debugPrint('[RealtimeSyncService] Note deleted: ${change.doc.id}');
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    final localData = Map<String, dynamic>.from(data);
    localData.remove('_syncedAt');
    localData.remove('_localModifiedAt');

    await box.put(change.doc.id, localData);
    debugPrint('[RealtimeSyncService] Note synced from server: ${change.doc.id}');
  }

  Future<void> _handleQuoteChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox(_quotesBoxName);

    if (change.type == DocumentChangeType.removed) {
      await box.delete(change.doc.id);
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    final localData = Map<String, dynamic>.from(data);
    localData.remove('_syncedAt');
    localData.remove('_localModifiedAt');

    await box.put(change.doc.id, localData);
    debugPrint('[RealtimeSyncService] Quote synced from server: ${change.doc.id}');
  }

  Future<void> _handleTimeTrackingChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox<TimeTrackingRecord>(_timeTrackingBoxName);

    if (change.type == DocumentChangeType.removed) {
      // Encontrar e remover por ID
      final keyToRemove = box.keys.cast<int?>().firstWhere(
        (k) => k != null && box.get(k)?.id == change.doc.id,
        orElse: () => null,
      );
      if (keyToRemove != null) {
        await box.delete(keyToRemove);
      }
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    final record = _mapToTimeTrackingRecord(data);

    // Verificar se já existe
    final existingKey = box.keys.cast<int?>().firstWhere(
      (k) => k != null && box.get(k)?.id == record.id,
      orElse: () => null,
    );

    if (existingKey != null) {
      await box.put(existingKey, record);
    } else {
      await box.add(record);
    }
    debugPrint('[RealtimeSyncService] TimeTracking synced from server: ${record.id}');
  }

  Future<void> _handleBookChange(DocumentChange<Map<String, dynamic>> change) async {
    final box = await Hive.openBox<Book>(_booksBoxName);

    if (change.type == DocumentChangeType.removed) {
      await box.delete(change.doc.id);
      return;
    }

    final data = change.doc.data();
    if (data == null) return;

    final book = _mapToBook(data);
    await box.put(book.id, book);
    debugPrint('[RealtimeSyncService] Book synced from server: ${book.id}');
  }

  Future<void> _handleGamificationChange(DocumentSnapshot snapshot) async {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final box = await Hive.openBox(_gamificationBoxName);

    if (data['stats'] != null) {
      final stats = Map<String, dynamic>.from(data['stats'] as Map);
      await box.put('user_stats', stats);
    }

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
    }

    debugPrint('[RealtimeSyncService] Gamification synced from server');
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Verifica se deve aplicar mudança do servidor
  bool _shouldApplyServerChange(Map<String, dynamic> serverData, DateTime? localModifiedAt) {
    if (localModifiedAt == null) return true;

    final serverModifiedStr = serverData['_localModifiedAt'] as String?;
    if (serverModifiedStr == null) return true;

    final serverModifiedAt = DateTime.tryParse(serverModifiedStr);
    if (serverModifiedAt == null) return true;

    // Aplica se servidor é mais recente
    return serverModifiedAt.isAfter(localModifiedAt);
  }

  MoodRecord _mapToMoodRecord(Map<String, dynamic> data) {
    final activities = (data['activities'] as List<dynamic>?)
            ?.map((a) => Activity(
                  activityName: a['activityName'] ?? '',
                  iconCode: a['iconCode'] ?? 0,
                ))
            .toList() ??
        [];

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

  Habit _mapToHabit(Map<String, dynamic> data) {
    final completedDates = (data['completedDates'] as List<dynamic>?)
            ?.map((d) => DateTime.tryParse(d.toString()) ?? DateTime.now())
            .toList() ??
        [];

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

  /// Libera recursos
  void dispose() {
    stopListening();
    _changeController.close();
  }
}

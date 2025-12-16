import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/providers/app_initializer_provider.dart';

class TimeTrackingRepository {
  TimeTrackingRepository(this._timeTrackingBox);
  final Box<TimeTrackingRecord> _timeTrackingBox;

  Box<TimeTrackingRecord> get box => _timeTrackingBox;

  static Future<TimeTrackingRepository> createTimeTrackingRepository() async {
    final box = await Hive.openBox<TimeTrackingRecord>("time_tracking_records");
    return TimeTrackingRepository(box);
  }

  Future<int> addTimeTrackingRecord(TimeTrackingRecord record) {
    return _timeTrackingBox.add(record);
  }

  List<TimeTrackingRecord> fetchAllTimeTrackingRecords() {
    return _timeTrackingBox.values.toList();
  }

  List<TimeTrackingRecord> fetchTimeTrackingRecordsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _timeTrackingBox.values
        .where((record) => 
            record.startTime.isAfter(startOfDay) && 
            record.startTime.isBefore(endOfDay))
        .toList();
  }

  Future<void> updateTimeTrackingRecord(String id, TimeTrackingRecord record) {
    final key = _timeTrackingBox.keys
        .firstWhere((key) => _timeTrackingBox.get(key)?.id == id, orElse: () => -1);
    if (key != -1) {
      return _timeTrackingBox.put(key, record);
    }
    return Future.value();
  }

  Future<void> toggleCompleted(String id) async {
    final key = _timeTrackingBox.keys
        .firstWhere((key) => _timeTrackingBox.get(key)?.id == id, orElse: () => -1);
    if (key != -1) {
      final record = _timeTrackingBox.get(key);
      if (record != null) {
        final updated = record.copyWith(isCompleted: !record.isCompleted);
        await _timeTrackingBox.put(key, updated);
      }
    }
  }

  int countCompletedToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _timeTrackingBox.values
        .where((r) => r.startTime.isAfter(startOfDay) && r.isCompleted)
        .length;
  }

  Future<void> deleteTimeTrackingRecord(String id) {
    final key = _timeTrackingBox.keys
        .firstWhere((key) => _timeTrackingBox.get(key)?.id == id, orElse: () => -1);
    if (key != -1) {
      return _timeTrackingBox.delete(key);
    }
    return Future.value();
  }

  // Buscar projetos únicos
  Set<String> getAllProjects() {
    return _timeTrackingBox.values
        .where((r) => r.project != null && r.project!.isNotEmpty)
        .map((r) => r.project!)
        .toSet();
  }

  // Buscar categorias únicas
  Set<String> getAllCategories() {
    return _timeTrackingBox.values
        .where((r) => r.category != null && r.category!.isNotEmpty)
        .map((r) => r.category!)
        .toSet();
  }
}

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  final appInitState = ref.watch(appInitializerProvider);
  if (appInitState.timeTrackingRepository == null) {
    throw Exception('TimeTrackingRepository not initialized');
  }
  return appInitState.timeTrackingRepository!;
});

final timeTrackingRecordsProvider = Provider<List<TimeTrackingRecord>>((ref) {
  final repository = ref.watch(timeTrackingRepositoryProvider);
  return repository.fetchAllTimeTrackingRecords();
});

final timeTrackingRecordsByDateProvider = Provider.family<List<TimeTrackingRecord>, DateTime>((ref, date) {
  final repository = ref.watch(timeTrackingRepositoryProvider);
  return repository.fetchTimeTrackingRecordsByDate(date);
});
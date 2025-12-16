import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/providers/app_initializer_provider.dart';

class MoodRecordRepository {
  MoodRecordRepository(this._moodRecordBox);
  final Box<MoodRecord> _moodRecordBox;

  Box<MoodRecord> get box => _moodRecordBox;

  static Future<MoodRecordRepository> createRepository() async {
    Box<MoodRecord> box;
    try {
      box = await Hive.openBox<MoodRecord>("mood_records");
    } catch (e) {
      debugPrint('Error opening mood_records box: $e');
      // If there's a type mismatch or other error, we might need to delete the box
      try {
        await Hive.deleteBoxFromDisk("mood_records");
      } catch (e) {
        debugPrint('Error deleting box: $e');
      }
      box = await Hive.openBox<MoodRecord>("mood_records");
    }
    // ref.onDispose(() => box.close());
    return MoodRecordRepository(box);
  }

  Future<int> createMoodRecord(MoodRecord record) {
    return _moodRecordBox.add(record);
  }

  Map<dynamic, MoodRecord> fetchMoodRecords() {
    return _moodRecordBox.toMap();
  }

  Future<void> updateMoodRecord(int key, MoodRecord record) {
    return _moodRecordBox.put(key, record);
  }

  Future<void> deleteMoodRecord(int key) {
    return _moodRecordBox.delete(key);
  }

  Map<dynamic, MoodRecord> fetchMoodRecordsByDate({required DateTime before, required DateTime after}) {
    final map = _moodRecordBox.toMap();
    map.removeWhere((key, value) => (value.date.compareTo(before) >= 0 || value.date.compareTo(after) <= 0));
    return map;
  }
}

final moodRecordRepositoryProvider = Provider<MoodRecordRepository>((ref) {
  final appInitState = ref.watch(appInitializerProvider);
  if (appInitState.moodRepository == null) {
    throw Exception('MoodRecordRepository not initialized');
  }
  return appInitState.moodRepository!;
});

final moodRecordsProvider = Provider<Map<dynamic, MoodRecord>>((ref) {
  final moodRecordRepository = ref.watch(moodRecordRepositoryProvider);
  return moodRecordRepository.fetchMoodRecords();
});

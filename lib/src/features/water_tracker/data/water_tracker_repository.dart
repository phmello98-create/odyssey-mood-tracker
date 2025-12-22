import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:odyssey/src/features/water_tracker/domain/water_record.dart';

/// Repositório para gerenciar registros de água
class WaterTrackerRepository {
  static const String _boxName = 'water_records';
  Box<WaterRecord>? _box;

  /// Inicializa o repositório
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<WaterRecord>(_boxName);
    debugPrint('💧 WaterTrackerRepository initialized');
  }

  /// Obtém a box (inicializando se necessário)
  Future<Box<WaterRecord>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Gera ID para uma data
  String _dateToId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Obtém o registro de hoje
  Future<WaterRecord> getTodayRecord() async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());

    final existing = box.get(todayId);
    if (existing != null) {
      return existing;
    }

    // Cria novo registro para hoje
    final newRecord = WaterRecord.today();
    await box.put(todayId, newRecord);
    return newRecord;
  }

  /// Obtém registro por data
  Future<WaterRecord?> getRecordByDate(DateTime date) async {
    final box = await _getBox();
    return box.get(_dateToId(date));
  }

  /// Adiciona um copo de água
  Future<WaterRecord> addGlass({DateTime? time}) async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());
    final now = DateTime.now();

    var record = box.get(todayId) ?? WaterRecord.today();

    final updatedTimes = List<DateTime>.from(record.drinkTimes)
      ..add(time ?? now);

    record = record.copyWith(
      glassesCount: record.glassesCount + 1,
      drinkTimes: updatedTimes,
      updatedAt: now,
    );

    await box.put(todayId, record);
    debugPrint('💧 Added glass: ${record.glassesCount}/${record.goalGlasses}');
    return record;
  }

  /// Remove um copo de água
  Future<WaterRecord> removeGlass() async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());
    final now = DateTime.now();

    var record = box.get(todayId) ?? WaterRecord.today();

    if (record.glassesCount <= 0) return record;

    final updatedTimes = List<DateTime>.from(record.drinkTimes);
    if (updatedTimes.isNotEmpty) {
      updatedTimes.removeLast();
    }

    record = record.copyWith(
      glassesCount: record.glassesCount - 1,
      drinkTimes: updatedTimes,
      updatedAt: now,
    );

    await box.put(todayId, record);
    debugPrint(
      '💧 Removed glass: ${record.glassesCount}/${record.goalGlasses}',
    );
    return record;
  }

  /// Atualiza a meta de copos
  Future<WaterRecord> updateGoal(int goalGlasses) async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());
    final now = DateTime.now();

    var record = box.get(todayId) ?? WaterRecord.today();

    record = record.copyWith(goalGlasses: goalGlasses, updatedAt: now);

    await box.put(todayId, record);
    debugPrint('💧 Updated goal: ${record.goalGlasses} glasses');
    return record;
  }

  /// Atualiza o tamanho do copo
  Future<WaterRecord> updateGlassSize(int sizeMl) async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());
    final now = DateTime.now();

    var record = box.get(todayId) ?? WaterRecord.today();

    record = record.copyWith(glassSizeMl: sizeMl, updatedAt: now);

    await box.put(todayId, record);
    debugPrint('💧 Updated glass size: ${record.glassSizeMl}ml');
    return record;
  }

  /// Reseta o registro de hoje
  Future<WaterRecord> resetToday() async {
    final box = await _getBox();
    final todayId = _dateToId(DateTime.now());

    final existing = box.get(todayId);
    final newRecord = WaterRecord.today(
      goalGlasses: existing?.goalGlasses ?? 8,
      glassSizeMl: existing?.glassSizeMl ?? 250,
    );

    await box.put(todayId, newRecord);
    debugPrint('💧 Reset today record');
    return newRecord;
  }

  /// Obtém registros da última semana
  Future<List<WaterRecord>> getWeekRecords() async {
    final box = await _getBox();
    final now = DateTime.now();
    final records = <WaterRecord>[];

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final id = _dateToId(date);
      final record = box.get(id);
      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  /// Estatísticas da semana
  Future<Map<String, dynamic>> getWeekStats() async {
    final records = await getWeekRecords();

    if (records.isEmpty) {
      return {
        'totalMl': 0,
        'totalGlasses': 0,
        'avgGlasses': 0.0,
        'daysWithGoal': 0,
        'streak': 0,
      };
    }

    int totalMl = 0;
    int totalGlasses = 0;
    int daysWithGoal = 0;

    for (final record in records) {
      totalMl += record.totalMl;
      totalGlasses += record.glassesCount;
      if (record.goalReached) daysWithGoal++;
    }

    return {
      'totalMl': totalMl,
      'totalGlasses': totalGlasses,
      'avgGlasses': totalGlasses / records.length,
      'daysWithGoal': daysWithGoal,
      'streak': _calculateStreak(records),
    };
  }

  int _calculateStreak(List<WaterRecord> records) {
    int streak = 0;
    for (var i = records.length - 1; i >= 0; i--) {
      if (records[i].goalReached) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Fecha o repositório
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

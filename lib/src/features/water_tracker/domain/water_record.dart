import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'water_record.freezed.dart';
part 'water_record.g.dart';

/// Registro diário de consumo de água
@freezed
@HiveType(typeId: 60)
class WaterRecord with _$WaterRecord {
  const WaterRecord._();

  factory WaterRecord({
    /// ID único (data no formato yyyy-MM-dd)
    @HiveField(0) required String id,

    /// Data do registro
    @HiveField(1) required DateTime date,

    /// Quantidade de copos bebidos
    @HiveField(2) @Default(0) int glassesCount,

    /// Meta de copos (padrão: 8 copos de 250ml = 2L)
    @HiveField(3) @Default(8) int goalGlasses,

    /// Tamanho do copo em ml (padrão: 250ml)
    @HiveField(4) @Default(250) int glassSizeMl,

    /// Horários em que bebeu água
    @HiveField(5) @Default([]) List<DateTime> drinkTimes,

    /// Data de criação
    @HiveField(6) required DateTime createdAt,

    /// Data de última atualização
    @HiveField(7) required DateTime updatedAt,
  }) = _WaterRecord;

  factory WaterRecord.fromJson(Map<String, dynamic> json) =>
      _$WaterRecordFromJson(json);

  /// Cria um registro para hoje
  factory WaterRecord.today({int goalGlasses = 8, int glassSizeMl = 250}) {
    final now = DateTime.now();
    final dateId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return WaterRecord(
      id: dateId,
      date: DateTime(now.year, now.month, now.day),
      goalGlasses: goalGlasses,
      glassSizeMl: glassSizeMl,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Total de ml bebidos
  int get totalMl => glassesCount * glassSizeMl;

  /// Meta em ml
  int get goalMl => goalGlasses * glassSizeMl;

  /// Progresso (0.0 a 1.0+)
  double get progress => goalGlasses > 0 ? glassesCount / goalGlasses : 0;

  /// Meta atingida?
  bool get goalReached => glassesCount >= goalGlasses;

  /// Copos restantes
  int get remainingGlasses =>
      (goalGlasses - glassesCount).clamp(0, goalGlasses);

  /// Ml restantes
  int get remainingMl => remainingGlasses * glassSizeMl;
}

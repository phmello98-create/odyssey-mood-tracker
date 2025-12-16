import 'package:flutter/material.dart' show IconData;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'suggestion_enums.dart';
import '../data/suggestion_icons.dart';

part 'suggestion.freezed.dart';
part 'suggestion.g.dart';

@freezed
class Suggestion with _$Suggestion {
  @HiveType(typeId: 16, adapterName: 'SuggestionAdapter')
  const factory Suggestion({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required String description,
    @HiveField(3) required SuggestionType type,
    @HiveField(4) required SuggestionCategory category,
    @HiveField(5) required String iconKey,
    @HiveField(6) required int colorValue,
    @HiveField(7) @Default(1) int minLevel,
    @HiveField(8) @Default(SuggestionDifficulty.easy) SuggestionDifficulty difficulty,
    @HiveField(9) List<String>? relatedActivities,
    @HiveField(10) List<String>? relatedMoods,
    @HiveField(11) String? scheduledTime,
    @HiveField(12) List<int>? suggestedDays,
  }) = _Suggestion;
  
  const Suggestion._();

  factory Suggestion.fromJson(Map<String, dynamic> json) => _$SuggestionFromJson(json);
  
  /// Retorna o IconData de forma segura para tree-shaking
  IconData get icon => getSuggestionIcon(iconKey);
}

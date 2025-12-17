import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

@freezed
class DiaryEntry with _$DiaryEntry {
  @HiveType(typeId: 20, adapterName: 'DiaryEntryAdapter')
  const factory DiaryEntry({
    @HiveField(0) required String id,
    @HiveField(1) required DateTime createdAt,
    @HiveField(2) required DateTime updatedAt,
    @HiveField(3) required DateTime entryDate,
    @HiveField(4) String? title,
    @HiveField(5) required String content,
    @HiveField(6) @Default([]) List<String> photoIds,
    @HiveField(7) @Default(false) bool starred,
    @HiveField(8) String? feeling,
    @HiveField(9) @Default([]) List<String> tags,
    @HiveField(10) String? searchableText,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  factory DiaryEntry.empty() {
    final now = DateTime.now();
    return DiaryEntry(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      entryDate: now,
      content: '[]',
    );
  }

  factory DiaryEntry.forDate(DateTime date) {
    final now = DateTime.now();
    return DiaryEntry(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      entryDate: date,
      content: '[]',
    );
  }
}

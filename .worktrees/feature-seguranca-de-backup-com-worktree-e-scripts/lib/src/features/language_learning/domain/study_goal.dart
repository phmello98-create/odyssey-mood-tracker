import 'package:hive_flutter/hive_flutter.dart';

part 'study_goal.g.dart';

@HiveType(typeId: 23)
class StudyGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String languageId; // null = goal for all languages

  @HiveField(2)
  final int dailyMinutesGoal;

  @HiveField(3)
  final int weeklyMinutesGoal;

  @HiveField(4)
  final int dailyNewWordsGoal;

  @HiveField(5)
  final int weeklyNewWordsGoal;

  @HiveField(6)
  final bool remindersEnabled;

  @HiveField(7)
  final String? reminderTime; // "09:00"

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  StudyGoal({
    required this.id,
    required this.languageId,
    this.dailyMinutesGoal = 30,
    this.weeklyMinutesGoal = 150,
    this.dailyNewWordsGoal = 5,
    this.weeklyNewWordsGoal = 25,
    this.remindersEnabled = true,
    this.reminderTime = '09:00',
    required this.createdAt,
    required this.updatedAt,
  });

  StudyGoal copyWith({
    String? id,
    String? languageId,
    int? dailyMinutesGoal,
    int? weeklyMinutesGoal,
    int? dailyNewWordsGoal,
    int? weeklyNewWordsGoal,
    bool? remindersEnabled,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyGoal(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      dailyMinutesGoal: dailyMinutesGoal ?? this.dailyMinutesGoal,
      weeklyMinutesGoal: weeklyMinutesGoal ?? this.weeklyMinutesGoal,
      dailyNewWordsGoal: dailyNewWordsGoal ?? this.dailyNewWordsGoal,
      weeklyNewWordsGoal: weeklyNewWordsGoal ?? this.weeklyNewWordsGoal,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Presets for goals
class StudyGoalPresets {
  static const casual = {'daily': 15, 'weekly': 75, 'words': 3, 'weeklyWords': 15};
  static const regular = {'daily': 30, 'weekly': 150, 'words': 5, 'weeklyWords': 25};
  static const serious = {'daily': 60, 'weekly': 300, 'words': 10, 'weeklyWords': 50};
  static const intense = {'daily': 120, 'weekly': 600, 'words': 20, 'weeklyWords': 100};

  static List<Map<String, dynamic>> get all => [
    {'id': 'casual', 'name': 'Casual', 'desc': '15 min/dia', 'icon': 0xe5d8, ...casual},
    {'id': 'regular', 'name': 'Regular', 'desc': '30 min/dia', 'icon': 0xe5d5, ...regular},
    {'id': 'serious', 'name': 'Sério', 'desc': '1h/dia', 'icon': 0xe3f3, ...serious},
    {'id': 'intense', 'name': 'Intenso', 'desc': '2h/dia', 'icon': 0xf06bb, ...intense},
  ];
}

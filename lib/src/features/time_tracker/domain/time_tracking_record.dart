import 'package:hive/hive.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';

part 'time_tracking_record.g.dart';

@HiveType(typeId: 2)
class TimeTrackingRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String activityName;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final int durationInSeconds;

  Duration get duration => Duration(seconds: durationInSeconds);

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final String? category;

  @HiveField(8)
  final String? project;

  @HiveField(9)
  final bool isCompleted;

  @HiveField(10)
  final int? colorValue;

  // Private constructor for Hive adapter
  TimeTrackingRecord._internal({
    required this.id,
    required this.activityName,
    required this.iconCode,
    required this.startTime,
    required this.endTime,
    required this.durationInSeconds,
    this.notes,
    this.category,
    this.project,
    this.isCompleted = false,
    this.colorValue,
  });

  // Public factory constructor that accepts Duration
  factory TimeTrackingRecord({
    required String id,
    required String activityName,
    required int iconCode,
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    String? notes,
    String? category,
    String? project,
    bool isCompleted = false,
    int? colorValue,
  }) {
    return TimeTrackingRecord._internal(
      id: id,
      activityName: activityName,
      iconCode: iconCode,
      startTime: startTime,
      endTime: endTime,
      durationInSeconds: duration.inSeconds,
      notes: notes,
      category: category,
      project: project,
      isCompleted: isCompleted,
      colorValue: colorValue,
    );
  }

  TimeTrackingRecord copyWith({
    String? id,
    String? activityName,
    int? iconCode,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? notes,
    String? category,
    String? project,
    bool? isCompleted,
    int? colorValue,
  }) {
    return TimeTrackingRecord(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      iconCode: iconCode ?? this.iconCode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      project: project ?? this.project,
      isCompleted: isCompleted ?? this.isCompleted,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory TimeTrackingRecord.fromActivity(Activity activity, {String? notes}) {
    return TimeTrackingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityName: activity.activityName,
      iconCode: activity.iconCode,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: Duration.zero,
      notes: notes,
    );
  }
}
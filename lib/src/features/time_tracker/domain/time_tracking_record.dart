import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';

part 'time_tracking_record.freezed.dart';
part 'time_tracking_record.g.dart';

@freezed
class TimeTrackingRecord with _$TimeTrackingRecord {
  @HiveType(typeId: 2)
  const factory TimeTrackingRecord.internal({
    @HiveField(0) required String id,
    @HiveField(1) required String activityName,
    @HiveField(2) required int iconCode,
    @HiveField(3) required DateTime startTime,
    @HiveField(4) required DateTime endTime,
    @HiveField(5) required int durationInSeconds,
    @HiveField(6) String? notes,
    @HiveField(7) String? category,
    @HiveField(8) String? project,
    @HiveField(9) @Default(false) bool isCompleted,
    @HiveField(10) int? colorValue,
  }) = _TimeTrackingRecord;

  // This factory allows existing code to call TimeTrackingRecord(duration: ...)
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
    return TimeTrackingRecord.internal(
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

  const TimeTrackingRecord._();

  Duration get duration => Duration(seconds: durationInSeconds);

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

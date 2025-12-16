class TimeTask {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isRunning;
  final Duration totalDuration;

  TimeTask({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isRunning = false,
    this.totalDuration = Duration.zero,
  });

  TimeTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRunning,
    Duration? totalDuration,
  }) {
    return TimeTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRunning: isRunning ?? this.isRunning,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}
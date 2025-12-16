import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_task.dart';

class TimeTrackerNotifier extends StateNotifier<List<TimeTask>> {
  TimeTrackerNotifier() : super([]);

  void addTask(TimeTask task) {
    state = [...state, task];
  }

  void updateTask(String id, TimeTask task) {
    state = [
      for (final t in state)
        if (t.id == id) task else t,
    ];
  }

  void removeTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }

  void startTask(String id) {
    final index = state.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = state[index];
      if (!task.isRunning) {
        final updatedTask = task.copyWith(
          isRunning: true,
          startTime: DateTime.now(),
        );
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) updatedTask else state[i],
        ];
      }
    }
  }

  void stopTask(String id) {
    final index = state.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = state[index];
      if (task.isRunning) {
        final now = DateTime.now();
        final duration = now.difference(task.startTime);
        final updatedTask = task.copyWith(
          isRunning: false,
          endTime: now,
          totalDuration: task.totalDuration + duration,
        );
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index) updatedTask else state[i],
        ];
      }
    }
  }

  Duration getTotalDurationForTask(String id) {
    final task = state.firstWhere((task) => task.id == id, orElse: () => TimeTask(
      id: '',
      title: '',
      startTime: DateTime.now(),
    ));
    
    if (task.isRunning) {
      return task.totalDuration + DateTime.now().difference(task.startTime);
    } else {
      return task.totalDuration;
    }
  }
}

final timeTrackerProvider =
    StateNotifierProvider<TimeTrackerNotifier, List<TimeTask>>((ref) {
  return TimeTrackerNotifier();
});
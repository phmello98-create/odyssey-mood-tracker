class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  Task({required this.id, required this.title, this.completed = false, required this.createdAt});
}

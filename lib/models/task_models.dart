class TaskModel {
  final String id;
  final String title;
  final DateTime dateTime;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.dateTime,
    this.isCompleted = false,
  });
}
import 'package:hive/hive.dart';

part 'task_models.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime dateTime;

  @HiveField(3)
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.dateTime,
    this.isCompleted = false,
  });
}
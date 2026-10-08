import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_models.dart';

class TaskDatabase {
  static const String boxName = 'tasksBox';

  // Database initialize
  static Future<void> init() async {
    await Hive.initFlutter();

    // Adapter আগে register করা না থাকলে শুধু তখনই register করবে
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    await Hive.openBox<TaskModel>(boxName);
  }

  // সব Task পাওয়া
  static List<TaskModel> getTasks() {
    final box = Hive.box<TaskModel>(boxName);
    return box.values.toList();
  }

  // Task save
  static Future<void> addTask(TaskModel task) async {
    final box = Hive.box<TaskModel>(boxName);
    await box.put(task.id, task);
  }

  // Task update
  static Future<void> updateTask(TaskModel task) async {
    final box = Hive.box<TaskModel>(boxName);
    await box.put(task.id, task);
  }

  // Task delete
  static Future<void> deleteTask(String id) async {
    final box = Hive.box<TaskModel>(boxName);
    await box.delete(id);
  }
}
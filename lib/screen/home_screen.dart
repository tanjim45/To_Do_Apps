import 'package:flutter/material.dart';
import 'package:todo_app/models/task_models.dart';
import 'package:todo_app/sevice/notification_service.dart';
import 'package:todo_app/sevice/task_database.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // Database থেকে Task load
  void loadTasks() {
    final savedTasks = TaskDatabase.getTasks();

    setState(() {
      tasks = savedTasks;
    });
  }

  // নতুন Task add
  Future<void> addTask() async {
  final task = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AddTaskPage(),
    ),
  );

  if (task != null && task is TaskModel) {
    // প্রথমে Database-এ save
    await TaskDatabase.addTask(task);

    // তারপর সঙ্গে সঙ্গে Home Page-এ show
    setState(() {
      tasks.add(task);
    });

    // তারপর Notification schedule
    try {
      await NotificationService.scheduleTaskNotification(
        id: int.parse(task.id),
        title: task.title,
        scheduledDateTime: task.dateTime,
      );
    } catch (e) {
      debugPrint('Notification scheduling error: $e');
    }
  }
}

  // Task Done / Undone
  Future<void> toggleTask(TaskModel task) async {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    await TaskDatabase.updateTask(task);
  }

  // Task Delete
  Future<void> deleteTask(TaskModel task) async {
    await TaskDatabase.deleteTask(task.id);

    setState(() {
      tasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My To-Do',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await NotificationService.showTestNotification();
            },
            icon: const Icon(Icons.notifications),
            tooltip: 'Test Notification',
          ),
        ],
      ),

      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: IconButton(
                      onPressed: () => toggleTask(task),
                      icon: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: task.isCompleted ? Colors.green : Colors.blue,
                        size: 30,
                      ),
                    ),

                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),

                    subtitle: Text(
                      '${task.dateTime.day}/'
                      '${task.dateTime.month}/'
                      '${task.dateTime.year} '
                      '${task.dateTime.hour}:'
                      '${task.dateTime.minute.toString().padLeft(2, '0')}',
                    ),

                    trailing: IconButton(
                      onPressed: () => deleteTask(task),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

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

  // Stable notification ID for each task.
  // It must fit within the 32-bit integer range.
  int notificationId(TaskModel task) {
    return int.parse(task.id) % 2147483647;
  }

  // Load tasks from Hive database.
  void loadTasks() {
    final savedTasks = TaskDatabase.getTasks();

    if (!mounted) return;

    setState(() {
      tasks = savedTasks;
    });
  }

  // Add a new task.
  Future<void> addTask() async {
    final result = await Navigator.push<TaskModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskPage(),
      ),
    );

    if (result == null) return;

    // Save task to database.
    await TaskDatabase.addTask(result);

    // Update Home Page.
    if (!mounted) return;

    setState(() {
      tasks.add(result);
    });

    // Schedule notification.
    try {
      await NotificationService.scheduleTaskNotification(
        id: notificationId(result),
        title: result.title,
        scheduledDateTime: result.dateTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved and reminder scheduled!'),
        ),
      );
    } catch (e) {
      debugPrint('Notification scheduling error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification error: $e'),
        ),
      );
    }
  }

  // Mark task as Done or Pending.
  Future<void> toggleTask(TaskModel task) async {
    final previousStatus = task.isCompleted;

    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    try {
      await TaskDatabase.updateTask(task);

      // If completed, cancel its scheduled notification.
      if (task.isCompleted) {
        await NotificationService.cancelNotification(
          notificationId(task),
        );
      } else if (!previousStatus) {
        // No action needed.
      }
    } catch (e) {
      debugPrint('Task update error: $e');

      if (!mounted) return;

      setState(() {
        task.isCompleted = previousStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update task.'),
        ),
      );
    }
  }

  // Delete task and cancel its notification.
  Future<void> deleteTask(TaskModel task) async {
    try {
      await NotificationService.cancelNotification(
        notificationId(task),
      );

      await TaskDatabase.deleteTask(task.id);

      if (!mounted) return;

      setState(() {
        tasks.remove(task);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully.'),
        ),
      );
    } catch (e) {
      debugPrint('Delete task error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete task.'),
        ),
      );
    }
  }

  // Display a list of tasks.
  Widget buildTaskList(List<TaskModel> taskList) {
    if (taskList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No tasks here',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: IconButton(
              onPressed: () => toggleTask(task),
              icon: Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: task.isCompleted
                    ? Colors.green
                    : Colors.blue,
                size: 30,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${task.dateTime.day}/'
                '${task.dateTime.month}/'
                '${task.dateTime.year}  '
                '${task.dateTime.hour.toString().padLeft(2, '0')}:'
                '${task.dateTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
            trailing: IconButton(
              onPressed: () => deleteTask(task),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              tooltip: 'Delete task',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks
        .where((task) => !task.isCompleted)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final completedTasks = tasks
        .where((task) => task.isCompleted)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My To-Do',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await NotificationService.showTestNotification();
              } catch (e) {
                debugPrint('Test notification error: $e');
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Notification',
          ),
        ],
      ),

      body: tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 75,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text('Tap + to create your first task'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pending (${pendingTasks.length})',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                buildTaskList(pendingTasks),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(
                      Icons.task_alt,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Done (${completedTasks.length})',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                buildTaskList(completedTasks),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

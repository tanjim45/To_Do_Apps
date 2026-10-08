import 'package:flutter/material.dart';
import 'package:todo_app/models/task_models.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TaskModel> tasks = [];

  // Add Task Page open করবে
  Future<void> addTask() async {
    final task = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskPage(),
      ),
    );

    // Add Task Page থেকে TaskModel ফেরত এলে
    if (task != null && task is TaskModel) {
      setState(() {
        tasks.add(task);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My To-Do',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: task.isCompleted
                          ? Colors.green
                          : Colors.blue,
                    ),
                    title: Text(task.title),
                    subtitle: Text(
                      '${task.dateTime.day}/'
                      '${task.dateTime.month}/'
                      '${task.dateTime.year} '
                      '${task.dateTime.hour}:'
                      '${task.dateTime.minute.toString().padLeft(2, '0')}',
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

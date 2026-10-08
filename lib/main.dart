import 'package:flutter/material.dart';
import 'package:todo_app/screen/home_screen.dart';
import 'package:todo_app/sevice/notification_service.dart';
import 'package:todo_app/sevice/task_database.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TaskDatabase.init();
  await NotificationService.init();

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My To-Do',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}


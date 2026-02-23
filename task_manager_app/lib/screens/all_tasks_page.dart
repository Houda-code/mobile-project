import 'package:flutter/material.dart';

class AllTasksPage extends StatelessWidget {

  final List<String> tasks;

  AllTasksPage({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Icon(Icons.task_alt),
            title: Text(tasks[index]),
          ),
        );
      },
    );
  }
}
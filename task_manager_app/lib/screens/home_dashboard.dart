import 'package:flutter/material.dart';

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: Icon(Icons.task),
              title: Text("Tasks due today"),
              subtitle: Text("3 tasks"),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.warning),
              title: Text("Overdue tasks"),
              subtitle: Text("1 task"),
            ),
          ),
        ],
      ),
    );
  }
}
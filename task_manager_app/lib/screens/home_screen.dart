import 'package:flutter/material.dart';
import 'home_dashboard.dart';
import 'all_tasks_page.dart';
import 'calendar_page.dart';
import 'statistics_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int selectedIndex = 0; // 1 = All Tasks (default)

  final List<String> tasks = [
    "Math homework",
    "Physics revision",
    "Prepare presentation",
    "Read biology chapter"
  ];

  Widget getScreen() {
    switch (selectedIndex) {
      case 0:
        return HomeDashboard();
      case 1:
        return AllTasksPage(tasks: tasks);
      case 2:
        return CalendarPage();
      case 3:
        return StatisticsPage();
      case 4:
        return ProfilePage();
      default:
        return HomeDashboard();
    }
  }

  Widget buildAllTasks() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Icon(Icons.task_alt),
            title: Text(tasks[index]),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // later open task details
            },
          ),
        );
      },
    );
  }

  void selectMenu(int index) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Manager"),
      ),

      drawer: Drawer(
        child: ListView(
          children: [

            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            ListTile(
              leading: Icon(Icons.home),
              title: Text("Home"),
              onTap: () => selectMenu(0),
            ),

            ListTile(
              leading: Icon(Icons.checklist),
              title: Text("All Tasks"),
              onTap: () => selectMenu(1),
            ),

            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text("Calendar"),
              onTap: () => selectMenu(2),
            ),

            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text("Statistics"),
              onTap: () => selectMenu(3),
            ),

            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () => selectMenu(4),
            ),

            Divider(),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      body: getScreen(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // later add task
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
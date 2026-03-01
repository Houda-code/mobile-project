import 'package:flutter/material.dart';
import 'professor_dashboard.dart';
import 'profile_page.dart';
import 'loginscreen.dart';
import '../services/api_service.dart';

class ProfessorHomeScreen extends StatefulWidget {
  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  int selectedIndex = 0;

  Widget getScreen() {
    switch (selectedIndex) {
      case 0:
        return ProfessorDashboard();
      case 1:
        return ProfilePage();
      default:
        return ProfessorDashboard();
    }
  }

  void selectMenu(int index) {
    setState(() => selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Professor Portal"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                "Professor",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () => selectMenu(0),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () => selectMenu(1),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () async {
                await ApiService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: getScreen(),
    );
  }
}

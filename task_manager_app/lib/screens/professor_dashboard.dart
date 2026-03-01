import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'assign_task_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_tasks_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getProfessorDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _professorName(Map<String, dynamic> data) {
    final prof = data["professor"];
    if (prof is Map<String, dynamic>) {
      final first = prof["firstName"]?.toString().trim() ?? "";
      final last = prof["lastName"]?.toString().trim() ?? "";
      final full = "$first $last".trim();
      if (full.isNotEmpty) return full;
    }
    return "";
  }

  String _studentName(Map<String, dynamic> student) {
    final first = student["firstName"]?.toString().trim() ?? "";
    final last = student["lastName"]?.toString().trim() ?? "";
    final full = "$first $last".trim();
    if (full.isNotEmpty) return full;
    return student["email"]?.toString() ?? "Student";
  }

  String _initials(Map<String, dynamic> student) {
    final first = student["firstName"]?.toString().trim() ?? "";
    final last = student["lastName"]?.toString().trim() ?? "";
    final a = first.isNotEmpty ? first[0] : "";
    final b = last.isNotEmpty ? last[0] : "";
    final initials = (a + b).toUpperCase();
    if (initials.isNotEmpty) return initials;
    final email = student["email"]?.toString() ?? "";
    if (email.isNotEmpty) return email[0].toUpperCase();
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final classes = _data["classes"];
    final classList = classes is List ? classes.cast<Map<String, dynamic>>() : [];
    final name = _professorName(_data);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            name.isNotEmpty ? "Hi Professor $name" : "Hi Professor",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (classList.isEmpty)
            Text("No classes assigned")
          else
            ...classList.map((cls) {
              final className = cls["className"]?.toString() ?? "Class";
              final studentsRaw = cls["students"];
              final students = studentsRaw is List
                  ? studentsRaw.cast<Map<String, dynamic>>()
                  : <Map<String, dynamic>>[];

              return Card(
                child: ExpansionTile(
                  title: Text(className),
                  subtitle: Text("${students.length} students"),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.playlist_add),
                          label: Text("Assign task to class"),
                          onPressed: () async {
                            final created = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignTaskScreen(className: className),
                              ),
                            );
                            if (created == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Task assigned to $className")),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    if (students.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No students in this class"),
                      )
                    else
                      ...students.map((student) {
                          final id = student["id"];
                          final name = _studentName(student);
                          final email = student["email"]?.toString() ?? "";

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_initials(student)),
                            ),
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: "View dashboard",
                                  icon: Icon(Icons.dashboard),
                                  onPressed: () {
                                    if (id is! int) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentDashboardScreen(
                                          studentId: id,
                                          studentName: name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: "View tasks",
                                  icon: Icon(Icons.checklist),
                                  onPressed: () {
                                    if (id is! int) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentTasksScreen(
                                          studentId: id,
                                          studentName: name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: "Assign task",
                                  icon: Icon(Icons.add_task),
                                  onPressed: () async {
                                    if (id is! int) return;
                                    final created = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AssignTaskScreen(
                                          studentId: id,
                                          studentName: name,
                                        ),
                                      ),
                                    );
                                    if (created == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Task assigned to $name")),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

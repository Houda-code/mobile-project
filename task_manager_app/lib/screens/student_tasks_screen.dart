import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentTasksScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentTasksScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends State<StudentTasksScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tasks = [];

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
      final data = await ApiService.getProfessorStudentTasks(widget.studentId);
      final tasks = data["tasks"];
      if (!mounted) return;
      setState(() {
        _tasks = tasks is List ? tasks.cast<Map<String, dynamic>>() : [];
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

  Color _priorityColor(String? value) {
    switch (value) {
      case "high":
        return Colors.red.shade400;
      case "medium":
        return Colors.orange.shade500;
      case "low":
      default:
        return Colors.green.shade500;
    }
  }

  String _priorityLabel(String? value) {
    switch (value) {
      case "high":
        return "High";
      case "medium":
        return "Medium";
      case "low":
      default:
        return "Low";
    }
  }

  String _statusLabel(String? value) {
    switch (value) {
      case "in_progress":
        return "In Progress";
      case "completed":
        return "Done";
      case "pending":
      default:
        return "Todo";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks • ${widget.studentName}"),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : _tasks.isEmpty
                  ? Center(child: Text("No tasks"))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          final title = task["title"]?.toString() ?? "Untitled";
                          final description = task["description"]?.toString();
                          final status = task["status"]?.toString();
                          final priority = task["priority"]?.toString();
                          final deadlineRaw = task["deadline"]?.toString();
                          final deadline = (deadlineRaw != null && deadlineRaw.isNotEmpty)
                              ? DateTime.tryParse(deadlineRaw)
                              : null;
                          final deadlineLabel = deadline == null
                              ? "No deadline"
                              : "${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}";
                          final color = _priorityColor(priority);

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(Icons.task_alt, color: color),
                              ),
                              title: Text(title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (description != null && description.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(description),
                                    ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _priorityLabel(priority),
                                            style: TextStyle(color: color, fontSize: 12),
                                          ),
                                        ),
                                        Text(
                                          _statusLabel(status),
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                        Text(
                                          deadlineLabel,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

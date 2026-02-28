import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_task_screen.dart';

class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => AllTasksPageState();
}

class AllTasksPageState extends State<AllTasksPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await ApiService.getAllTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load tasks";
        _loading = false;
      });
    }
  }

  Future<void> reload() async {
    await _loadTasks();
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

  Future<void> _editTask(Map<String, dynamic> task) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );

    if (updated == true) {
      await _loadTasks();
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final id = task["id"];
    if (id is! int) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete task?"),
        content: Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteTask(id);
      if (!mounted) return;
      await _loadTasks();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete task")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_tasks.isEmpty) {
      return Center(child: Text("No tasks yet"));
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: "Edit Task",
                    child: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editTask(task),
                    ),
                  ),
                  Tooltip(
                    message: "Delete Task",
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteTask(task),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

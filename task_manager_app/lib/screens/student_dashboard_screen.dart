import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentDashboardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};

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
      final data = await ApiService.getProfessorStudentSummary(widget.studentId);
      if (!mounted) return;
      setState(() {
        _summary = data;
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

  int _statValue(Map<String, dynamic>? stats, String key) {
    final value = stats?[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _taskList(dynamic value) {
    if (value is List) return value.cast<Map<String, dynamic>>();
    return [];
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "No deadline";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return "No deadline";
    return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        subtitle: Text("$value"),
      ),
    );
  }

  Widget _taskSection(String title, List<Map<String, dynamic>> tasks, String emptyLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        if (tasks.isEmpty)
          Text(emptyLabel, style: TextStyle(color: Colors.grey[600]))
        else
          ...tasks.map((task) {
            final title = task["title"]?.toString() ?? "Untitled";
            final priority = task["priority"]?.toString();
            final deadline = task["deadline"]?.toString();
            final color = _priorityColor(priority);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.task_alt, color: color),
                ),
                title: Text(title),
                subtitle: Text(_formatDate(deadline)),
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _summary["stats"] as Map<String, dynamic>?;
    final today = _taskList(_summary["today"]);
    final overdue = _taskList(_summary["overdue"]);
    final upcoming = _taskList(_summary["upcoming"]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard • ${widget.studentName}"),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _statCard(
                        "Due Today",
                        _statValue(stats, "dueToday"),
                        Icons.today,
                        Colors.blue,
                      ),
                      _statCard(
                        "Overdue",
                        _statValue(stats, "overdue"),
                        Icons.warning_amber,
                        Colors.red,
                      ),
                      _statCard(
                        "Upcoming (7 days)",
                        _statValue(stats, "upcoming"),
                        Icons.schedule,
                        Colors.orange,
                      ),
                      _statCard(
                        "Completed",
                        _statValue(stats, "completed"),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      SizedBox(height: 16),
                      _taskSection("Due Today", today, "No tasks due today"),
                      SizedBox(height: 16),
                      _taskSection("Overdue", overdue, "No overdue tasks"),
                      SizedBox(height: 16),
                      _taskSection("Upcoming", upcoming, "No upcoming tasks"),
                    ],
                  ),
                ),
    );
  }
}

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
 
  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
 
  String _formatDateTime(DateTime? value) {
    if (value == null) return "No reminder set";
    final date = "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}";
    final time = "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}";
    return "$date $time";
  }
 
  Future<void> _manageReminder(Map<String, dynamic> task) async {
    final taskId = task["id"];
    if (taskId is! int) return;
 
    Map<String, dynamic>? reminder;
    try {
      reminder = await ApiService.getReminder(taskId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load reminder")),
      );
      return;
    }
 
    DateTime? reminderDateTime = _parseDateTime(reminder?["reminderDateTime"]?.toString());
    bool isActive = reminder?["isActive"] == true;
    bool isSaving = false;
    String? error;
 
    final deadline = _parseDateTime(task["deadline"]?.toString());
 
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final initial = reminderDateTime ?? now.add(Duration(hours: 1));
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(initial.year, initial.month, initial.day),
                firstDate: DateTime(now.year - 1, 1, 1),
                lastDate: DateTime(now.year + 5, 12, 31),
              );
 
              if (picked == null) return;
              final currentTime = reminderDateTime ?? now.add(Duration(hours: 1));
              setDialogState(() {
                reminderDateTime = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  currentTime.hour,
                  currentTime.minute,
                );
                error = null;
              });
            }
 
            Future<void> pickTime() async {
              final now = DateTime.now();
              final initial = reminderDateTime ?? now.add(Duration(hours: 1));
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
              );
              if (picked == null) return;
              setDialogState(() {
                final date = reminderDateTime ?? now.add(Duration(hours: 1));
                reminderDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  picked.hour,
                  picked.minute,
                );
                error = null;
              });
            }
 
            String? validateReminderDate() {
              if (reminderDateTime == null) {
                return "Select a reminder date and time";
              }
              final now = DateTime.now();
              if (!reminderDateTime!.isAfter(now)) {
                return "Reminder must be in the future";
              }
              if (deadline != null && reminderDateTime!.isAfter(deadline)) {
                return "Reminder must be before the task deadline";
              }
              return null;
            }
 
            Future<void> saveReminder() async {
              final validationError = validateReminderDate();
              if (validationError != null) {
                setDialogState(() => error = validationError);
                return;
              }
 
              setDialogState(() => isSaving = true);
              try {
                if (reminder == null) {
                  await ApiService.createReminder(
                    taskId: taskId,
                    reminderDateTime: reminderDateTime!,
                    isActive: isActive,
                  );
                } else {
                  await ApiService.updateReminder(
                    taskId: taskId,
                    reminderDateTime: reminderDateTime,
                    isActive: isActive,
                  );
                }
                if (!mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (e) {
                setDialogState(() {
                  error = "Failed to save reminder";
                });
              } finally {
                if (mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }
 
            Future<void> deleteReminder() async {
              setDialogState(() => isSaving = true);
              try {
                await ApiService.deleteReminder(taskId);
                if (!mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (_) {
                setDialogState(() {
                  error = "Failed to delete reminder";
                });
              } finally {
                if (mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }
 
            return AlertDialog(
              title: Text("Reminder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task["title"]?.toString() ?? "Task"),
                  SizedBox(height: 12),
                  Text("Date & Time"),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSaving ? null : pickDate,
                          icon: Icon(Icons.calendar_today, size: 18),
                          label: Text(reminderDateTime == null
                              ? "Select date"
                              : "${reminderDateTime!.year}-${reminderDateTime!.month.toString().padLeft(2, '0')}-${reminderDateTime!.day.toString().padLeft(2, '0')}"),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSaving ? null : pickTime,
                          icon: Icon(Icons.access_time, size: 18),
                          label: Text(reminderDateTime == null
                              ? "Select time"
                              : "${reminderDateTime!.hour.toString().padLeft(2, '0')}:${reminderDateTime!.minute.toString().padLeft(2, '0')}"),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatDateTime(reminderDateTime),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                  SwitchListTile(
                    value: isActive,
                    onChanged: isSaving
                        ? null
                        : (value) => setDialogState(() => isActive = value),
                    title: Text("Active"),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (error != null) ...[
                    SizedBox(height: 8),
                    Text(error!, style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                if (reminder != null)
                  TextButton(
                    onPressed: isSaving ? null : deleteReminder,
                    child: Text("Delete"),
                  ),
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext, false),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveReminder,
                  child: isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(reminder == null ? "Add" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
 
    if (mounted) {
      await _loadTasks();
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
          final reminder = task["Reminder"];
          final bool hasActiveReminder =
              reminder is Map<String, dynamic> && reminder["isActive"] == true;
 
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
                    message: hasActiveReminder ? "Edit reminder" : "Add reminder",
                    child: IconButton(
                      icon: Icon(
                        hasActiveReminder ? Icons.notifications_active : Icons.notifications_none,
                      ),
                      color: hasActiveReminder ? Colors.amber[700] : Colors.grey[600],
                      onPressed: () => _manageReminder(task),
                    ),
                  ),
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
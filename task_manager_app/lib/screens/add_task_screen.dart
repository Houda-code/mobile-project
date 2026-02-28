import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Map<String, dynamic>? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  bool _isSaving = false;
  DateTime? _deadline;
  String _status = "pending";
  String _priority = "medium";

  static const Map<String, String> _statusLabels = {
    "pending": "Todo",
    "in_progress": "In Progress",
    "completed": "Done",
  };

  static const Map<String, String> _priorityLabels = {
    "low": "Low",
    "medium": "Medium",
    "high": "High",
  };

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task["title"]?.toString() ?? "";
      _descriptionController.text = task["description"]?.toString() ?? "";

      final deadlineRaw = task["deadline"]?.toString();
      if (deadlineRaw != null && deadlineRaw.isNotEmpty) {
        _deadline = DateTime.tryParse(deadlineRaw);
      }

      final statusRaw = task["status"]?.toString();
      if (statusRaw != null && _statusLabels.containsKey(statusRaw)) {
        _status = statusRaw;
      }

      final priorityRaw = task["priority"]?.toString();
      if (priorityRaw != null && _priorityLabels.containsKey(priorityRaw)) {
        _priority = priorityRaw;
      }
    }

    _deadlineController.text = _formatDate(_deadline);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return "";
    return "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked != null) {
      setState(() {
        _deadline = DateTime(picked.year, picked.month, picked.day);
        _deadlineController.text = _formatDate(_deadline);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.task == null) {
        await ApiService.createTask(
          title: title,
          description: description.isEmpty ? null : description,
          deadline: _deadline,
          status: _status,
          priority: _priority,
        );
      } else {
        final id = widget.task?["id"];
        if (id is! int) {
          throw Exception("Invalid task id");
        }

        await ApiService.updateTask(
          id: id,
          title: title,
          description: description,
          deadline: _deadline,
          status: _status,
          priority: _priority,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add task")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Task" : "Add Task"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Title is required";
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Description (optional)"),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: "Status"),
                items: _statusLabels.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(labelText: "Priority"),
                items: _priorityLabels.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _priority = value);
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Deadline",
                  hintText: "YYYY-MM-DD",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _pickDeadline,
                  ),
                ),
                onTap: _pickDeadline,
              ),
              if (_deadline != null) ...[
                SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _deadline = null;
                      _deadlineController.text = "";
                    }),
                    child: Text("Clear deadline"),
                  ),
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? "Update Task" : "Create Task"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

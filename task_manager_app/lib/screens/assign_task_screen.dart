import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;
  final String? className;

  const AssignTaskScreen({
    super.key,
    this.studentId,
    this.studentName,
    this.className,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  bool _saving = false;
  DateTime? _deadline;
  String _priority = "medium";

  static const Map<String, String> _priorityLabels = {
    "low": "Low",
    "medium": "Medium",
    "high": "High",
  };

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
    setState(() => _saving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.studentId != null) {
        await ApiService.createTaskForStudent(
          studentId: widget.studentId!,
          title: title,
          description: description.isEmpty ? null : description,
          deadline: _deadline,
          priority: _priority,
        );
      } else if (widget.className != null) {
        await ApiService.createTaskForClass(
          className: widget.className!,
          title: title,
          description: description.isEmpty ? null : description,
          deadline: _deadline,
          priority: _priority,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = widget.studentName != null
        ? "Student: ${widget.studentName}"
        : "Class: ${widget.className}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Task"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(targetLabel, style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text("Assign Task"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

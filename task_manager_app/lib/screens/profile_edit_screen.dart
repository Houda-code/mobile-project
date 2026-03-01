import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _className;
  Set<String> _classNames = {};
  bool _saving = false;

  static const List<String> _classOptions = [
    "ALINFO1",
    "ALINFO2",
    "ALINFO3",
    "ALINFO4",
    "ALINFO5",
    "ALINFO6",
    "ALINFO7",
    "ALINFO8",
    "ALINFO9",
    "ALINFO10",
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user["firstName"]?.toString() ?? "";
    _lastNameController.text = widget.user["lastName"]?.toString() ?? "";
    _emailController.text = widget.user["email"]?.toString() ?? "";
    final className = widget.user["className"]?.toString();
    if (className != null && className.isNotEmpty) {
      _className = className;
    }
    final classNamesRaw = widget.user["classNames"];
    if (classNamesRaw is List) {
      _classNames = classNamesRaw.map((e) => e.toString()).toSet();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email';
    return null;
  }

  String? _classValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Class is required';
    }
    return null;
  }

  String? _classListValidator() {
    if (_classNames.isEmpty) {
      return 'Select at least one class';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final role = widget.user["role"]?.toString();
      final updated = await ApiService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        className: role == "PROFESSOR" ? null : _className,
        classNames: role == "PROFESSOR" ? _classNames.toList() : null,
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
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
    final role = widget.user["role"]?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: _required,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: _required,
              ),
              SizedBox(height: 12),
              if (role == "PROFESSOR")
                FormField<Set<String>>(
                  validator: (_) => _classListValidator(),
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Classes', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _classOptions.map((value) {
                            final selected = _classNames.contains(value);
                            return FilterChip(
                              label: Text(value),
                              selected: selected,
                              onSelected: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    _classNames.add(value);
                                  } else {
                                    _classNames.remove(value);
                                  }
                                  field.didChange(_classNames);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              field.errorText ?? '',
                              style: TextStyle(color: Colors.red[700], fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                )
              else
                DropdownButtonFormField<String>(
                  value: _className,
                  decoration: InputDecoration(labelText: 'Class Name'),
                  items: _classOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _className = value);
                  },
                  validator: _classValidator,
                ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
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
                      : Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

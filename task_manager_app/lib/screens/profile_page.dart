import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'profile_edit_screen.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _user;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _loadProfile();
  }

  Future<void> _loadCached() async {
    final cached = await ApiService.getCachedUser();
    if (!mounted) return;
    if (cached != null) {
      setState(() => _user = cached);
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _user = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load profile";
        _loading = false;
      });
    }
  }

  String _displayName(Map<String, dynamic>? user) {
    if (user == null) return "";
    final display = user["displayName"]?.toString().trim();
    if (display != null && display.isNotEmpty) return display;
    final first = user["firstName"]?.toString().trim();
    final last = user["lastName"]?.toString().trim();
    final full = [first, last].where((v) => v != null && v!.isNotEmpty).join(" ");
    if (full.isNotEmpty) return full;
    final email = user["email"]?.toString().trim();
    return email ?? "";
  }

  String _initials(Map<String, dynamic>? user) {
    if (user == null) return "?";
    final first = user["firstName"]?.toString().trim();
    final last = user["lastName"]?.toString().trim();
    final a = (first != null && first.isNotEmpty) ? first[0] : "";
    final b = (last != null && last.isNotEmpty) ? last[0] : "";
    final initials = (a + b).toUpperCase();
    if (initials.isNotEmpty) return initials;
    final email = user["email"]?.toString().trim();
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return "?";
  }

  Widget _infoTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? "-" : value),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final updated = await ApiService.uploadProfilePhoto(File(picked.path));
      if (!mounted) return;
      setState(() {
        _user = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _openPhotoViewer() {
    final url = ApiService.resolveFileUrl(_user?["photoUrl"]?.toString());
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          photoUrl: url,
          initials: _initials(_user),
          onChangePhoto: _pickAndUploadPhoto,
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    if (_user == null) return;
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(user: _user!),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _user = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null && _user == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProfile,
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user ?? {};
    final name = _displayName(user);
    final email = user["email"]?.toString().trim() ?? "";
    final firstName = user["firstName"]?.toString().trim() ?? "";
    final lastName = user["lastName"]?.toString().trim() ?? "";
    final className = user["className"]?.toString().trim() ?? "";
    final role = user["role"]?.toString().trim() ?? "";
    final classNamesRaw = user["classNames"];
    final classNames = classNamesRaw is List
        ? classNamesRaw.map((e) => e.toString()).toList()
        : <String>[];
    final photoUrl = ApiService.resolveFileUrl(user["photoUrl"]?.toString());

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _openPhotoViewer,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          _initials(user),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "User" : name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    if (email.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          email,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: "Edit profile",
                    onPressed: _openEditProfile,
                    icon: Icon(Icons.edit),
                  ),
                  if (_loading || _uploadingPhoto)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _infoTile("First Name", firstName),
          _infoTile("Last Name", lastName),
          if (classNames.isNotEmpty)
            _infoTile("Classes", classNames.join(", "))
          else
            _infoTile("Class Name", className),
          _infoTile("Email", email),
          _infoTile("Role", role),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String photoUrl;
  final String initials;
  final VoidCallback onChangePhoto;

  const _PhotoViewer({
    required this.photoUrl,
    required this.initials,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Profile Photo'),
        actions: [
          TextButton(
            onPressed: onChangePhoto,
            child: Text(
              'Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: photoUrl.isNotEmpty
            ? InteractiveViewer(
                child: Image.network(photoUrl),
              )
            : CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white12,
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

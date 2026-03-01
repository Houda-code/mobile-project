import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'loginscreen.dart';
import 'professor_home_screen.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final cached = await ApiService.getCachedUser();
    if (cached != null) {
      setState(() {
        _user = cached;
        _loading = false;
      });
      return;
    }

    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _user = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return LoginScreen();
    }

    final role = _user?["role"]?.toString();
    if (role == "PROFESSOR") {
      return ProfessorHomeScreen();
    }

    return HomeScreen();
  }
}

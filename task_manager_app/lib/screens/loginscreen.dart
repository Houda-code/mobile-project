import 'package:flutter_login/flutter_login.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _role = "STUDENT";

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Task Manager',
      headerWidget: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Login as',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Student'),
                    value: "STUDENT",
                    groupValue: _role,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _role = value);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Professor'),
                    value: "PROFESSOR",
                    groupValue: _role,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _role = value);
                    },
                  ),
                ),
              ],
            ),
            if (_role == "STUDENT")
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: Text('Create a new account'),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Professors are added by admin',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
      userValidator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return 'Email is required';
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        if (!emailRegex.hasMatch(email)) return 'Invalid email';
        return null;
      },
      
      // Login API
      onLogin: (loginData) async {
        try {
          final email = loginData.name?.trim();
          final password = loginData.password;
          if (email == null || email.isEmpty || password == null || password.isEmpty) {
            return 'Email and password are required';
          }

          final res = await ApiService.login(
            email: email,
            password: password,
            role: _role,
          );

          if (res.containsKey('token')) {
            return null; // success
          } else {
            return res['message'] ?? 'Login failed';
          }
        } catch (e) {
          return 'Server error';
        }
      },

      onSubmitAnimationCompleted: () {
        // Navigate to home screen after login/register
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RoleRouter()),
        );
      },

      onRecoverPassword: (email) async {
        // Optional: add your password recovery API here
        return 'Not implemented yet';
      },
    );
  }
}
 
 

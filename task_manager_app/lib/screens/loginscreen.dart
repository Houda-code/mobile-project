import 'package:flutter_login/flutter_login.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
 
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Task Manager',
      headerWidget: Builder(
        builder: (context) => Column(
          children: [
            Text(
              'Welcome back',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: Text('Create a new account'),
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
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      },
 
      onRecoverPassword: (email) async {
        // Optional: add your password recovery API here
        return 'Not implemented yet';
      },
    );
  }
}
 
 
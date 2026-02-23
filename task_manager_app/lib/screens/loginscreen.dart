import 'package:flutter_login/flutter_login.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Task Manager',
      
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

      // Register API
      onSignup: (signupData) async {
        try {
          final email = signupData.name?.trim();
          final password = signupData.password;
          if (email == null || email.isEmpty || password == null || password.isEmpty) {
            return 'Email and password are required';
          }

          final res = await ApiService.register(
            firstName: email, // adapt if you want fullName vs first/last
            lastName: 'LastName',       // temporary placeholder
            className: 'ClassName',     // temporary placeholder
            email: email,
            password: password,
          );

          if (res['message'] == 'User registered successfully') {
            return null; // success
          } else {
            return res['message'] ?? 'Registration failed';
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

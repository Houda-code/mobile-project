import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace this with your backend URL
  static const String baseUrl = "http://10.0.2.2:3000/api"; // 10.0.2.2 = localhost for Android emulator

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String className,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "className": className,
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }
}

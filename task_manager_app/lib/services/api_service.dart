import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Replace this with your backend URL
  static const String baseUrl = "http://10.0.2.2:3000/api"; // 10.0.2.2 = localhost for Android emulator
  static const String _tokenKey = "auth_token";

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

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data["token"];
      if (token is String && token.isNotEmpty) {
        await _saveToken(token);
      }
    }

    return data;
  }

  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/tasks"),
      headers: _authHeaders(token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    }

    final data = _decodeJson(response.body);
    throw Exception(data["message"] ?? "Failed to load tasks");
  }

  static Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? status,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final body = <String, dynamic>{
      "title": title,
    };
    if (description != null && description.isNotEmpty) {
      body["description"] = description;
    }
    if (deadline != null) {
      body["deadline"] = deadline.toIso8601String();
    }
    if (priority != null && priority.isNotEmpty) {
      body["priority"] = priority;
    }
    if (status != null && status.isNotEmpty) {
      body["status"] = status;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/tasks/create"),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to create task");
  }

  static Future<Map<String, dynamic>> updateTask({
    required int id,
    required String title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? status,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final body = <String, dynamic>{
      "title": title,
    };
    if (description != null) body["description"] = description;
    if (deadline != null) body["deadline"] = deadline.toIso8601String();
    if (priority != null && priority.isNotEmpty) body["priority"] = priority;
    if (status != null && status.isNotEmpty) body["status"] = status;

    final response = await http.put(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to update task");
  }

  static Future<void> deleteTask(int id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: _authHeaders(token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final data = _decodeJson(response.body);
    throw Exception(data["message"] ?? "Failed to delete task");
  }

  static Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  static Map<String, String> _authHeaders(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

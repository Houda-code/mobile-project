import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
 
class ApiService {
  // Replace this with your backend URL
  static const String baseHost = "http://10.0.2.2:3000"; // 10.0.2.2 = localhost for Android emulator
  static const String baseUrl = "$baseHost/api";
  static const String _tokenKey = "auth_token";
  static const String _userKey = "auth_user";
 
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
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "role": role,
      }),
    );
 
    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data["token"];
      if (token is String && token.isNotEmpty) {
        await _saveToken(token);
      }
      final user = data["user"];
      if (user is Map<String, dynamic>) {
        await _saveUser(user);
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
 
  static Future<Map<String, dynamic>> getHomeSummary() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }
 
    final response = await http.get(
      Uri.parse("$baseUrl/tasks/home/summary"),
      headers: _authHeaders(token),
    );
 
    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
 
    throw Exception(data["message"] ?? "Failed to load home summary");
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
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
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
    await prefs.remove(_userKey);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: _authHeaders(token),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data.isNotEmpty) {
        await _saveUser(data);
      }
      return data;
    }

    throw Exception(data["message"] ?? "Failed to load profile");
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? className,
    List<String>? classNames,
    String? email,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final body = <String, dynamic>{};
    if (firstName != null) body["firstName"] = firstName;
    if (lastName != null) body["lastName"] = lastName;
    if (className != null) body["className"] = className;
    if (classNames != null) body["classNames"] = classNames;
    if (email != null) body["email"] = email;

    final response = await http.put(
      Uri.parse("$baseUrl/auth/me"),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data.isNotEmpty) {
        await _saveUser(data);
      }
      return data;
    }

    throw Exception(data["message"] ?? "Failed to update profile");
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(File file) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/auth/photo"),
    );
    request.headers.addAll({
      "Authorization": "Bearer $token",
    });
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data.isNotEmpty) {
        await _saveUser(data);
      }
      return data;
    }

    final message = data["message"] ??
        (response.body.isNotEmpty ? response.body : "Failed to upload photo");
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> getProfessorDashboard() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/professor/dashboard"),
      headers: _authHeaders(token),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to load professor dashboard");
  }

  static Future<Map<String, dynamic>> getProfessorStudentTasks(int studentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/professor/students/$studentId/tasks"),
      headers: _authHeaders(token),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to load student tasks");
  }

  static Future<Map<String, dynamic>> getProfessorStudentSummary(int studentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/professor/students/$studentId/summary"),
      headers: _authHeaders(token),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to load student summary");
  }

  static Future<void> createTaskForStudent({
    required int studentId,
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
      Uri.parse("$baseUrl/professor/students/$studentId/tasks"),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data["message"] ?? "Failed to create task for student");
  }

  static Future<void> createTaskForClass({
    required String className,
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
      Uri.parse("$baseUrl/professor/classes/$className/tasks"),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data["message"] ?? "Failed to create task for class");
  }

  static String resolveFileUrl(String? path) {
    if (path == null || path.trim().isEmpty) return "";
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return path;
    }
    return "$baseHost$path";
  }
}
 
 

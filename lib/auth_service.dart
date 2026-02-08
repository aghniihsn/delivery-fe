import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://192.168.45.106:5000/api/auth';

  /// Login dan simpan token + data user ke SharedPreferences
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('userName', data['name']);
        await prefs.setString('userId', data['_id']);

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  /// Register user baru
  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password, {
    String role = 'driver',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('userName', data['name']);
        await prefs.setString('userId', data['_id']);

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      print('Register Error: $e');
      return null;
    }
  }

  /// Cek apakah user sudah login (ada token tersimpan)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Ambil token yang tersimpan
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Ambil role user yang tersimpan
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// Ambil nama user yang tersimpan
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  /// Logout - hapus semua data sesi
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Alias untuk logout
  Future<void> signOut() async {
    await logout();
  }
}

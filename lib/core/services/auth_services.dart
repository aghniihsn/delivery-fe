import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:praktikum_1/core/constants/api_constants.dart';

class AuthService {
  final String baseUrl = ApiConstants.authUrl;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('userName', data['name']);
        await prefs.setString('userId', data['_id']);
        await prefs.setBool(
          'profileCompleted',
          data['profileCompleted'] ?? false,
        );
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {'error': 'Tidak bisa terhubung ke server: $e'};
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');
  Future<String?> getRole() async =>
      (await SharedPreferences.getInstance()).getString('role');
  Future<String?> getUserName() async =>
      (await SharedPreferences.getInstance()).getString('userName');

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profileCompleted') ?? false;
  }

  Future<void> setProfileCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileCompleted', value);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }
}

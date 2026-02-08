import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:praktikum_1/delivery_task_model.dart';
import 'package:praktikum_1/auth_service.dart';

class ApiService {
  final String baseUrl = 'http://192.168.66.106:5000/api';
  final AuthService _authService = AuthService();

  /// Header dengan Bearer Token
  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar tugas pengiriman milik driver yang login
  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => DeliveryTask.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else {
        throw Exception('Gagal memuat data tugas');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Selesaikan tugas pengiriman dengan upload bukti foto
  Future<Map<String, dynamic>> completeTask(
    String taskId, {
    File? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('$baseUrl/tasks/complete/$taskId');

      if (imageFile != null) {
        // Multipart request untuk upload gambar
        final request = http.MultipartRequest('PUT', uri);
        request.headers['Authorization'] = 'Bearer $token';

        final extension = imageFile.path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Gagal menyelesaikan tugas');
        }
      } else {
        // Tanpa gambar
        final headers = await _authHeaders();
        final response = await http.put(uri, headers: headers);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Gagal menyelesaikan tugas');
        }
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ======================== DRIVER PROFILE API ========================

  /// Ambil profil user yang sedang login
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else {
        throw Exception('Gagal memuat profil');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Update profil driver (nama, phone)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode({'name': name, 'phone': phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Ganti password driver
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/change-password'),
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  // ======================== ADMIN API ========================

  /// [ADMIN] Ambil semua user (drivers)
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya admin yang bisa mengakses.');
      } else {
        throw Exception('Gagal memuat data pengguna');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// [ADMIN] Register kurir baru via backend
  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'driver',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mendaftarkan kurir');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// [ADMIN] Ambil semua tugas pengiriman
  Future<List<DeliveryTask>> fetchAllTasks() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => DeliveryTask.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya admin yang bisa mengakses.');
      } else {
        throw Exception('Gagal memuat data tugas');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// [ADMIN] Buat tugas pengiriman baru
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String taskId,
    required String assignedTo,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{
        'title': title,
        'taskId': taskId,
        'assignedTo': assignedTo,
      };

      if (address != null || latitude != null || longitude != null) {
        body['destination'] = {
          if (address != null) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal membuat tugas');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}

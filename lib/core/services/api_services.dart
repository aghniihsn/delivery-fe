import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';
import 'package:praktikum_1/core/services/auth_services.dart';
import 'package:praktikum_1/core/constants/api_constants.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.tasksUrl}/my'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DeliveryTask.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat data tugas');
    }
  }

  Future<Map<String, dynamic>> updateTaskStatus({
    required String taskId,
    required String status,
    String? notes,
    String? failedReason,
    String? rescheduledDate,
    String? rescheduledReason,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'status': status};

    if (notes != null) body['notes'] = notes;
    if (failedReason != null) body['failedReason'] = failedReason;
    if (rescheduledDate != null) body['rescheduledDate'] = rescheduledDate;
    if (rescheduledReason != null)
      body['rescheduledReason'] = rescheduledReason;

    final response = await http.patch(
      Uri.parse('${ApiConstants.tasksUrl}/$taskId/status'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal mengubah status');
  }

  Future<Map<String, dynamic>> uploadDeliveryProof(
    String taskId, {
    required File imageFile,
  }) async {
    final token = await _authService.getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConstants.tasksUrl}/$taskId/upload-proof'),
    );
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

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal upload bukti');
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final response = await http.get(
      Uri.parse(ApiConstants.usersUrl),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Gagal memuat data pengguna');
  }

  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.authUrl}/register'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': 'driver',
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Gagal mendaftarkan kurir');
  }

  Future<List<DeliveryTask>> fetchAllTasks() async {
    final response = await http.get(
      Uri.parse(ApiConstants.tasksUrl),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DeliveryTask.fromJson(item)).toList();
    }
    throw Exception('Gagal memuat semua tugas');
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    required String taskId,
    String? assignedTo,
    String? address,
  }) async {
    final body = {
      'title': title,
      'taskId': taskId,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (address != null) 'destination': {'address': address},
    };
    final response = await http.post(
      Uri.parse(ApiConstants.tasksUrl),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Gagal membuat tugas');
  }

  Future<Map<String, dynamic>> createBulkTasks(
    List<Map<String, dynamic>> tasks,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.tasksUrl}/bulk'),
        headers: headers,
        body: jsonEncode({'tasks': tasks}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal membuat tugas bulk');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<Map<String, dynamic>> assignTask({
    required String taskId,
    required String driverId,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.tasksUrl}/$taskId/assign'),
      headers: await _authHeaders(),
      body: jsonEncode({'assignedTo': driverId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal assign tugas');
  }

  Future<Map<String, dynamic>> assignBatchTasks({
    required List<String> taskIds,
    required String driverId,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConstants.tasksUrl}/assign-batch'),
        headers: headers,
        body: jsonEncode({'taskIds': taskIds, 'assignedTo': driverId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal assign batch task');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.usersUrl}/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal memuat profil');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.usersUrl}/profile'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal update profil');
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.usersUrl}/change-password'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal mengubah password');
  }
}

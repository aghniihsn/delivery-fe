import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:praktikum_1/delivery_task_model.dart';
import 'package:praktikum_1/auth_service.dart';

class ApiService {
  final String baseUrl = 'http://192.168.45.106:5000/api';
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
}

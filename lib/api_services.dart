import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:praktikum_1/delivery_task_model.dart';

class ApiService {
  final String apiUrl =
      'https://jsonplaceholder.typicode.com/todos'; // Ganti dengan URL API yang sesuai

  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);

        List<DeliveryTask> tasks = body
            .map((dynamic item) => DeliveryTask.fromJson(item))
            .toList();

        return tasks;
      } else {
        throw Exception('Gagal memuat data dari API');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

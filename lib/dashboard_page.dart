import 'package:flutter/material.dart';
import 'package:praktikum_1/api_services.dart';
import 'package:praktikum_1/delivery_task_model.dart';
import 'package:praktikum_1/auth_service.dart';
import 'package:praktikum_1/delivery_detail_page.dart';
import 'package:praktikum_1/qr_scanner_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _navigateToQRScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Kode Terdeteksi: $result')));
    }
  }

  final ApiService _apiService = ApiService();
  late Future<List<DeliveryTask>> _tasksFuture;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.fetchDeliveryTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengiriman'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              _navigateToQRScanner();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DeliveryTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data pengiriman.'));
          } else {
            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(task.title),
                    subtitle: Text('ID Tugas: ${task.id}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryDetailPage(task: task),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

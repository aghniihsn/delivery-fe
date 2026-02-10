import 'package:flutter/material.dart';
import 'package:praktikum_1/core/services/api_services.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';
import 'package:praktikum_1/core/services/auth_services.dart';
import 'package:praktikum_1/ui/driver/delivery_detail_page.dart';
import 'package:praktikum_1/ui/driver/edit_profile_page.dart';
import 'package:praktikum_1/ui/driver/qr_scanner_page.dart';
import 'package:praktikum_1/ui/auth/login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  late Future<List<DeliveryTask>> _tasksFuture;
  String _userName = 'Driver';

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.fetchDeliveryTasks();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    if (mounted && name != null) {
      setState(() => _userName = name);
    }
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _apiService.fetchDeliveryTasks();
    });
  }

  void _showMsg(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToQRScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );

    if (scannedCode != null && mounted) {
      try {
        final List<DeliveryTask> tasks = await _apiService.fetchDeliveryTasks();
        final matchedTask = tasks.firstWhere(
          (t) => t.taskId == scannedCode,
          orElse: () => throw Exception('Paket tidak ditemukan'),
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetailPage(task: matchedTask),
          ),
        ).then((_) => _refreshTasks());
      } catch (e) {
        _showMsg('Gagal: ID "$scannedCode" tidak ditemukan.', isError: true);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'on_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'rescheduled':
        return Colors.amber.shade700;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'on_delivery':
        return Icons.local_shipping;
      case 'assigned':
        return Icons.assignment_ind;
      case 'rescheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DeliverWell Driver',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Halo, $_userName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _navigateToQRScanner,
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                ).then((_) => _loadUserName());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Tugas Aktif'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: FutureBuilder<List<DeliveryTask>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return _buildErrorView(snapshot.error.toString());
            }

            final allTasks = snapshot.data ?? [];
            final activeTasks = allTasks
                .where((t) => t.status != 'delivered')
                .toList();
            final completedTasks = allTasks
                .where((t) => t.status == 'delivered')
                .toList();

            return Column(
              children: [
                _buildHeaderStats(activeTasks.length, completedTasks.length),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTaskListView(activeTasks, 'Belum ada tugas aktif.'),
                      _buildTaskListView(
                        completedTasks,
                        'Belum ada tugas yang selesai.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refreshTasks,
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(int active, int done) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          _statCard(
            'Tugas Aktif',
            active.toString(),
            Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 12),
          _statCard(
            'Total Selesai',
            done.toString(),
            Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListView(List<DeliveryTask> tasks, String emptyMsg) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor(task.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(task.status),
                  color: _statusColor(task.status),
                  size: 24,
                ),
              ),
              title: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        task.taskId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  if (task.destination?.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.destination!.address!,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryDetailPage(task: task),
                  ),
                );
                _refreshTasks();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshTasks,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:praktikum_1/core/services/api_services.dart';
import 'package:praktikum_1/core/services/auth_services.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';
import 'package:praktikum_1/ui/admin/add_driver_page.dart';
import 'package:praktikum_1/ui/auth/login_page.dart';

import 'widgets/admin_summary_cards.dart';
import 'widgets/task_card_item.dart';
import 'widgets/create_task_sheet.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  late Future<List<Map<String, dynamic>>> _usersFuture;
  late Future<List<DeliveryTask>> _tasksFuture;
  String _adminName = 'Admin';
  List<Map<String, dynamic>> _cachedDrivers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadAdminName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _usersFuture = _apiService.fetchAllUsers().then((users) {
        _cachedDrivers = users.where((u) => u['role'] == 'driver').toList();
        return users;
      });
      _tasksFuture = _apiService.fetchAllTasks();
    });
  }

  Future<void> _loadAdminName() async {
    final name = await _authService.getUserName();
    if (mounted && name != null) {
      setState(() => _adminName = name);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  void _showCreateTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateTaskSheet(
        drivers: _cachedDrivers,
        onCreateSingle: (data) async {
          try {
            await _apiService.createTask(
              title: data['title'],
              taskId: data['taskId'],
              address: data['address'],
              assignedTo: data['assignedTo'],
            );
            _showMsg('Task berhasil dibuat');
            _loadData();
          } catch (e) {
            _showMsg(e.toString(), isError: true);
          }
        },
      ),
    );
  }

  void _showAssignDialog(DeliveryTask task) {
    String? selectedDriverId;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Kurir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ID: ${task.taskId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: InputDecoration(
                      labelText: 'Pilih Kurir',
                      prefixIcon: const Icon(Icons.delivery_dining),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _cachedDrivers
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d['_id'],
                            child: Text(d['name'] ?? 'No Name'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedDriverId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedDriverId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await _apiService.assignTask(
                              taskId: task.id,
                              driverId: selectedDriverId!,
                            );
                            _showMsg('Kurir berhasil di-assign');
                            _loadData();
                          } catch (e) {
                            _showMsg(e.toString(), isError: true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Halo, $_adminName',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Kurir'),
            Tab(icon: Icon(Icons.assignment), text: 'Tugas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDriversTab(), _buildTasksTab()],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AddDriverPage()),
              );
              if (res == true) _loadData();
            },
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Tambah Kurir',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          return FloatingActionButton.extended(
            onPressed: _showCreateTaskDialog,
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.add_task, color: Colors.white),
            label: const Text(
              'Buat Task',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      },
    );
  }

  Widget _buildDriversTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text(snapshot.error.toString()));

          final drivers = snapshot.data!
              .where((u) => u['role'] == 'driver')
              .toList();
          if (drivers.isEmpty)
            return const Center(child: Text('Belum ada kurir terdaftar.'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: const Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(
                    d['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(d['email'] ?? '-'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTasksTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<DeliveryTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text(snapshot.error.toString()));

          final tasks = snapshot.data!;
          if (tasks.isEmpty)
            return const Center(child: Text('Belum ada tugas pengiriman.'));

          return Column(
            children: [
              AdminSummaryCards(
                pending: tasks.where((t) => t.isPending).length,
                assigned: tasks.where((t) => t.isAssigned).length,
                onDelivery: tasks.where((t) => t.isOnDelivery).length,
                delivered: tasks.where((t) => t.isCompleted).length,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => TaskCardItem(
                    task: tasks[index],
                    onTap: () {
                      /* Buka detail */
                    },
                    onAssign: () => _showAssignDialog(tasks[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

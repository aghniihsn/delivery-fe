import 'package:flutter/material.dart';
import 'package:praktikum_1/api_services.dart';
import 'package:praktikum_1/auth_service.dart';
import 'package:praktikum_1/delivery_task_model.dart';
import 'package:praktikum_1/ui/admin/add_driver_page.dart';
import 'package:praktikum_1/login_page.dart';

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

  // Cache drivers untuk assign dropdown
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
    _usersFuture = _apiService.fetchAllUsers()
      ..then((users) {
        _cachedDrivers = users.where((u) => u['role'] == 'driver').toList();
      });
    _tasksFuture = _apiService.fetchAllTasks();
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  Future<void> _loadAdminName() async {
    final name = await _authService.getUserName();
    if (mounted && name != null) {
      setState(() => _adminName = name);
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

  void _navigateToAddDriver() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddDriverPage()),
    );
    if (result == true && mounted) {
      _refreshData();
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
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Selesai';
      case 'on_delivery':
        return 'Pengiriman';
      case 'assigned':
        return 'Ditugaskan';
      case 'rescheduled':
        return 'Reschedule';
      case 'failed':
        return 'Gagal';
      case 'pending':
      default:
        return 'Menunggu';
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
      case 'pending':
      default:
        return Icons.radio_button_unchecked;
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
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
            heroTag: 'addDriver',
            onPressed: _navigateToAddDriver,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Kurir'),
          );
        } else {
          return FloatingActionButton.extended(
            heroTag: 'addTask',
            onPressed: () => _showCreateTaskDialog(),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_task),
            label: const Text('Buat Task'),
          );
        }
      },
    );
  }

  // ======================== TAB: KURIR ========================

  Widget _buildDriversTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmpty(
              icon: Icons.people_outline,
              message: 'Belum ada kurir terdaftar.',
            );
          }

          final users = snapshot.data!;
          final drivers = users.where((u) => u['role'] == 'driver').toList();

          if (drivers.isEmpty) {
            return _buildEmpty(
              icon: Icons.people_outline,
              message: 'Belum ada kurir terdaftar.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      (driver['name'] as String? ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  title: Text(
                    driver['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['email'] ?? '-',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (driver['phone'] != null &&
                          (driver['phone'] as String).isNotEmpty)
                        Text(
                          driver['phone'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Driver',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ======================== TAB: TUGAS ========================

  Widget _buildTasksTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: FutureBuilder<List<DeliveryTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmpty(
              icon: Icons.assignment_outlined,
              message: 'Belum ada tugas pengiriman.',
            );
          }

          final tasks = snapshot.data!;

          final pending = tasks.where((t) => t.status == 'pending').length;
          final assigned = tasks.where((t) => t.status == 'assigned').length;
          final onDelivery = tasks
              .where((t) => t.status == 'on_delivery')
              .length;
          final delivered = tasks.where((t) => t.status == 'delivered').length;
          final rescheduled = tasks
              .where((t) => t.status == 'rescheduled')
              .length;
          final failed = tasks.where((t) => t.status == 'failed').length;

          return Column(
            children: [
              // Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      'Menunggu',
                      pending,
                      Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    _buildSummaryCard('Assign', assigned, Colors.blue),
                    const SizedBox(width: 6),
                    _buildSummaryCard('Kirim', onDelivery, Colors.orange),
                    const SizedBox(width: 6),
                    _buildSummaryCard('Selesai', delivered, Colors.green),
                  ],
                ),
              ),
              if (rescheduled > 0 || failed > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      if (rescheduled > 0) ...[
                        _buildSummaryCard(
                          'Reschedule',
                          rescheduled,
                          Colors.amber.shade700,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (failed > 0)
                        _buildSummaryCard('Gagal', failed, Colors.red),
                    ],
                  ),
                ),
              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(DeliveryTask task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetailDialog(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _statusIcon(task.status),
                    color: _statusColor(task.status),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'ID: ${task.taskId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(task.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(task.status),
                      style: TextStyle(
                        color: _statusColor(task.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Info row
              Row(
                children: [
                  if (task.destination?.address != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.destination!.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.recipientName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      task.recipientName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              // Driver info + Actions
              Row(
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignedToName ?? 'Belum di-assign',
                      style: TextStyle(
                        fontSize: 12,
                        color: task.assignedToName != null
                            ? Colors.indigo
                            : Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (task.status == 'pending' || task.status == 'assigned')
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAssignDialog(task),
                        icon: const Icon(Icons.assignment_ind, size: 14),
                        label: Text(
                          task.status == 'pending' ? 'Assign' : 'Re-assign',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.indigo),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== DIALOG: BUAT TASK SATUAN ========================

  void _showCreateTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateTaskSheet(
        drivers: _cachedDrivers,
        onCreateSingle: _handleCreateSingleTask,
        onCreateBulk: _handleCreateBulkTasks,
      ),
    );
  }

  Future<void> _handleCreateSingleTask(Map<String, dynamic> taskData) async {
    try {
      await _apiService.createTask(
        title: taskData['title'],
        taskId: taskData['taskId'],
        description: taskData['description'],
        assignedTo: taskData['assignedTo'],
        address: taskData['address'],
        recipientName: taskData['recipientName'],
        recipientPhone: taskData['recipientPhone'],
        notes: taskData['notes'],
      );
      _showMsg('Task berhasil dibuat');
      _refreshData();
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _handleCreateBulkTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final result = await _apiService.createBulkTasks(tasks);
      _showMsg(result['message'] ?? '${tasks.length} task berhasil dibuat');
      _refreshData();
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  // ======================== DIALOG: ASSIGN TASK ========================

  void _showAssignDialog(DeliveryTask task) {
    String? selectedDriverId = task.assignedTo;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Task ke Kurir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task: ${task.title}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ID: ${task.taskId}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: InputDecoration(
                      labelText: 'Pilih Kurir',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_search),
                    ),
                    items: _cachedDrivers.map((d) {
                      return DropdownMenuItem(
                        value: d['_id'] as String,
                        child: Text(d['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedDriverId = val);
                    },
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
                          await _handleAssignTask(task.id, selectedDriverId!);
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

  Future<void> _handleAssignTask(String taskId, String driverId) async {
    try {
      await _apiService.assignTask(taskId: taskId, driverId: driverId);
      _showMsg('Task berhasil di-assign');
      _refreshData();
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  // ======================== DIALOG: DETAIL TASK ========================

  void _showTaskDetailDialog(DeliveryTask task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _statusIcon(task.status),
                color: _statusColor(task.status),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.title, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Task ID', task.taskId),
                _detailRow('Status', _statusLabel(task.status)),
                if (task.description.isNotEmpty)
                  _detailRow('Deskripsi', task.description),
                if (task.destination?.address != null)
                  _detailRow('Alamat', task.destination!.address!),
                if (task.recipientName.isNotEmpty)
                  _detailRow('Penerima', task.recipientName),
                if (task.recipientPhone.isNotEmpty)
                  _detailRow('HP Penerima', task.recipientPhone),
                if (task.notes.isNotEmpty) _detailRow('Catatan', task.notes),
                if (task.failedReason.isNotEmpty)
                  _detailRow('Alasan Gagal', task.failedReason),
                if (task.rescheduledReason.isNotEmpty)
                  _detailRow('Alasan Reschedule', task.rescheduledReason),
                if (task.rescheduledDate != null)
                  _detailRow(
                    'Tgl Reschedule',
                    _formatDate(task.rescheduledDate!),
                  ),
                _detailRow('Kurir', task.assignedToName ?? 'Belum di-assign'),
                if (task.assignedAt != null)
                  _detailRow('Di-assign', _formatDate(task.assignedAt!)),
                if (task.pickedUpAt != null)
                  _detailRow('Diambil', _formatDate(task.pickedUpAt!)),
                if (task.deliveredAt != null)
                  _detailRow('Terkirim', _formatDate(task.deliveredAt!)),
                if (task.createdAt != null)
                  _detailRow('Dibuat', _formatDate(task.createdAt!)),
              ],
            ),
          ),
          actions: [
            if (task.status == 'pending' || task.status == 'assigned')
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAssignDialog(task);
                },
                icon: const Icon(Icons.assignment_ind, size: 18),
                label: Text(task.status == 'pending' ? 'Assign' : 'Re-assign'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ======================== WIDGETS HELPER ========================

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    final errorMsg = error.replaceAll('Exception: ', '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ======================== CREATE TASK BOTTOM SHEET ========================

class _CreateTaskSheet extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final Future<void> Function(Map<String, dynamic>) onCreateSingle;
  final Future<void> Function(List<Map<String, dynamic>>) onCreateBulk;

  const _CreateTaskSheet({
    required this.drivers,
    required this.onCreateSingle,
    required this.onCreateBulk,
  });

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet>
    with SingleTickerProviderStateMixin {
  late TabController _modeTab;
  final _singleFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Single task fields
  final _titleCtrl = TextEditingController();
  final _taskIdCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedDriverId;

  // Bulk task fields
  final List<_BulkTaskEntry> _bulkEntries = [_BulkTaskEntry()];

  @override
  void initState() {
    super.initState();
    _modeTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _modeTab.dispose();
    _titleCtrl.dispose();
    _taskIdCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _notesCtrl.dispose();
    for (final e in _bulkEntries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _submitSingle() async {
    if (!_singleFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'taskId': _taskIdCtrl.text.trim(),
    };
    if (_descCtrl.text.trim().isNotEmpty) {
      data['description'] = _descCtrl.text.trim();
    }
    if (_addressCtrl.text.trim().isNotEmpty) {
      data['address'] = _addressCtrl.text.trim();
    }
    if (_recipientNameCtrl.text.trim().isNotEmpty) {
      data['recipientName'] = _recipientNameCtrl.text.trim();
    }
    if (_recipientPhoneCtrl.text.trim().isNotEmpty) {
      data['recipientPhone'] = _recipientPhoneCtrl.text.trim();
    }
    if (_notesCtrl.text.trim().isNotEmpty) {
      data['notes'] = _notesCtrl.text.trim();
    }
    if (_selectedDriverId != null) data['assignedTo'] = _selectedDriverId;

    await widget.onCreateSingle(data);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  Future<void> _submitBulk() async {
    // Validate all entries
    for (int i = 0; i < _bulkEntries.length; i++) {
      if (_bulkEntries[i].title.text.trim().isEmpty ||
          _bulkEntries[i].taskId.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Task #${i + 1}: Title dan Task ID wajib diisi'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        return;
      }
    }

    setState(() => _isLoading = true);

    final tasks = _bulkEntries.map((e) {
      final t = <String, dynamic>{
        'title': e.title.text.trim(),
        'taskId': e.taskId.text.trim(),
      };
      if (e.address.text.trim().isNotEmpty) {
        t['destination'] = {'address': e.address.text.trim()};
      }
      if (e.recipientName.text.trim().isNotEmpty) {
        t['recipientName'] = e.recipientName.text.trim();
      }
      if (e.driverId != null) t['assignedTo'] = e.driverId;
      return t;
    }).toList();

    await widget.onCreateBulk(tasks);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Buat Task Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TabBar(
            controller: _modeTab,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: const [
              Tab(text: 'Satuan'),
              Tab(text: 'Bulk'),
            ],
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: TabBarView(
                controller: _modeTab,
                children: [_buildSingleTaskForm(), _buildBulkTaskForm()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTaskForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _singleFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDec('Judul Task *', Icons.title),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taskIdCtrl,
              decoration: _inputDec('Task ID *', Icons.tag),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: _inputDec('Deskripsi', Icons.description),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: _inputDec('Alamat Tujuan', Icons.location_on),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientNameCtrl,
                    decoration: _inputDec('Nama Penerima', Icons.person),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _recipientPhoneCtrl,
                    decoration: _inputDec('HP Penerima', Icons.phone),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: _inputDec('Catatan', Icons.note),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: _inputDec(
                'Assign ke Kurir (opsional)',
                Icons.delivery_dining,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    '-- Tidak assign --',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ...widget.drivers.map((d) {
                  return DropdownMenuItem(
                    value: d['_id'] as String,
                    child: Text(d['name'] ?? 'Unknown'),
                  );
                }),
              ],
              onChanged: (val) => setState(() => _selectedDriverId = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitSingle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Membuat...' : 'Buat Task',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkTaskForm() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bulkEntries.length,
            itemBuilder: (context, index) {
              final entry = _bulkEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Task #${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_bulkEntries.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _bulkEntries[index].dispose();
                                  _bulkEntries.removeAt(index);
                                });
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: entry.title,
                        decoration: _inputDec('Judul *', Icons.title),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: entry.taskId,
                              decoration: _inputDec('Task ID *', Icons.tag),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: entry.recipientName,
                              decoration: _inputDec('Penerima', Icons.person),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: entry.address,
                        decoration: _inputDec('Alamat', Icons.location_on),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: entry.driverId,
                        decoration: _inputDec(
                          'Assign Kurir',
                          Icons.delivery_dining,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              '-- Skip --',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...widget.drivers.map((d) {
                            return DropdownMenuItem(
                              value: d['_id'] as String,
                              child: Text(
                                d['name'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) =>
                            setState(() => entry.driverId = val),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _bulkEntries.add(_BulkTaskEntry()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Task'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitBulk,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(
                    _isLoading
                        ? 'Loading...'
                        : 'Buat ${_bulkEntries.length} Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BulkTaskEntry {
  final TextEditingController title = TextEditingController();
  final TextEditingController taskId = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController recipientName = TextEditingController();
  String? driverId;

  void dispose() {
    title.dispose();
    taskId.dispose();
    address.dispose();
    recipientName.dispose();
  }
}

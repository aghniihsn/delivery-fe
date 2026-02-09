import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';
import 'package:praktikum_1/core/services/api_services.dart';

class DeliveryDetailPage extends StatefulWidget {
  final DeliveryTask task;

  const DeliveryDetailPage({super.key, required this.task});

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  final ApiService _apiService = ApiService();
  late DeliveryTask _task;
  XFile? _imageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
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

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Terkirim';
      case 'on_delivery':
        return 'Dalam Pengiriman';
      case 'assigned':
        return 'Ditugaskan';
      case 'rescheduled':
        return 'Dijadwalkan Ulang';
      case 'failed':
        return 'Gagal';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        _showMsg(
          'Gagal mengakses ${source == ImageSource.camera ? 'kamera' : 'galeri'}',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleCompleteDelivery(String notes) async {
    if (_imageFile == null) {
      _showMsg(
        'Wajib mengambil foto bukti sebelum menyelesaikan pengiriman!',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadResult = await _apiService.uploadDeliveryProof(
        _task.id,
        imageFile: File(_imageFile!.path),
      );

      final updateResult = await _apiService.updateTaskStatus(
        taskId: _task.id,
        status: 'delivered',
        notes: notes,
      );

      if (!mounted) return;

      _showMsg(updateResult['message'] ?? 'Pengiriman berhasil diselesaikan!');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMsg(
        'Gagal menyelesaikan pengiriman: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStatus(
    String newStatus, {
    String? notes,
    String? failedReason,
    String? rescheduledDate,
    String? rescheduledReason,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final result = await _apiService.updateTaskStatus(
        taskId: _task.id,
        status: newStatus,
        notes: notes,
        failedReason: failedReason,
        rescheduledDate: rescheduledDate,
        rescheduledReason: rescheduledReason,
      );

      if (!mounted) return;

      _showMsg(result['message'] ?? 'Status berhasil diperbarui');

      if (result['task'] != null) {
        setState(() {
          _task = DeliveryTask.fromJson(result['task'] as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMsg(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
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

  void _showPickupConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.local_shipping, color: Colors.orange, size: 48),
        title: const Text('Ambil Paket'),
        content: const Text(
          'Konfirmasi bahwa Anda telah mengambil paket ini dan siap mengantar ke tujuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('on_delivery');
            },
            icon: const Icon(Icons.local_shipping),
            label: const Text('Ya, Ambil Paket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveredConfirmation() {
    if (_imageFile == null) {
      _showMsg('Wajib mengambil foto bukti terlebih dahulu!', isError: true);
      return;
    }

    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Konfirmasi Terkirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Foto bukti sudah terlampir. Berikan catatan tambahan jika perlu.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Diterima oleh satpam',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCompleteDelivery(notesController.text);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Selesaikan Tugas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    final reasonController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: Icon(
                Icons.schedule,
                color: Colors.amber.shade700,
                size: 48,
              ),
              title: const Text('Jadwalkan Ulang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pilih tanggal pengiriman ulang dan alasannya.'),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : 'Pilih tanggal reschedule',
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Alasan reschedule',
                      hintText: 'Contoh: Penerima tidak di tempat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.info_outline),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: selectedDate == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _updateStatus(
                            'rescheduled',
                            rescheduledDate: selectedDate!.toIso8601String(),
                            rescheduledReason: reasonController.text,
                          );
                        },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Jadwalkan Ulang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFailedDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 48),
              title: const Text('Pengiriman Gagal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Jelaskan alasan pengiriman gagal.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Alasan gagal *',
                      hintText: 'Contoh: Alamat tidak ditemukan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.error_outline),
                    ),
                    maxLines: 3,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: reasonController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _updateStatus(
                            'failed',
                            failedReason: reasonController.text.trim(),
                          );
                        },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Tandai Gagal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRetryConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.refresh, color: Colors.orange, size: 48),
        title: const Text('Kirim Ulang'),
        content: const Text(
          'Konfirmasi bahwa Anda akan mencoba mengirim paket ini kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('on_delivery', notes: 'Percobaan pengiriman ulang');
            },
            icon: const Icon(Icons.local_shipping),
            label: const Text('Kirim Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Detail: ${_task.taskId}'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusProgress(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (_task.recipientName.isNotEmpty ||
                _task.recipientPhone.isNotEmpty)
              _buildRecipientCard(),

            if (_task.isOnDelivery || _task.isRescheduled) ...[
              const SizedBox(height: 16),
              _buildPhotoInputSection(),
            ],

            if (_task.isRescheduled) ...[
              const SizedBox(height: 16),
              _buildRescheduleInfoCard(),
            ],
            if (_task.isFailed && _task.failedReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFailedInfoCard(),
            ],
            if (_task.statusHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStatusHistoryCard(),
            ],
            if (_task.isCompleted) ...[
              const SizedBox(height: 20),
              _buildProofSection(),
            ],
            const SizedBox(height: 24),
            if (_task.canUpdateStatus && !_isSubmitting) _buildActionButtons(),
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_task.isCompleted && !_isSubmitting) _buildCompletedBanner(),
            if (_task.isFailed && !_isSubmitting) _buildFailedBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoInputSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Ambil Bukti Foto *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Wajib dilampirkan sebelum menandai paket terkirim.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        const Text(
                          'Gunakan Kamera',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                          PositionError(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_imageFile == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Pilih dari Galeri'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget PositionError({
    required double top,
    required double right,
    required Widget child,
  }) {
    return Positioned(top: top, right: right, child: child);
  }

  Widget _buildStatusProgress() {
    final stages = ['assigned', 'on_delivery', 'delivered'];
    final stageLabels = {
      'assigned': 'Ditugaskan',
      'on_delivery': 'Pengiriman',
      'delivered': 'Terkirim',
    };

    int currentIndex = stages.indexOf(_task.status);
    if (_task.isRescheduled) currentIndex = 1;
    if (_task.isFailed) currentIndex = 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusIcon(_task.status),
                  color: _statusColor(_task.status),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Saat Ini',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _statusLabel(_task.status),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(_task.status),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(_task.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _task.statusLabel,
                    style: TextStyle(
                      color: _statusColor(_task.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(stages.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final lineIndex = i ~/ 2;
                  final isActive = currentIndex > lineIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isActive
                          ? _statusColor(_task.status)
                          : Colors.grey.shade300,
                    ),
                  );
                } else {
                  final dotIndex = i ~/ 2;
                  final isActive = currentIndex >= dotIndex;
                  final isCurrent = currentIndex == dotIndex;
                  return Container(
                    width: isCurrent ? 18 : 14,
                    height: isCurrent ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? _statusColor(_task.status)
                          : Colors.grey.shade300,
                      border: isCurrent
                          ? Border.all(
                              color: _statusColor(_task.status),
                              width: 3,
                            )
                          : null,
                    ),
                    child: isActive && !isCurrent
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  );
                }
              }),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stages.map((s) {
                return Text(
                  stageLabels[s]!,
                  style: TextStyle(
                    fontSize: 10,
                    color: _statusColor(_task.status),
                    fontWeight: stages.indexOf(s) == currentIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.confirmation_number, 'ID Tugas', _task.taskId),
            if (_task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.description, 'Deskripsi', _task.description),
            ],
            if (_task.destination?.address != null) ...[
              const SizedBox(height: 8),
              _infoRow(
                Icons.location_on,
                'Alamat',
                _task.destination!.address!,
              ),
            ],
            if (_task.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.notes, 'Catatan', _task.notes),
            ],
            if (_task.createdAt != null) ...[
              const SizedBox(height: 8),
              _infoRow(
                Icons.calendar_today,
                'Dibuat',
                _formatDate(_task.createdAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Info Penerima',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_task.recipientName.isNotEmpty)
              _infoRow(Icons.badge, 'Nama', _task.recipientName),
            if (_task.recipientPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.phone, 'Telepon', _task.recipientPhone),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRescheduleInfoCard() {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Dijadwalkan Ulang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_task.rescheduledDate != null)
              _infoRow(
                Icons.calendar_month,
                'Tanggal',
                '${_task.rescheduledDate!.day}/${_task.rescheduledDate!.month}/${_task.rescheduledDate!.year}',
              ),
            if (_task.rescheduledReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.info_outline, 'Alasan', _task.rescheduledReason),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFailedInfoCard() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Alasan Gagal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _task.failedReason,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Riwayat Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_task.statusHistory.length, (i) {
              final entry =
                  _task.statusHistory[_task.statusHistory.length - 1 - i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(entry.to),
                          ),
                        ),
                        if (i < _task.statusHistory.length - 1)
                          Container(
                            width: 2,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_statusLabel(entry.from)} → ${_statusLabel(entry.to)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (entry.notes.isNotEmpty)
                            Text(
                              entry.notes,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (entry.changedAt != null)
                            Text(
                              _formatDate(entry.changedAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bukti Pengiriman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_task.imageUrl != null && _task.imageUrl!.isNotEmpty)
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _task.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_task.isAssigned) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _showPickupConfirmation,
          icon: const Icon(Icons.local_shipping, size: 28),
          label: const Text(
            'Ambil Paket & Mulai Pengiriman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
          ),
        ),
      );
    }

    if (_task.isOnDelivery) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _showDeliveredConfirmation,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Paket Terkirim',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _showRescheduleDialog,
                    icon: const Icon(Icons.schedule, size: 20),
                    label: const Text('Reschedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                      side: BorderSide(color: Colors.amber.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _showFailedDialog,
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text('Gagal Kirim'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (_task.isRescheduled) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _showRetryConfirmation,
          icon: const Icon(Icons.refresh, size: 28),
          label: const Text(
            'Coba Kirim Ulang',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            'Pengiriman telah selesai',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text(
            'Pengiriman gagal',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

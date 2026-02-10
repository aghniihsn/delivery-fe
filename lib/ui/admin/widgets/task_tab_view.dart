import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';
import 'package:praktikum_1/core/services/api_services.dart';

class TaskTabView extends StatefulWidget {
  final DeliveryTask initialTask;

  const TaskTabView({super.key, required this.initialTask});

  @override
  State<TaskTabView> createState() => _TaskTabViewState();
}

class _TaskTabViewState extends State<TaskTabView> {
  final ApiService _apiService = ApiService();
  late DeliveryTask _task;
  Timer? _pollingTimer;
  bool _isLive = true;
  bool _isRefreshing = false;

  // Map state
  double? _driverLat;
  double? _driverLng;
  DateTime? _locationUpdatedAt;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask;
    _startPolling();
    _fetchDriverLocation();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isLive) {
        _fetchLatest();
        _fetchDriverLocation();
      }
    });
  }

  Future<void> _fetchDriverLocation() async {
    if (_task.assignedTo == null) return;
    try {
      final data = await _apiService.getDriverLocation(_task.assignedTo!);
      if (data != null && data['location'] != null && mounted) {
        final loc = data['location'];
        if (loc['latitude'] != null && loc['longitude'] != null) {
          setState(() {
            _driverLat = (loc['latitude'] as num).toDouble();
            _driverLng = (loc['longitude'] as num).toDouble();
            _locationUpdatedAt = loc['updatedAt'] != null
                ? DateTime.tryParse(loc['updatedAt'])
                : null;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchLatest() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final updated = await _apiService.fetchTaskById(_task.id);
      if (mounted) {
        setState(() => _task = updated);
      }
    } catch (_) {
      // Silence polling errors
    } finally {
      _isRefreshing = false;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'on_delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'rescheduled':
        return Colors.purple;
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.person_pin;
      case 'on_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'rescheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detail & Live Tracking'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Live indicator
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: _isLive ? Colors.greenAccent : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _isLive ? 'LIVE' : 'PAUSED',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          IconButton(
            icon: Icon(_isLive ? Icons.pause : Icons.play_arrow),
            tooltip: _isLive ? 'Pause live tracking' : 'Resume live tracking',
            onPressed: () => setState(() => _isLive = !_isLive),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLatest),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatest,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(),
              const SizedBox(height: 16),
              _buildLiveMap(),
              const SizedBox(height: 16),
              _buildTaskInfo(),
              const SizedBox(height: 16),
              _buildDriverInfo(),
              const SizedBox(height: 16),
              _buildRecipientInfo(),
              const SizedBox(height: 16),
              _buildStatusTimeline(),
              if (_task.imageUrl != null && _task.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildProofImage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _statusColor(_task.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(_statusIcon(_task.status), size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _task.statusLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_task.taskId}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_isLive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    final bool hasDriverLocation = _driverLat != null && _driverLng != null;
    final bool hasDestination =
        _task.destination?.latitude != null &&
        _task.destination?.longitude != null;

    // Default center: driver location > destination > Indonesia
    final centerLat = _driverLat ?? _task.destination?.latitude ?? -6.2;
    final centerLng = _driverLng ?? _task.destination?.longitude ?? 106.8;

    final markers = <Marker>[];

    if (hasDriverLocation) {
      markers.add(
        Marker(
          point: LatLng(_driverLat!, _driverLng!),
          width: 50,
          height: 50,
          child: const Column(
            children: [
              Icon(Icons.local_shipping, color: Colors.orange, size: 32),
              Text(
                'Kurir',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (hasDestination) {
      markers.add(
        Marker(
          point: LatLng(
            _task.destination!.latitude!,
            _task.destination!.longitude!,
          ),
          width: 50,
          height: 50,
          child: const Column(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 32),
              Text(
                'Tujuan',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return _card(
      title: 'Peta Live Tracking',
      icon: Icons.map,
      children: [
        // Location info row
        if (hasDriverLocation && _locationUpdatedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'Update terakhir: ${_formatDate(_locationUpdatedAt!)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        if (!hasDriverLocation)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.gps_off, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  _task.assignedTo == null
                      ? 'Belum ada kurir yang di-assign'
                      : _task.isOnDelivery
                      ? 'Menunggu data GPS kurir...'
                      : 'GPS aktif saat status Dalam Pengiriman',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: hasDriverLocation ? 15 : 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.logitrack',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
        if (hasDriverLocation)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_driverLat!.toStringAsFixed(5)}, ${_driverLng!.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                TextButton.icon(
                  onPressed: () {
                    _mapController.move(LatLng(_driverLat!, _driverLng!), 16);
                  },
                  icon: const Icon(Icons.my_location, size: 14),
                  label: const Text(
                    'Fokus Kurir',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTaskInfo() {
    return _card(
      title: 'Informasi Tugas',
      icon: Icons.assignment,
      children: [
        _infoRow('Judul', _task.title),
        _infoRow(
          'Deskripsi',
          _task.description.isEmpty ? '-' : _task.description,
        ),
        if (_task.destination?.address != null)
          _infoRow('Alamat', _task.destination!.address!),
        if (_task.notes.isNotEmpty) _infoRow('Catatan', _task.notes),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return _card(
      title: 'Kurir',
      icon: Icons.delivery_dining,
      children: [
        _infoRow('Nama', _task.assignedToName ?? 'Belum di-assign'),
        if (_task.assignedAt != null)
          _infoRow('Di-assign pada', _formatDate(_task.assignedAt!)),
        if (_task.pickedUpAt != null)
          _infoRow('Diambil pada', _formatDate(_task.pickedUpAt!)),
        if (_task.deliveredAt != null)
          _infoRow('Dikirim pada', _formatDate(_task.deliveredAt!)),
      ],
    );
  }

  Widget _buildRecipientInfo() {
    if (_task.recipientName.isEmpty && _task.recipientPhone.isEmpty) {
      return const SizedBox.shrink();
    }
    return _card(
      title: 'Penerima',
      icon: Icons.person_outline,
      children: [
        if (_task.recipientName.isNotEmpty)
          _infoRow('Nama', _task.recipientName),
        if (_task.recipientPhone.isNotEmpty)
          _infoRow('No. HP', _task.recipientPhone),
      ],
    );
  }

  Widget _buildStatusTimeline() {
    // Build the stepper steps from status flow + history
    final allSteps = <_TimelineStep>[];

    // Created
    allSteps.add(
      _TimelineStep(
        title: 'Task Dibuat',
        subtitle: _task.createdAt != null ? _formatDate(_task.createdAt!) : '-',
        isDone: true,
        icon: Icons.note_add,
        color: Colors.grey,
      ),
    );

    // Assigned
    final isAssigned = _task.status != 'pending';
    allSteps.add(
      _TimelineStep(
        title: 'Ditugaskan ke Kurir',
        subtitle: isAssigned
            ? '${_task.assignedToName ?? '-'} • ${_task.assignedAt != null ? _formatDate(_task.assignedAt!) : '-'}'
            : 'Menunggu assign',
        isDone: isAssigned,
        icon: Icons.person_pin,
        color: Colors.blue,
      ),
    );

    // On delivery
    final isOnDelivery = ['on_delivery', 'delivered'].contains(_task.status);
    allSteps.add(
      _TimelineStep(
        title: 'Dalam Pengiriman',
        subtitle: isOnDelivery
            ? (_task.pickedUpAt != null
                  ? _formatDate(_task.pickedUpAt!)
                  : 'Sedang dikirim')
            : 'Belum dikirim',
        isDone: isOnDelivery,
        isActive: _task.status == 'on_delivery',
        icon: Icons.local_shipping,
        color: Colors.orange,
      ),
    );

    // Delivered / Failed / Rescheduled
    if (_task.status == 'failed') {
      allSteps.add(
        _TimelineStep(
          title: 'Gagal',
          subtitle: _task.failedReason.isNotEmpty
              ? _task.failedReason
              : 'Pengiriman gagal',
          isDone: true,
          icon: Icons.cancel,
          color: Colors.red,
        ),
      );
    } else if (_task.status == 'rescheduled') {
      allSteps.add(
        _TimelineStep(
          title: 'Dijadwalkan Ulang',
          subtitle: _task.rescheduledDate != null
              ? 'Dijadwalkan: ${_formatDate(_task.rescheduledDate!)}'
              : (_task.rescheduledReason.isNotEmpty
                    ? _task.rescheduledReason
                    : '-'),
          isDone: true,
          isActive: true,
          icon: Icons.schedule,
          color: Colors.purple,
        ),
      );
    } else {
      allSteps.add(
        _TimelineStep(
          title: 'Terkirim',
          subtitle: _task.deliveredAt != null
              ? _formatDate(_task.deliveredAt!)
              : 'Belum selesai',
          isDone: _task.status == 'delivered',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      );
    }

    return _card(
      title: 'Live Tracking',
      icon: Icons.timeline,
      children: [
        ...allSteps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isLast = i == allSteps.length - 1;
          return _buildTimelineItem(step, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(_TimelineStep step, bool isLast) {
    final dotColor = step.isDone ? step.color : Colors.grey.shade300;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: step.isActive
                        ? [
                            BoxShadow(
                              color: dotColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(step.icon, size: 16, color: Colors.white),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isDone
                          ? step.color.withOpacity(0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: step.isDone ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: step.isDone
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (step.isActive) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: step.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sedang berlangsung...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: step.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage() {
    return _card(
      title: 'Bukti Pengiriman',
      icon: Icons.camera_alt,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _task.imageUrl!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, size: 48)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final IconData icon;
  final Color color;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isActive = false,
    required this.icon,
    required this.color,
  });
}
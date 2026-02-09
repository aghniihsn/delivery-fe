class Destination {
  final String? address;
  final double? latitude;
  final double? longitude;

  const Destination({this.address, this.latitude, this.longitude});

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class StatusHistoryEntry {
  final String from;
  final String to;
  final String notes;
  final DateTime? changedAt;

  const StatusHistoryEntry({
    required this.from,
    required this.to,
    this.notes = '',
    this.changedAt,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'] as String)
          : null,
    );
  }
}

class DeliveryTask {
  final String id;
  final String title;
  final String taskId;
  final String description;
  final String status;
  final String? assignedTo;
  final String? assignedToName;
  final String? imageUrl;
  final Destination? destination;
  final String recipientName;
  final String recipientPhone;
  final String notes;
  final String failedReason;
  final DateTime? rescheduledDate;
  final String rescheduledReason;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<StatusHistoryEntry> statusHistory;

  bool get isCompleted => status == 'delivered';
  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isOnDelivery => status == 'on_delivery';
  bool get isRescheduled => status == 'rescheduled';
  bool get isFailed => status == 'failed';

  bool get canUpdateStatus =>
      status == 'assigned' ||
      status == 'on_delivery' ||
      status == 'rescheduled';

  String get statusLabel {
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

  const DeliveryTask({
    required this.id,
    required this.title,
    required this.taskId,
    required this.status,
    this.description = '',
    this.assignedTo,
    this.assignedToName,
    this.imageUrl,
    this.destination,
    this.recipientName = '',
    this.recipientPhone = '',
    this.notes = '',
    this.failedReason = '',
    this.rescheduledDate,
    this.rescheduledReason = '',
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
  });

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    String? assignedToId;
    String? assignedToName;
    final assigned = json['assignedTo'];
    if (assigned is String) {
      assignedToId = assigned;
    } else if (assigned is Map<String, dynamic>) {
      assignedToId = assigned['_id'] as String?;
      assignedToName = assigned['name'] as String?;
    }

    return DeliveryTask(
      id: json['_id'] as String,
      title: json['title'] as String,
      taskId: json['taskId'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      assignedTo: assignedToId,
      assignedToName: assignedToName,
      imageUrl: json['imageUrl'] as String?,
      destination: json['destination'] != null
          ? Destination.fromJson(json['destination'] as Map<String, dynamic>)
          : null,
      recipientName: json['recipientName'] as String? ?? '',
      recipientPhone: json['recipientPhone'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      failedReason: json['failedReason'] as String? ?? '',
      rescheduledDate: json['rescheduledDate'] != null
          ? DateTime.tryParse(json['rescheduledDate'] as String)
          : null,
      rescheduledReason: json['rescheduledReason'] as String? ?? '',
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.tryParse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
                .map(
                  (e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

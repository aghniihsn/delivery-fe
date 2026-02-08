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

class DeliveryTask {
  final String id;
  final String title;
  final String taskId;
  final String status; // 'pending', 'processing', 'delivered'
  final String? assignedTo;
  final String? imageUrl;
  final Destination? destination;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == 'delivered';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';

  String get statusLabel {
    switch (status) {
      case 'delivered':
        return 'Selesai';
      case 'processing':
        return 'Dalam Proses';
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
    this.assignedTo,
    this.imageUrl,
    this.destination,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: json['_id'] as String,
      title: json['title'] as String,
      taskId: json['taskId'] as String,
      status: json['status'] as String? ?? 'pending',
      assignedTo: json['assignedTo'] as String?,
      imageUrl: json['imageUrl'] as String?,
      destination: json['destination'] != null
          ? Destination.fromJson(json['destination'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

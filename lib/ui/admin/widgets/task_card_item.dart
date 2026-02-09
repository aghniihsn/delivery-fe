import 'package:flutter/material.dart';
import 'package:praktikum_1/core/models/delivery_task_model.dart';

class TaskCardItem extends StatelessWidget {
  final DeliveryTask task;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  const TaskCardItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                ],
              ),
              const SizedBox(height: 8),
              if (task.destination?.address != null)
                Text(
                  task.destination!.address!,
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignedToName ?? 'Belum di-assign',
                      style: TextStyle(
                        fontSize: 12,
                        color: task.assignedToName != null
                            ? Colors.indigo
                            : Colors.red,
                      ),
                    ),
                  ),
                  if (task.status == 'pending' || task.status == 'assigned')
                    OutlinedButton(
                      onPressed: onAssign,
                      child: const Text(
                        'Assign',
                        style: TextStyle(fontSize: 11),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'on_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
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
      default:
        return Icons.radio_button_unchecked;
    }
  }
}

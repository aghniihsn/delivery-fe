import 'package:flutter/material.dart';

class AdminSummaryCards extends StatelessWidget {
  final int pending, assigned, onDelivery, delivered;

  const AdminSummaryCards({
    super.key,
    required this.pending,
    required this.assigned,
    required this.onDelivery,
    required this.delivered,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _card('Menunggu', pending, Colors.grey.shade600),
          const SizedBox(width: 6),
          _card('Assign', assigned, Colors.blue),
          const SizedBox(width: 6),
          _card('Kirim', onDelivery, Colors.orange),
          const SizedBox(width: 6),
          _card('Selesai', delivered, Colors.green),
        ],
      ),
    );
  }

  Widget _card(String label, int count, Color color) {
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
}

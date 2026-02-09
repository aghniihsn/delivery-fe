import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class QRViewDialog extends StatelessWidget {
  final String taskId;
  final String title;
  final ScreenshotController screenshotController = ScreenshotController();

  QRViewDialog({super.key, required this.taskId, required this.title});

  Future<void> _shareQR(BuildContext context) async {
    try {
      // Capture gambar dengan ukuran spesifik agar tidak error "no size"
      final directory = (await getTemporaryDirectory()).path;
      final String fileName = "QR_${taskId.replaceAll('-', '_')}.png";

      await screenshotController.captureAndSave(
        directory,
        fileName: fileName,
        pixelRatio: 2.0,
      );

      final String imagePath = '$directory/$fileName';

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: 'QR Code untuk Paket: $title ($taskId)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Center(
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 44),
            SizedBox(height: 8),
            Text(
              'Tugas Berhasil Dibuat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        // Tambahkan scroll agar aman di layar kecil
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Text(
              'ID: $taskId',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Bungkus dengan Container berkonten tetap agar ukuran terdeteksi
            Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  // PAKSA UKURAN DI SINI
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: taskId,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Silakan simpan atau bagikan QR Code ini untuk ditempel pada paket.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: () => _shareQR(context),
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Simpan / Bagikan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

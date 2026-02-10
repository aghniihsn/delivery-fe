import 'package:flutter/material.dart';
import 'package:praktikum_1/ui/admin/widgets/qr_view_dialog.dart'; // Import Dialog Baru

class CreateTaskSheet extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final Future<void> Function(Map<String, dynamic>) onCreateSingle;

  const CreateTaskSheet({
    super.key,
    required this.drivers,
    required this.onCreateSingle,
  });

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _singleFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleCtrl = TextEditingController();
  final _taskIdCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedDriverId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _taskIdCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _generateAutoId() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final micro = now.microsecondsSinceEpoch
        .toString()
        .split('')
        .reversed
        .take(4)
        .join('')
        .split('')
        .reversed
        .join('');
    setState(() {
      _taskIdCtrl.text = "LGT-$dateStr-$micro";
    });
  }

  Future<void> _submitSingle() async {
    if (!_singleFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Pastikan ID ada
    if (_taskIdCtrl.text.trim().isEmpty) _generateAutoId();

    final String finalTaskId = _taskIdCtrl.text.trim();
    final String finalTitle = _titleCtrl.text.trim();

    final data = <String, dynamic>{'title': finalTitle, 'taskId': finalTaskId};

    if (_descCtrl.text.trim().isNotEmpty)
      data['description'] = _descCtrl.text.trim();
    if (_addressCtrl.text.trim().isNotEmpty)
      data['address'] = _addressCtrl.text.trim();
    if (_recipientNameCtrl.text.trim().isNotEmpty)
      data['recipientName'] = _recipientNameCtrl.text.trim();
    if (_recipientPhoneCtrl.text.trim().isNotEmpty)
      data['recipientPhone'] = _recipientPhoneCtrl.text.trim();
    if (_notesCtrl.text.trim().isNotEmpty)
      data['notes'] = _notesCtrl.text.trim();
    if (_selectedDriverId != null) data['assignedTo'] = _selectedDriverId;

    try {
      await widget.onCreateSingle(data);

      if (mounted) {
        setState(() => _isLoading = false);

        // Ambil navigator sebelum pop agar context tidak hilang
        final navigator = Navigator.of(context);
        navigator.pop(); // Tutup Bottom Sheet

        // Gunakan Future.delayed agar transisi pop selesai dulu sebelum muncul dialog
        Future.delayed(Duration.zero, () {
          if (mounted) {
            showDialog(
              // Gunakan context yang lebih tinggi jika perlu, atau navigator.context
              context: navigator.context,
              barrierDismissible: false,
              builder: (ctx) =>
                  QRViewDialog(taskId: finalTaskId, title: finalTitle),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Gagal membuat tugas: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, size: 20, color: Colors.indigo),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              'Buat Tugas Pengiriman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildSingleForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _singleFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDec('Judul Task *', Icons.title),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taskIdCtrl,
              decoration: _inputDec('Nomor Resi / Task ID', Icons.tag).copyWith(
                helperText: "Kosongkan untuk resi otomatis",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.autorenew, color: Colors.indigo),
                  onPressed: _generateAutoId,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: _inputDec('Alamat Tujuan', Icons.location_on),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientNameCtrl,
                    decoration: _inputDec('Penerima', Icons.person),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recipientPhoneCtrl,
                    decoration: _inputDec('No. HP', Icons.phone),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: _inputDec('Assign ke Kurir', Icons.delivery_dining),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Pilih Kurir --'),
                ),
                ...widget.drivers.map(
                  (d) =>
                      DropdownMenuItem(value: d['_id'], child: Text(d['name'])),
                ),
              ],
              onChanged: (val) => setState(() => _selectedDriverId = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitSingle,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'BUAT TUGAS & GENERATE QR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

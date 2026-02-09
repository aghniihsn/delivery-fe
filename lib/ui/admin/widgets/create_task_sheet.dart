import 'package:flutter/material.dart';

class CreateTaskSheet extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final Future<void> Function(Map<String, dynamic>) onCreateSingle;
  final Future<void> Function(List<Map<String, dynamic>>) onCreateBulk;

  const CreateTaskSheet({
    super.key,
    required this.drivers,
    required this.onCreateSingle,
    required this.onCreateBulk,
  });

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet>
    with SingleTickerProviderStateMixin {
  late TabController _modeTab;
  final _singleFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controller untuk Task Satuan
  final _titleCtrl = TextEditingController();
  final _taskIdCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedDriverId;

  // List untuk Task Bulk (Massal)
  final List<BulkTaskEntry> _bulkEntries = [BulkTaskEntry()];

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

  // --- LOGIKA SUBMIT ---

  Future<void> _submitSingle() async {
    if (!_singleFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'taskId': _taskIdCtrl.text.trim(),
    };
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

    await widget.onCreateSingle(data);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  Future<void> _submitBulk() async {
    for (int i = 0; i < _bulkEntries.length; i++) {
      if (_bulkEntries[i].title.text.trim().isEmpty ||
          _bulkEntries[i].taskId.text.trim().isEmpty) {
        _showError('Task #${i + 1}: Judul dan ID wajib diisi');
        return;
      }
    }

    setState(() => _isLoading = true);

    final tasks = _bulkEntries.map((e) {
      return {
        'title': e.title.text.trim(),
        'taskId': e.taskId.text.trim(),
        'recipientName': e.recipientName.text.trim(),
        'destination': {'address': e.address.text.trim()},
        'assignedTo': e.driverId,
      };
    }).toList();

    await widget.onCreateBulk(tasks);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // --- UI COMPONENTS ---

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, size: 20, color: Colors.indigo),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TabBar(
            controller: _modeTab,
            labelColor: Colors.indigo,
            indicatorColor: Colors.indigo,
            tabs: const [
              Tab(text: 'Satuan'),
              Tab(text: 'Massal (Bulk)'),
            ],
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: TabBarView(
                controller: _modeTab,
                children: [_buildSingleForm(), _buildBulkForm()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _singleFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDec('Judul Task *', Icons.title),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taskIdCtrl,
              decoration: _inputDec('Task ID / Nomor Resi *', Icons.tag),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
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
            DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: _inputDec('Assign ke Kurir', Icons.delivery_dining),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Pilih Kurir (Opsional) --'),
                ),
                ...widget.drivers.map(
                  (d) =>
                      DropdownMenuItem(value: d['_id'], child: Text(d['name'])),
                ),
              ],
              onChanged: (val) => setState(() => _selectedDriverId = val),
            ),
            const SizedBox(height: 24),
            _submitButton(_submitSingle, 'Buat Tugas Sekarang'),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkForm() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bulkEntries.length,
            itemBuilder: (context, index) => _buildBulkItem(index),
          ),
        ),
        _bulkActions(),
      ],
    );
  }

  Widget _buildBulkItem(int index) {
    final entry = _bulkEntries[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Data Paket',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_bulkEntries.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _bulkEntries.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.title,
              decoration: _inputDec('Judul *', Icons.title),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.taskId,
              decoration: _inputDec('ID / Resi *', Icons.tag),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulkActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _bulkEntries.add(BulkTaskEntry())),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Baris'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _submitButton(_submitBulk, 'Simpan Semua')),
        ],
      ),
    );
  }

  Widget _submitButton(VoidCallback onPressed, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label),
      ),
    );
  }
}

class BulkTaskEntry {
  final title = TextEditingController();
  final taskId = TextEditingController();
  final address = TextEditingController();
  final recipientName = TextEditingController();
  String? driverId;

  void dispose() {
    title.dispose();
    taskId.dispose();
    address.dispose();
    recipientName.dispose();
  }
}

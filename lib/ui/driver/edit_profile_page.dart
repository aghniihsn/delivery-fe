import 'package:flutter/material.dart';
import 'package:praktikum_1/api_services.dart';
import 'package:praktikum_1/auth_service.dart';
import 'package:praktikum_1/ui/driver/dashboard_page.dart';

class EditProfilePage extends StatefulWidget {
  final bool isFirstTime;

  const EditProfilePage({super.key, this.isFirstTime = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoadingProfile = false;
  bool _isLoadingPassword = false;
  bool _isLoadingData = true;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _profileUpdated = false;
  bool _passwordChanged = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _email = profile['email'] ?? '';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        _showMsg('Gagal memuat data profil', isError: true);
      }
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

  Future<void> _handleUpdateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isLoadingProfile = true);

    try {
      final result = await _apiService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await _authService.setUserName(result['name']);
      await _authService.setProfileCompleted(true);

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _profileUpdated = true;
        });
        _showMsg('Profil berhasil diperbarui');
        _checkAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showMsg(errorMsg, isError: true);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoadingPassword = true);

    try {
      await _apiService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      await _authService.setProfileCompleted(true);

      if (mounted) {
        setState(() {
          _isLoadingPassword = false;
          _passwordChanged = true;
        });
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showMsg('Password berhasil diubah');
        _checkAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPassword = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showMsg(errorMsg, isError: true);
      }
    }
  }

  /// Jika mode firstTime, navigasi ke Dashboard setelah kedua langkah selesai
  void _checkAndNavigate() {
    if (widget.isFirstTime && _profileUpdated && _passwordChanged) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        }
      });
    }
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstTime,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Edit Profil'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !widget.isFirstTime,
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info wajib jika pertama kali
                    if (widget.isFirstTime) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Selamat datang! Silakan lengkapi profil dan ubah password Anda sebelum melanjutkan.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Checklist progress
                      Row(
                        children: [
                          _buildCheckItem('Update Profil', _profileUpdated),
                          const SizedBox(width: 16),
                          _buildCheckItem('Ganti Password', _passwordChanged),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ====== SECTION: Update Profil ======
                    _buildSectionHeader(
                      'Informasi Profil',
                      Icons.person_outline,
                      isDone: _profileUpdated,
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _profileFormKey,
                      child: Column(
                        children: [
                          // Email (read-only)
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            decoration: _inputDecoration(
                              'Email',
                              '',
                              Icons.email_outlined,
                            ).copyWith(fillColor: Colors.grey.shade200),
                          ),
                          const SizedBox(height: 14),

                          // Nama
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              'Nama Lengkap',
                              'Masukkan nama lengkap',
                              Icons.badge_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Nomor HP
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              'Nomor HP',
                              'Contoh: 08123456789',
                              Icons.phone_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor HP tidak boleh kosong';
                              }
                              if (value.trim().length < 10) {
                                return 'Nomor HP minimal 10 digit';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoadingProfile
                                  ? null
                                  : _handleUpdateProfile,
                              icon: _isLoadingProfile
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isLoadingProfile
                                    ? 'Menyimpan...'
                                    : 'Simpan Profil',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ====== SECTION: Ganti Password ======
                    _buildSectionHeader(
                      'Ganti Password',
                      Icons.lock_outline,
                      isDone: _passwordChanged,
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _passwordFormKey,
                      child: Column(
                        children: [
                          // Password Lama
                          TextFormField(
                            controller: _oldPasswordController,
                            obscureText: !_showOldPassword,
                            decoration:
                                _inputDecoration(
                                  'Password Lama',
                                  'Masukkan password saat ini',
                                  Icons.lock_clock_outlined,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showOldPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _showOldPassword = !_showOldPassword,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password lama wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password Baru
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_showNewPassword,
                            decoration:
                                _inputDecoration(
                                  'Password Baru',
                                  'Minimal 6 karakter',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showNewPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _showNewPassword = !_showNewPassword,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password baru wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Konfirmasi Password Baru
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            decoration:
                                _inputDecoration(
                                  'Konfirmasi Password Baru',
                                  'Ketik ulang password baru',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () => _showConfirmPassword =
                                          !_showConfirmPassword,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoadingPassword
                                  ? null
                                  : _handleChangePassword,
                              icon: _isLoadingPassword
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.vpn_key),
                              label: Text(
                                _isLoadingPassword
                                    ? 'Mengubah...'
                                    : 'Ubah Password',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool isDone = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: isDone ? Colors.green : Colors.blueAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDone ? Colors.green.shade700 : Colors.blueGrey.shade800,
          ),
        ),
        if (isDone) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ],
    );
  }

  Widget _buildCheckItem(String label, bool done) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: done ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: done ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

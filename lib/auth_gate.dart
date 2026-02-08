import 'package:flutter/material.dart';
import 'package:praktikum_1/auth_service.dart';
import 'package:praktikum_1/admin_dashboard_page.dart';
import 'package:praktikum_1/dashboard_page.dart';
import 'package:praktikum_1/edit_profile_page.dart';
import 'package:praktikum_1/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // User sudah login, cek role untuk navigasi
          return FutureBuilder<String?>(
            future: authService.getRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;
              if (role == 'admin') {
                return const AdminDashboardPage();
              }
              // Cek apakah driver sudah lengkapi profil
              return FutureBuilder<bool>(
                future: authService.isProfileCompleted(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final profileDone = profileSnapshot.data ?? false;
                  if (!profileDone) {
                    return const EditProfilePage(isFirstTime: true);
                  }
                  return const DashboardPage();
                },
              );
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}

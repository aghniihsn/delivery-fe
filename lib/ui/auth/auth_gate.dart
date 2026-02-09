import 'package:flutter/material.dart';
import 'package:praktikum_1/core/services/auth_services.dart';
import 'package:praktikum_1/ui/admin/admin_dashboard_page.dart';
import 'package:praktikum_1/ui/driver/dashboard_page.dart';
import 'package:praktikum_1/ui/driver/edit_profile_page.dart';
import 'package:praktikum_1/ui/auth/login_page.dart';

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

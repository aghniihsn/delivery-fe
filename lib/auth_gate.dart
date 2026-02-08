import 'package:flutter/material.dart';
import 'package:praktikum_1/auth_service.dart';
import 'package:praktikum_1/dashboard_page.dart';
import 'package:praktikum_1/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }
}

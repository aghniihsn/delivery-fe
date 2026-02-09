import 'package:flutter/material.dart';
import 'package:praktikum_1/ui/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogiTrack',
      theme: ThemeData(colorSchemeSeed: Colors.blueAccent, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

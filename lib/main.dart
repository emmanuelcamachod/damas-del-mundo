import 'package:flutter/material.dart';
import 'auth/auth.dart';
import 'ui/auth_screen.dart';

void main() {
  runApp(const CheckersApp());
}

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Damas de Élite • GEM V4.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090D16),
        useMaterial3: true,
      ),
      home: AuthScreen(authService: SupabaseAuthService()),
    );
  }
}

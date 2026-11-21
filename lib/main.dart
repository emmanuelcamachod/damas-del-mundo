import 'package:flutter/material.dart';
import 'auth/auth.dart';
import 'ui/auth_screen.dart';
import 'ui/neo_tactile_theme.dart';

void main() {
  runApp(const CheckersApp());
}

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Damas del Mundo • Neo-Tactile Studio',
      debugShowCheckedModeBanner: false,
      theme: NeoTactileTheme.themeData,
      home: AuthScreen(authService: SupabaseAuthService()),
    );
  }
}

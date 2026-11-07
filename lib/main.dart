// Punto de entrada de la aplicación Flutter — Juego de Damas Españolas 8x8.

import 'package:flutter/material.dart';
import 'ui/board_screen.dart';

void main() {
  runApp(const CheckersApp());
}

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego de Damas Españolas 8x8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}

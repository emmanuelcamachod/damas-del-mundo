// Diálogo y Efecto Cinematográfico de Victoria / "Mate de la Dama" (GEM V4.0 + Frontend Design).
// Cumple RNF-004 (5 estados visuales) y RNF-003 (anidamiento <= 2).

import 'package:flutter/material.dart';
import '../domain/checkers_types.dart';
import 'game_controller.dart';

class VictoryCelebrationDialog extends StatelessWidget {
  final GameController controller;
  final VoidCallback onRematch;
  final VoidCallback onInspectDna;

  const VictoryCelebrationDialog({
    super.key,
    required this.controller,
    required this.onRematch,
    required this.onInspectDna,
  });

  @override
  Widget build(BuildContext context) {
    final status = controller.currentBoard.status;
    final isHumanVictory = status == GameStatus.whiteWins;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: _buildDialogContent(context, isHumanVictory),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context, bool isHumanVictory) {
    final primaryColor = isHumanVictory
        ? const Color(0xFFEAB308)
        : const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCrownAvatar(isHumanVictory, primaryColor),
          const SizedBox(height: 16),
          _buildTitleText(isHumanVictory),
          const SizedBox(height: 8),
          _buildSubtitleText(isHumanVictory),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCrownAvatar(bool isHumanVictory, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isHumanVictory ? Icons.emoji_events : Icons.smart_toy,
          size: 48,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTitleText(bool isHumanVictory) {
    return Text(
      isHumanVictory ? '¡MATE DE LA DAMA!' : 'VICTORIA DE LA IA NÉMESIS',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtitleText(bool isHumanVictory) {
    return Text(
      isHumanVictory
          ? 'Has arrinconado a la máquina sin jugadas legales con maestría táctica.'
          : 'La IA Némesis aplicó su libro de patrones y optimizó sus pesos TD-Learning.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF94A3B8),
        height: 1.4,
      ),
    );
  }

  Widget _buildStatsRow() {
    final moves = controller.moveLog.length;
    final blunders = controller.detectedBlunders.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Jugadas', '$moves'),
          _buildStatDivider(),
          _buildStatItem('Precisión', '${controller.playerDnaProfile.aggressionScorePct}%'),
          _buildStatDivider(),
          _buildStatItem('Errores', '$blunders'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFF334155),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onInspectDna();
            },
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('Ver ADN'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRematch();
            },
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Revancha'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: const Color(0xFFEAB308),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

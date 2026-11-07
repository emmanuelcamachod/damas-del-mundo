// Hoja modal con la Radiografía "ADN del Jugador", telemetría de la IA Adaptativa y Detector de Errores.
// Cumple RF-003, RF-004, RF-005 y RNF-004 (anidación <= 2, contraste WCAG AA y áreas >= 48dp).

import 'package:flutter/material.dart';
import '../ai/ai_engine.dart';
import 'game_controller.dart';

class AiDnaSheet extends StatelessWidget {
  final GameController controller;

  const AiDnaSheet({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final dna = controller.playerDnaProfile;
    final learner = controller.adaptiveLearner;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildDnaSummaryCard(dna),
            const SizedBox(height: 12),
            _buildAiWeightsCard(learner),
            const SizedBox(height: 12),
            _buildBlundersSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ADN del Jugador y Cerebro IA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDnaSummaryCard(PlayerDnaProfile dna) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RADIOGRAFÍA TÁCTICA DEL RIVAL HUMANO',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dna.tacticalSummary,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Contraestrategia IA: ${dna.aiCounterStrategy}',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Agresividad: ${dna.aggressionScorePct}% · Solidez Fila Base: ${dna.backRowDisciplinePct}% · Flanco: ${dna.preferredFlank}',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiWeightsCard(AdaptiveLearner learner) {
    final weights = learner.currentWeights;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVOLUCIÓN TD-LEARNING (Partidas aprendidas: ${learner.gamesLearned})',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Récord IA: ${learner.aiWins}V - ${learner.humanWins}D - ${learner.draws}T',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesos actuales → Peón: ${weights.pawnValue.toStringAsFixed(1)} | '
            'Dama: ${weights.kingValue.toStringAsFixed(1)} | '
            'Centro: ${weights.centerControlBonus.toStringAsFixed(1)} | '
            'Fila Real: ${weights.backRowGuardBonus.toStringAsFixed(1)}',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBlundersSection(BuildContext context) {
    final blunders = controller.detectedBlunders;
    if (blunders.isEmpty) {
      return const Text(
        'Detector de Errores: Sin errores graves detectados en esta partida.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOMENTOS CRÍTICOS (REINTENTAR DESDE MI ERROR)',
          style: TextStyle(
            color: Color(0xFFF87171),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        for (final record in blunders) _buildBlunderTile(context, record),
      ],
    );
  }

  Widget _buildBlunderTile(BuildContext context, BlunderRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B181E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turno #${record.moveNumber}: ${record.tacticalExplanation}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: ElevatedButton.icon(
              onPressed: () {
                controller.retryFromBlunder(record);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.replay),
              label: const Text('Reintentar desde este turno'),
            ),
          ),
        ],
      ),
    );
  }
}

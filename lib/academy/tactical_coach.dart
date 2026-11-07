// Entrenador Táctico en Tiempo Real (Modo Coach) — Fase 03 (RF-006 / DEC-004).
// Analiza cualquier estado del tablero y explica en lenguaje humano qué técnica aplicar.

import '../ai/ai_engine.dart';
import '../domain/checkers_engine.dart';
import 'academy_models.dart';

class TacticalCoach {
  static CoachAdvice analyzePosition(
    BoardState board, {
    HeuristicWeights weights = const HeuristicWeights(),
  }) {
    assert(!board.status.isTerminal, 'No se puede pedir pista en partida terminada');
    final solver = AlphaBetaSolver(weights: weights);
    final decision = solver.findBestDecision(board, maxDepth: 4);
    final move = decision.bestMove;
    assert(move != null, 'Debe existir al menos un movimiento legal para el Coach');

    final technique = _classifyTechnique(board, move!);
    final explanation = _buildHumanExplanation(
      board,
      move,
      technique,
      decision.evaluationScore,
    );

    return CoachAdvice(
      recommendedMove: move,
      techniqueName: technique,
      tacticalExplanation: explanation,
      evaluationScoreCp: decision.evaluationScore,
    );
  }

  static String _classifyTechnique(BoardState board, CheckersMove move) {
    if (move.capturedCount >= 2) {
      return 'Golpe de Captura Múltiple (${move.capturedCount} piezas)';
    }
    if (move.capturedKingsCount >= 1) {
      return 'Caza de Dama por Ley de Calidad (RN-005)';
    }
    if (move.isCapture) {
      return 'Captura Táctica Obligatoria (RN-004)';
    }
    if (move.promotesToKing) {
      return 'Coronación Directa de Dama';
    }
    if (_isCentralSquare(move.to, board.ruleset.boardSize)) {
      return 'Dominio de las Casillas Centrales (Nivel 7)';
    }
    return 'Desarrollo Sólido y Reserva de Fila Real (Nivel 3)';
  }

  static bool _isCentralSquare(BoardPosition pos, int boardSize) {
    final minC = (boardSize ~/ 2) - 2;
    final maxC = (boardSize ~/ 2) + 1;
    return pos.row >= minC &&
        pos.row <= maxC &&
        pos.col >= minC &&
        pos.col <= maxC;
  }

  static String _buildHumanExplanation(
    BoardState board,
    CheckersMove move,
    String technique,
    double scoreCp,
  ) {
    final size = board.ruleset.boardSize;
    final notation = move.toNotation(size);
    if (move.isCapture) {
      return 'Coach Táctico [$technique]: Ejecuta $notation para ganar material inmediato y forzar la iniciativa (${scoreCp.round()} cp).';
    }
    if (move.promotesToKing) {
      return 'Coach Táctico [$technique]: Avanza con $notation para coronar Dama y dominar las diagonales largas.';
    }
    return 'Coach Táctico [$technique]: Juega $notation para fortalecer tu control posicional sin debilitar tu Fila Real.';
  }
}

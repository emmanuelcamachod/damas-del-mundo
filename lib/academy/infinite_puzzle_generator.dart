// Generador Infinito de Retos Tácticos Procedimentales y Conversor de Errores del Usuario.
// Cumple RF-006 y RN-008: la Academia nunca se agota gracias a la generación verificada con AlphaBetaSolver.

import '../ai/ai_engine.dart';
import '../domain/checkers_engine.dart';
import 'academy_models.dart';

class InfinitePuzzleGenerator {
  // Genera un reto táctico único a partir de una semilla numérica (seed >= 1).
  static TacticalLesson generateProceduralPuzzle({
    required int seed,
    CheckersRuleset ruleset = CheckersRuleset.spanish,
  }) {
    assert(seed >= 1, 'La semilla del generador infinito debe ser >= 1');
    final board = _buildTacticalPositionFromSeed(seed, ruleset);
    final solver = AlphaBetaSolver();
    final decision = solver.findBestDecision(board, maxDepth: 4);
    final bestMove = decision.bestMove;
    assert(bestMove != null, 'El tablero generado debe tener jugada óptima válida');

    final size = ruleset.boardSize;
    final notation = bestMove!.toNotation(size);
    return TacticalLesson(
      id: 'INF_PUZZLE_$seed',
      levelNumber: 10,
      title: 'Reto Infinito #$seed (${ruleset.displayName})',
      techniqueName: bestMove.isCapture
          ? 'Combinación Forzada de Captura'
          : 'Maniobra Posicional de Gran Maestro',
      theoryExplanation:
          'Posición táctica generada procedimentalmente y verificada con búsqueda Alfa-Beta a profundidad 4.',
      objectivePrompt:
          'Encuentra la mejor jugada para las ${board.turn.displayName} en esta posición crítica.',
      initialBoard: board,
      expectedFrom: bestMove.from,
      expectedTo: bestMove.to,
      successExplanation:
          '¡Exacto! $notation es la jugada maestra (${decision.evaluationScore.round()} cp).',
      failureHint:
          'Observa la ficha en ${bestMove.from.toAlgebraicLabel(size)} y calcula su salto o avance más fuerte.',
    );
  }

  // Convierte un error real cometido por el jugador (BlunderRecord) en una lección interactiva.
  static TacticalLesson lessonFromPlayerBlunder(BlunderRecord blunder) {
    final size = blunder.stateBeforeError.ruleset.boardSize;
    return TacticalLesson(
      id: 'BLUNDER_LESSON_${blunder.moveNumber}',
      levelNumber: 10,
      title: 'Lección de tu Partida (Turno #${blunder.moveNumber})',
      techniqueName: 'Corrección de Momento Crítico Personalizado',
      theoryExplanation: blunder.tacticalExplanation,
      objectivePrompt:
          'En tu partida jugaste ${blunder.playedMove.toNotation(size)}. Encuentra ahora la jugada maestra que mantenía la ventaja.',
      initialBoard: blunder.stateBeforeError,
      expectedFrom: blunder.optimalMove.from,
      expectedTo: blunder.optimalMove.to,
      successExplanation:
          '¡Error superado! ${blunder.optimalMove.toNotation(size)} neutralizaba la amenaza rival.',
      failureHint:
          'Revisa la pieza en ${blunder.optimalMove.from.toAlgebraicLabel(size)}.',
    );
  }

  static BoardState _buildTacticalPositionFromSeed(
    int seed,
    CheckersRuleset ruleset,
  ) {
    var board = BoardState.initial(ruleset: ruleset);
    final pliesToAdvance = 4 + (seed % 7);
    for (var step = 0; step < pliesToAdvance; step++) {
      final moves = board.legalMoves();
      if (moves.isEmpty) {
        return BoardState.initial(ruleset: ruleset);
      }
      final pickedIndex = (seed * 31 + step * 17) % moves.length;
      final nextBoard = board.applyMove(moves[pickedIndex]);
      if (nextBoard.status.isTerminal) {
        return board;
      }
      board = nextBoard;
    }
    return board;
  }
}

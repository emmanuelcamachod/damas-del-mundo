// Detector de Errores Críticos (Blunder Detector) y soporte para "Reintentar desde mi Error" (RF-004 / RN-008).

import '../domain/checkers_engine.dart';
import 'alpha_beta_solver.dart';
import 'heuristic_weights.dart';

class BlunderRecord {
  final int moveNumber;
  final int boardHistoryIndex;
  final BoardState stateBeforeError;
  final CheckersMove playedMove;
  final CheckersMove optimalMove;
  final double evaluationDrop;
  final String tacticalExplanation;

  const BlunderRecord({
    required this.moveNumber,
    required this.boardHistoryIndex,
    required this.stateBeforeError,
    required this.playedMove,
    required this.optimalMove,
    required this.evaluationDrop,
    required this.tacticalExplanation,
  }) : assert(evaluationDrop > 0, 'La caída de evaluación debe ser positiva');
}

class BlunderDetector {
  static const double blunderThresholdCp = 180.0;

  static BlunderRecord? inspectHumanMove({
    required BoardState boardBefore,
    required CheckersMove playedMove,
    required int moveNumber,
    required int boardHistoryIndex,
    HeuristicWeights weights = const HeuristicWeights(),
  }) {
    final legal = boardBefore.legalMoves();
    if (legal.length <= 1) {
      return null;
    }
    final solver = AlphaBetaSolver(weights: weights);
    final bestDecision = solver.findBestDecision(boardBefore, maxDepth: 3);
    final bestMove = bestDecision.bestMove;
    if (bestMove == null || _isSameMove(playedMove, bestMove)) {
      return null;
    }

    final boardAfterPlayed = boardBefore.applyMove(playedMove);
    final opponentReply = solver.findBestDecision(boardAfterPlayed, maxDepth: 2);
    final playedScore = -opponentReply.evaluationScore;
    final drop = bestDecision.evaluationScore - playedScore;

    if (drop < blunderThresholdCp) {
      return null;
    }
    return BlunderRecord(
      moveNumber: moveNumber,
      boardHistoryIndex: boardHistoryIndex,
      stateBeforeError: boardBefore,
      playedMove: playedMove,
      optimalMove: bestMove,
      evaluationDrop: drop,
      tacticalExplanation: _explainBlunder(
        boardBefore,
        playedMove,
        bestMove,
        drop,
      ),
    );
  }

  static bool _isSameMove(CheckersMove a, CheckersMove b) {
    return a.from == b.from &&
        a.to == b.to &&
        a.capturedCount == b.capturedCount;
  }

  static String _explainBlunder(
    BoardState boardBefore,
    CheckersMove played,
    CheckersMove optimal,
    double drop,
  ) {
    final size = boardBefore.ruleset.boardSize;
    final playedStr = played.toNotation(size);
    final bestStr = optimal.toNotation(size);
    if (optimal.isCapture && !played.isCapture) {
      return 'Jugaste $playedStr omitiendo la captura crítica $bestStr (pérdida táctica de ${drop.round()} pts).';
    }
    if (optimal.promotesToKing) {
      return 'Jugaste $playedStr en lugar de $bestStr, que aseguraba coronación directa.';
    }
    return 'En la jugada $playedStr cediste una combinación táctica al rival (-${drop.round()} pts). '
        'La jugada maestra era $bestStr para mantener la iniciativa y proteger tu estructura.';
  }
}

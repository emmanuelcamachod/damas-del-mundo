// Motor de búsqueda Minimax con Poda Alfa-Beta, Quiescence Search y Zobrist Transposition Table.
// Soporta ejecución en Isolate (RNF-001) y decisión de Soplido (RN-004).

import 'dart:isolate';
import '../domain/checkers_engine.dart';
import 'heuristic_weights.dart';

class SearchDecision {
  final CheckersMove? bestMove;
  final BoardPosition? recommendedHuffPosition;
  final double evaluationScore;
  final int depthReached;
  final int nodesEvaluated;

  const SearchDecision({
    required this.bestMove,
    required this.recommendedHuffPosition,
    required this.evaluationScore,
    required this.depthReached,
    required this.nodesEvaluated,
  }) : assert(depthReached >= 0, 'Profundidad alcanzada no puede ser negativa');
}

class _TranspositionEntry {
  final int depth;
  final double score;

  const _TranspositionEntry({
    required this.depth,
    required this.score,
  });
}

class AlphaBetaSolver {
  final HeuristicWeights weights;
  final Map<int, double> opponentPatternBias;
  final Map<int, _TranspositionEntry> _tt = <int, _TranspositionEntry>{};
  int _nodesCount = 0;

  AlphaBetaSolver({
    this.weights = const HeuristicWeights(),
    this.opponentPatternBias = const {},
  });

  static Future<SearchDecision> computeInBackground({
    required BoardState board,
    required int maxDepth,
    HeuristicWeights weights = const HeuristicWeights(),
    Map<int, double> opponentPatternBias = const {},
  }) {
    assert(maxDepth >= 1 && maxDepth <= 9, 'Profundidad fuera de rango 1..9');
    return Isolate.run(() {
      final solver = AlphaBetaSolver(
        weights: weights,
        opponentPatternBias: opponentPatternBias,
      );
      return solver.findBestDecision(board, maxDepth: maxDepth);
    });
  }

  SearchDecision findBestDecision(
    BoardState initialBoard, {
    int maxDepth = 4,
  }) {
    assert(maxDepth >= 1, 'maxDepth debe ser al menos 1');
    _nodesCount = 0;
    _tt.clear();

    BoardPosition? chosenHuff;
    var workingBoard = initialBoard;
    if (workingBoard.canHuff) {
      chosenHuff = _selectBestHuffTarget(workingBoard);
      workingBoard = workingBoard.applyHuff(chosenHuff);
    }

    final legal = workingBoard.legalMoves();
    if (legal.isEmpty) {
      return SearchDecision(
        bestMove: null,
        recommendedHuffPosition: chosenHuff,
        evaluationScore: BoardEvaluator.evaluate(
          workingBoard,
          workingBoard.turn,
          weights,
        ),
        depthReached: 0,
        nodesEvaluated: _nodesCount,
      );
    }

    final ordered = _orderMoves(workingBoard, legal);
    var bestMove = ordered.first;
    var bestScore = -999999.0;

    for (var currentDepth = 1; currentDepth <= maxDepth; currentDepth++) {
      final iteration = _searchRootAtDepth(workingBoard, ordered, currentDepth);
      bestMove = iteration.move;
      bestScore = iteration.score;
    }

    return SearchDecision(
      bestMove: bestMove,
      recommendedHuffPosition: chosenHuff,
      evaluationScore: bestScore,
      depthReached: maxDepth,
      nodesEvaluated: _nodesCount,
    );
  }

  BoardPosition _selectBestHuffTarget(BoardState board) {
    assert(board.huffablePositions.isNotEmpty, 'Debe haber piezas para soplar');
    var bestTarget = board.huffablePositions.first;
    for (final candidate in board.huffablePositions) {
      final piece = board.pieceAt(candidate);
      if (piece != null && piece.isKing) {
        bestTarget = candidate;
      }
    }
    return bestTarget;
  }

  _RootIterationResult _searchRootAtDepth(
    BoardState rootBoard,
    List<CheckersMove> orderedMoves,
    int depth,
  ) {
    var bestMove = orderedMoves.first;
    var alpha = -999999.0;
    const beta = 999999.0;

    for (final move in orderedMoves) {
      final child = rootBoard.applyMove(move);
      final bias = _lookupPatternBias(child.zobristHash);
      final score = -_negamax(child, depth - 1, -beta, -alpha) + bias;
      if (score > alpha) {
        alpha = score;
        bestMove = move;
      }
    }
    return _RootIterationResult(move: bestMove, score: alpha);
  }

  double _negamax(
    BoardState board,
    int depth,
    double alpha,
    double beta,
  ) {
    _nodesCount++;
    final cached = _tt[board.zobristHash];
    if (cached != null && cached.depth >= depth) {
      return cached.score;
    }
    if (board.status.isTerminal) {
      return BoardEvaluator.evaluate(board, board.turn, weights);
    }
    if (depth <= 0) {
      return _quiescenceSearch(board, alpha, beta, 2);
    }

    final moves = _orderMoves(board, board.legalMoves());
    var currentAlpha = alpha;
    for (final move in moves) {
      final child = board.applyMove(move);
      final score = -_negamax(child, depth - 1, -beta, -currentAlpha);
      if (score >= beta) {
        return beta;
      }
      if (score > currentAlpha) {
        currentAlpha = score;
      }
    }
    _tt[board.zobristHash] = _TranspositionEntry(
      depth: depth,
      score: currentAlpha,
    );
    return currentAlpha;
  }

  // Quiescence Search: extiende búsqueda cuando hay capturas pendientes.
  double _quiescenceSearch(
    BoardState board,
    double alpha,
    double beta,
    int remainingCaptureDepth,
  ) {
    final standPat = BoardEvaluator.evaluate(board, board.turn, weights);
    if (remainingCaptureDepth <= 0 || !board.hasMandatoryCapture) {
      return standPat;
    }
    var currentAlpha = standPat > alpha ? standPat : alpha;
    if (currentAlpha >= beta) {
      return beta;
    }
    for (final capture in board.mandatoryCaptures()) {
      final child = board.applyMove(capture);
      final score = -_quiescenceSearch(
        child,
        -beta,
        -currentAlpha,
        remainingCaptureDepth - 1,
      );
      if (score >= beta) {
        return beta;
      }
      if (score > currentAlpha) {
        currentAlpha = score;
      }
    }
    return currentAlpha;
  }

  List<CheckersMove> _orderMoves(
    BoardState board,
    List<CheckersMove> moves,
  ) {
    final copy = List<CheckersMove>.from(moves);
    copy.sort((a, b) => _movePriorityScore(b).compareTo(_movePriorityScore(a)));
    return copy;
  }

  static int _movePriorityScore(CheckersMove move) {
    var priority = move.capturedCount * 100 + move.capturedKingsCount * 45;
    if (move.promotesToKing) {
      priority += 80;
    }
    return priority;
  }

  double _lookupPatternBias(int hash) {
    final existing = opponentPatternBias[hash];
    if (existing == null) {
      return 0.0;
    }
    return existing;
  }
}

class _RootIterationResult {
  final CheckersMove move;
  final double score;

  const _RootIterationResult({
    required this.move,
    required this.score,
  });
}

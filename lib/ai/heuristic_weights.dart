// Pesos heurísticos acotados (RN-007) y evaluador estático multivariante.
// Metodología: GEM PROYECTOS SOFTWARE V4.0 (Negative Space Programming).

import '../domain/checkers_engine.dart';

class HeuristicWeights {
  final double pawnValue;
  final double kingValue;
  final double centerControlBonus;
  final double backRowGuardBonus;
  final double advancementBonus;
  final double vulnerabilityPenalty;

  const HeuristicWeights({
    this.pawnValue = 100.0,
    this.kingValue = 285.0,
    this.centerControlBonus = 14.0,
    this.backRowGuardBonus = 18.0,
    this.advancementBonus = 6.0,
    this.vulnerabilityPenalty = 22.0,
  })  : assert(pawnValue >= 80.0 && pawnValue <= 140.0, 'Peso de peón fuera de rango'),
        assert(kingValue >= 200.0 && kingValue <= 420.0, 'Peso de Dama fuera de rango'),
        assert(centerControlBonus >= 4.0 && centerControlBonus <= 40.0, 'Peso centro fuera de rango'),
        assert(backRowGuardBonus >= 4.0 && backRowGuardBonus <= 45.0, 'Peso fila base fuera de rango'),
        assert(advancementBonus >= 1.0 && advancementBonus <= 20.0, 'Peso avance fuera de rango'),
        assert(vulnerabilityPenalty >= 5.0 && vulnerabilityPenalty <= 55.0, 'Penalización fuera de rango');

  HeuristicWeights clampedCopy({
    required double pawn,
    required double king,
    required double center,
    required double backRow,
    required double advance,
    required double vulnerability,
  }) {
    return HeuristicWeights(
      pawnValue: _clamp(pawn, 80.0, 140.0),
      kingValue: _clamp(king, 200.0, 420.0),
      centerControlBonus: _clamp(center, 4.0, 40.0),
      backRowGuardBonus: _clamp(backRow, 4.0, 45.0),
      advancementBonus: _clamp(advance, 1.0, 20.0),
      vulnerabilityPenalty: _clamp(vulnerability, 5.0, 55.0),
    );
  }

  static double _clamp(double value, double minVal, double maxVal) {
    if (value < minVal) {
      return minVal;
    }
    if (value > maxVal) {
      return maxVal;
    }
    return value;
  }

  Map<String, double> toMap() {
    return {
      'pawnValue': pawnValue,
      'kingValue': kingValue,
      'centerControlBonus': centerControlBonus,
      'backRowGuardBonus': backRowGuardBonus,
      'advancementBonus': advancementBonus,
      'vulnerabilityPenalty': vulnerabilityPenalty,
    };
  }

  factory HeuristicWeights.fromMap(Map<String, dynamic> map) {
    assert(map.isNotEmpty, 'El mapa de pesos heurísticos no puede estar vacío');
    const defaults = HeuristicWeights();
    return defaults.clampedCopy(
      pawn: _readDouble(map, 'pawnValue', defaults.pawnValue),
      king: _readDouble(map, 'kingValue', defaults.kingValue),
      center: _readDouble(map, 'centerControlBonus', defaults.centerControlBonus),
      backRow: _readDouble(map, 'backRowGuardBonus', defaults.backRowGuardBonus),
      advance: _readDouble(map, 'advancementBonus', defaults.advancementBonus),
      vulnerability: _readDouble(
        map,
        'vulnerabilityPenalty',
        defaults.vulnerabilityPenalty,
      ),
    );
  }

  static double _readDouble(
    Map<String, dynamic> map,
    String key,
    double fallback,
  ) {
    final raw = map[key];
    if (raw is num) {
      return raw.toDouble();
    }
    return fallback;
  }
}

class BoardEvaluator {
  static const double winScore = 10000.0;

  // Evalúa el tablero desde la perspectiva de [perspective].
  static double evaluate(
    BoardState board,
    PlayerColor perspective,
    HeuristicWeights weights,
  ) {
    if (board.status.isTerminal) {
      return _evaluateTerminalState(board.status, perspective);
    }
    var score = 0.0;
    final size = board.ruleset.boardSize;
    for (var index = 0; index < board.ruleset.totalSquares; index++) {
      final pos = BoardPosition(index ~/ size, index % size);
      score += _evaluateSquareContribution(board, pos, perspective, weights);
    }
    if (board.hasMandatoryCapture) {
      final tacticalBonus = board.turn == perspective ? 18.0 : -18.0;
      score += tacticalBonus;
    }
    return score;
  }

  static double _evaluateTerminalState(
    GameStatus status,
    PlayerColor perspective,
  ) {
    if (status == GameStatus.whiteWins) {
      return perspective == PlayerColor.white ? winScore : -winScore;
    }
    if (status == GameStatus.blackWins) {
      return perspective == PlayerColor.black ? winScore : -winScore;
    }
    return 0.0;
  }

  static double _evaluateSquareContribution(
    BoardState board,
    BoardPosition pos,
    PlayerColor perspective,
    HeuristicWeights weights,
  ) {
    final piece = board.pieceAt(pos);
    if (piece == null) {
      return 0.0;
    }
    final rawValue = _scoreSinglePiece(
      piece,
      pos,
      board.ruleset.boardSize,
      weights,
    );
    return piece.color == perspective ? rawValue : -rawValue;
  }

  static double _scoreSinglePiece(
    CheckersPiece piece,
    BoardPosition pos,
    int boardSize,
    HeuristicWeights weights,
  ) {
    var total = piece.isKing ? weights.kingValue : weights.pawnValue;
    if (_isCentralSquare(pos, boardSize)) {
      total += weights.centerControlBonus;
    }
    if (!piece.isKing && _isBackRow(pos.row, piece.color, boardSize)) {
      total += weights.backRowGuardBonus;
    }
    if (!piece.isKing) {
      total += _advancementProgress(pos.row, piece.color, boardSize) *
          weights.advancementBonus;
    }
    if (!_isEdgeSquare(pos, boardSize) && !piece.isKing) {
      total -= weights.vulnerabilityPenalty * 0.15;
    }
    return total;
  }

  static bool _isCentralSquare(BoardPosition pos, int boardSize) {
    final minCenter = (boardSize ~/ 2) - 2;
    final maxCenter = (boardSize ~/ 2) + 1;
    return pos.row >= minCenter &&
        pos.row <= maxCenter &&
        pos.col >= minCenter &&
        pos.col <= maxCenter;
  }

  static bool _isBackRow(int row, PlayerColor color, int boardSize) {
    final homeRow = color == PlayerColor.white ? boardSize - 1 : 0;
    return row == homeRow;
  }

  static int _advancementProgress(int row, PlayerColor color, int boardSize) {
    if (color == PlayerColor.white) {
      return (boardSize - 1) - row;
    }
    return row;
  }

  static bool _isEdgeSquare(BoardPosition pos, int boardSize) {
    return pos.row == 0 ||
        pos.row == boardSize - 1 ||
        pos.col == 0 ||
        pos.col == boardSize - 1;
  }
}

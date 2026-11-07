// Tipos de dominio e invariantes base para Damas Multivariante (8x8 y 10x10).
// Metodología: GEM PROYECTOS SOFTWARE V4.0 (RNF-003 Negative Space Programming).

import 'ruleset.dart';

enum PlayerColor {
  white,
  black;

  PlayerColor get opponent =>
      this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;

  int get forwardRowDelta => this == PlayerColor.white ? -1 : 1;

  int promotionRowForSize(int boardSize) {
    assert(boardSize == 8 || boardSize == 10, 'Tamaño de tablero inválido');
    return this == PlayerColor.white ? 0 : boardSize - 1;
  }

  int get promotionRow => promotionRowForSize(8);

  String get displayName => this == PlayerColor.white ? 'Blancas' : 'Negras';
}

enum PieceType {
  pawn,
  king;

  bool get isKing => this == PieceType.king;
}

enum GameStatus {
  inProgress,
  whiteWins,
  blackWins,
  drawByFortyMoves,
  drawByRepetition;

  bool get isTerminal => this != GameStatus.inProgress;
}

class CheckersDomainError implements Exception {
  final String code;
  final String message;

  const CheckersDomainError({
    required this.code,
    required this.message,
  })  : assert(code != '', 'El código de error no puede ser vacío'),
        assert(message != '', 'El mensaje de error no puede ser vacío');

  @override
  String toString() => 'CheckersDomainError($code): $message';
}

class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col)
      : assert(row >= 0 && row < 10, 'Fila fuera de rango 0..9'),
        assert(col >= 0 && col < 10, 'Columna fuera de rango 0..9');

  bool get isDarkSquare => (row + col).isOdd;

  static bool isValidBounds(int row, int col, [int boardSize = 8]) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  static bool isPlayableDarkSquare(int row, int col, [int boardSize = 8]) {
    if (!isValidBounds(row, col, boardSize)) {
      return false;
    }
    return (row + col).isOdd;
  }

  static bool isPlayableForRuleset(
    int row,
    int col,
    CheckersRuleset ruleset,
  ) {
    if (!isValidBounds(row, col, ruleset.boardSize)) {
      return false;
    }
    if (ruleset.orthogonalMovement) {
      return true;
    }
    return (row + col).isOdd;
  }

  String toAlgebraicLabel([int boardSize = 8]) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    final rank = boardSize - row;
    return '${columns[col]}$rank';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BoardPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row * 31 + col;

  @override
  String toString() => '($row, $col)';
}

class CheckersPiece {
  final PlayerColor color;
  final PieceType type;

  const CheckersPiece({
    required this.color,
    required this.type,
  });

  bool get isKing => type == PieceType.king;

  CheckersPiece promoteToKing() {
    return CheckersPiece(color: color, type: PieceType.king);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CheckersPiece &&
        other.color == color &&
        other.type == type;
  }

  @override
  int get hashCode => color.index * 7 + type.index;
}

class CapturedPieceRecord {
  final BoardPosition position;
  final CheckersPiece piece;

  const CapturedPieceRecord({
    required this.position,
    required this.piece,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CapturedPieceRecord &&
        other.position == position &&
        other.piece == piece;
  }

  @override
  int get hashCode => position.hashCode * 19 + piece.hashCode;
}

class CheckersMove {
  final BoardPosition from;
  final BoardPosition to;
  final List<BoardPosition> stepPath;
  final List<CapturedPieceRecord> captures;
  final bool promotesToKing;

  CheckersMove({
    required this.from,
    required this.to,
    required List<BoardPosition> stepPath,
    required List<CapturedPieceRecord> captures,
    required this.promotesToKing,
  })  : stepPath = List<BoardPosition>.unmodifiable(stepPath),
        captures = List<CapturedPieceRecord>.unmodifiable(captures) {
    assert(from.row >= 0 && from.col >= 0, 'Coordenada origen válida');
    assert(to.row >= 0 && to.col >= 0, 'Coordenada destino válida');
    assert(stepPath.isNotEmpty, 'El camino de pasos no puede estar vacío');
  }

  bool get isCapture => captures.isNotEmpty;

  int get capturedCount => captures.length;

  int get capturedKingsCount {
    var count = 0;
    for (final record in captures) {
      if (record.piece.isKing) {
        count++;
      }
    }
    return count;
  }

  String toNotation([int boardSize = 8]) {
    final separator = isCapture ? 'x' : '-';
    return '${from.toAlgebraicLabel(boardSize)}$separator${to.toAlgebraicLabel(boardSize)}';
  }
}

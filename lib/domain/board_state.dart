// Estado inmutable del tablero (8x8 y 10x10) con soporte de las 7 variantes y Regla del Soplido.
// Metodología: GEM PROYECTOS SOFTWARE V4.0 (Negative Space Programming).

import 'checkers_types.dart';
import 'move_generator.dart';
import 'ruleset.dart';
import 'zobrist_hash.dart';

class BoardState {
  static const int maxHalfMovesWithoutProgress = 40;

  final CheckersRuleset ruleset;
  final List<CheckersPiece?> _squares;
  final PlayerColor turn;
  final int halfMovesWithoutProgress;
  final Map<int, int> positionCounts;
  final int zobristHash;
  final GameStatus status;
  final List<BoardPosition> huffablePositions;

  BoardState._({
    required this.ruleset,
    required List<CheckersPiece?> squares,
    required this.turn,
    required this.halfMovesWithoutProgress,
    required Map<int, int> positionCounts,
    required this.zobristHash,
    required this.status,
    required List<BoardPosition> huffablePositions,
  })  : _squares = List<CheckersPiece?>.unmodifiable(squares),
        positionCounts = Map<int, int>.unmodifiable(positionCounts),
        huffablePositions = List<BoardPosition>.unmodifiable(huffablePositions) {
    _assertBoardInvariants();
  }

  factory BoardState.initial({
    CheckersRuleset ruleset = CheckersRuleset.spanish,
  }) {
    final total = ruleset.totalSquares;
    final squares = List<CheckersPiece?>.filled(total, null);
    for (var index = 0; index < total; index++) {
      squares[index] = _initialPieceForIndex(index, ruleset);
    }
    return BoardState.custom(
      squares: squares,
      turn: PlayerColor.white,
      ruleset: ruleset,
      halfMovesWithoutProgress: 0,
      priorPositionCounts: const {},
      huffablePositions: const [],
    );
  }

  factory BoardState.custom({
    required List<CheckersPiece?> squares,
    required PlayerColor turn,
    CheckersRuleset ruleset = CheckersRuleset.spanish,
    int halfMovesWithoutProgress = 0,
    Map<int, int> priorPositionCounts = const {},
    List<BoardPosition> huffablePositions = const [],
  }) {
    assert(
      squares.length == ruleset.totalSquares,
      'El tablero debe tener exactamente ${ruleset.totalSquares} celdas',
    );
    assert(halfMovesWithoutProgress >= 0, 'Contador de jugadas negativo');
    final hash = ZobristHash.computeHash(squares, turn);
    final updatedCounts = Map<int, int>.from(priorPositionCounts);
    final currentOccurrences = (updatedCounts[hash] != null)
        ? updatedCounts[hash]! + 1
        : 1;
    updatedCounts[hash] = currentOccurrences;

    final provisional = BoardState._(
      ruleset: ruleset,
      squares: squares,
      turn: turn,
      halfMovesWithoutProgress: halfMovesWithoutProgress,
      positionCounts: updatedCounts,
      zobristHash: hash,
      status: GameStatus.inProgress,
      huffablePositions: huffablePositions,
    );
    final resolvedStatus = _evaluateBoardStatus(
      provisional,
      currentOccurrences,
    );
    return BoardState._(
      ruleset: ruleset,
      squares: squares,
      turn: turn,
      halfMovesWithoutProgress: halfMovesWithoutProgress,
      positionCounts: updatedCounts,
      zobristHash: hash,
      status: resolvedStatus,
      huffablePositions: huffablePositions,
    );
  }

  static CheckersPiece? _initialPieceForIndex(
    int index,
    CheckersRuleset ruleset,
  ) {
    final size = ruleset.boardSize;
    final row = index ~/ size;
    final col = index % size;
    if (!BoardPosition.isPlayableForRuleset(row, col, ruleset)) {
      return null;
    }
    if (ruleset.orthogonalMovement) {
      return _initialTurkishPiece(row);
    }
    final fillRows = size == 10 ? 4 : 3;
    if (row < fillRows) {
      return const CheckersPiece(color: PlayerColor.black, type: PieceType.pawn);
    }
    if (row >= size - fillRows) {
      return const CheckersPiece(color: PlayerColor.white, type: PieceType.pawn);
    }
    return null;
  }

  static CheckersPiece? _initialTurkishPiece(int row) {
    if (row == 1 || row == 2) {
      return const CheckersPiece(color: PlayerColor.black, type: PieceType.pawn);
    }
    if (row == 5 || row == 6) {
      return const CheckersPiece(color: PlayerColor.white, type: PieceType.pawn);
    }
    return null;
  }

  void _assertBoardInvariants() {
    assert(
      _squares.length == ruleset.totalSquares,
      'Cantidad de casillas inválida para la variante',
    );
    var activeSquares = 0;
    var whiteCount = 0;
    var blackCount = 0;
    final size = ruleset.boardSize;
    for (var i = 0; i < _squares.length; i++) {
      final isPlayable = BoardPosition.isPlayableForRuleset(
        i ~/ size,
        i % size,
        ruleset,
      );
      activeSquares += isPlayable ? 1 : 0;
      final piece = _squares[i];
      assert(isPlayable || piece == null, 'Pieza en casilla no jugable');
      whiteCount += (piece != null && piece.color == PlayerColor.white) ? 1 : 0;
      blackCount += (piece != null && piece.color == PlayerColor.black) ? 1 : 0;
    }
    if (size == 8 && !ruleset.orthogonalMovement) {
      assert(activeSquares == 32, 'Debe haber exactamente 32 casillas oscuras');
    }
    assert(
      activeSquares == ruleset.playableSquaresCount,
      'Casillas activas deben coincidir con la variante',
    );
    final maxPieces = ruleset.initialPiecesPerSide;
    assert(whiteCount >= 0 && whiteCount <= maxPieces, 'Conteo blanco inválido');
    assert(blackCount >= 0 && blackCount <= maxPieces, 'Conteo negro inválido');
  }

  List<CheckersPiece?> get rawSquares => _squares;

  CheckersPiece? pieceAt(BoardPosition position) {
    final size = ruleset.boardSize;
    return _squares[position.row * size + position.col];
  }

  int countPieces(PlayerColor color) {
    var count = 0;
    for (final piece in _squares) {
      if (piece != null && piece.color == color) {
        count++;
      }
    }
    return count;
  }

  int countKings(PlayerColor color) {
    var count = 0;
    for (final piece in _squares) {
      if (piece != null && piece.color == color && piece.isKing) {
        count++;
      }
    }
    return count;
  }

  List<CheckersMove> legalMoves() {
    if (status.isTerminal) {
      return const [];
    }
    return MoveGenerator.generateLegalMoves(this);
  }

  List<CheckersMove> mandatoryCaptures() {
    if (status.isTerminal) {
      return const [];
    }
    return MoveGenerator.generateMandatoryCapturesOnly(this);
  }

  bool get hasMandatoryCapture => mandatoryCaptures().isNotEmpty;

  bool get canHuff => ruleset.allowHuffing && huffablePositions.isNotEmpty;

  // Ejecuta el "Soplido" (retira gratis la ficha rival que omitió capturar).
  BoardState applyHuff(BoardPosition offendedSquare) {
    if (!canHuff || !huffablePositions.contains(offendedSquare)) {
      throw const CheckersDomainError(
        code: 'INVALID_HUFF_TARGET',
        message: 'Esa pieza no puede ser soplada en este turno.',
      );
    }
    final nextSquares = List<CheckersPiece?>.from(_squares);
    final size = ruleset.boardSize;
    nextSquares[offendedSquare.row * size + offendedSquare.col] = null;

    return BoardState.custom(
      squares: nextSquares,
      turn: turn,
      ruleset: ruleset,
      halfMovesWithoutProgress: 0,
      priorPositionCounts: positionCounts,
      huffablePositions: const [],
    );
  }

  BoardState applyMove(CheckersMove move) {
    if (status.isTerminal) {
      throw const CheckersDomainError(
        code: 'GAME_ALREADY_FINISHED',
        message: 'La partida ya ha concluido.',
      );
    }
    _validateMoveIsLegal(move);
    final nextHuffables = _computeHuffableAfterMove(move);
    final nextSquares = List<CheckersPiece?>.from(_squares);
    final movingPiece = pieceAt(move.from);
    assert(movingPiece != null, 'Debe existir una pieza en la casilla origen');

    final size = ruleset.boardSize;
    nextSquares[move.from.row * size + move.from.col] = null;
    for (final captured in move.captures) {
      nextSquares[captured.position.row * size + captured.position.col] = null;
    }
    final resultingPiece = move.promotesToKing
        ? movingPiece!.promoteToKing()
        : movingPiece!;
    nextSquares[move.to.row * size + move.to.col] = resultingPiece;

    final resetsProgress = move.isCapture || !movingPiece.isKing;
    final nextHalfMoves = resetsProgress ? 0 : halfMovesWithoutProgress + 1;

    return BoardState.custom(
      squares: nextSquares,
      turn: turn.opponent,
      ruleset: ruleset,
      halfMovesWithoutProgress: nextHalfMoves,
      priorPositionCounts: positionCounts,
      huffablePositions: nextHuffables,
    );
  }

  List<BoardPosition> _computeHuffableAfterMove(CheckersMove chosenMove) {
    if (!ruleset.allowHuffing) {
      return const [];
    }
    final mandatory = mandatoryCaptures();
    if (mandatory.isEmpty || chosenMove.isCapture) {
      return const [];
    }
    final offenders = <BoardPosition>[];
    for (final cap in mandatory) {
      final actualPos = cap.from == chosenMove.from ? chosenMove.to : cap.from;
      if (!offenders.contains(actualPos)) {
        offenders.add(actualPos);
      }
    }
    return offenders;
  }

  void _validateMoveIsLegal(CheckersMove candidate) {
    final availableMoves = legalMoves();
    for (final legal in availableMoves) {
      if (_areMovesEquivalent(legal, candidate)) {
        return;
      }
    }
    if (hasMandatoryCapture && !candidate.isCapture) {
      throw const CheckersDomainError(
        code: 'MANDATORY_CAPTURE_VIOLATION',
        message: 'Captura obligatoria disponible (RN-004): debes comer.',
      );
    }
    throw const CheckersDomainError(
      code: 'ILLEGAL_MOVE_OR_LAW_VIOLATION',
      message: 'Movimiento ilegal o incumple la Ley de Cantidad/Calidad (RN-005).',
    );
  }

  static bool _areMovesEquivalent(CheckersMove a, CheckersMove b) {
    if (a.from != b.from || a.to != b.to) {
      return false;
    }
    if (a.capturedCount != b.capturedCount ||
        a.capturedKingsCount != b.capturedKingsCount) {
      return false;
    }
    return true;
  }

  static GameStatus _evaluateBoardStatus(
    BoardState provisional,
    int currentOccurrences,
  ) {
    if (currentOccurrences >= 3) {
      return GameStatus.drawByRepetition;
    }
    if (provisional.halfMovesWithoutProgress >= maxHalfMovesWithoutProgress) {
      return GameStatus.drawByFortyMoves;
    }
    final available = MoveGenerator.generateLegalMoves(provisional);
    if (available.isEmpty) {
      return provisional.turn == PlayerColor.white
          ? GameStatus.blackWins
          : GameStatus.whiteWins;
    }
    return GameStatus.inProgress;
  }
}

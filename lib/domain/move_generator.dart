// Motor generador de movimientos reglamentarios para las 7 variantes mundiales + Regla del Soplido.
// Cumple RN-001 a RN-005 con Guard Clauses (anidación <= 2) y Negative Space Programming.

import 'board_state.dart';
import 'checkers_types.dart';
import 'ruleset.dart';

class MoveGenerator {
  static const List<List<int>> _allDiagonals = [
    [-1, -1],
    [-1, 1],
    [1, -1],
    [1, 1],
  ];

  static const List<List<int>> _allOrthogonals = [
    [-1, 0],
    [1, 0],
    [0, -1],
    [0, 1],
  ];

  static List<CheckersMove> generateLegalMoves(BoardState board) {
    assert(!board.status.isTerminal, 'No se generan jugadas en estado terminal');
    final rawCaptures = _generateAllCaptures(board);
    final filteredCaptures = rawCaptures.isNotEmpty
        ? _filterByQuantityAndQualityLaw(rawCaptures, board.ruleset)
        : const <CheckersMove>[];

    if (filteredCaptures.isEmpty) {
      return _generateAllSimpleMoves(board);
    }
    if (!board.ruleset.allowHuffing) {
      return filteredCaptures;
    }
    final simpleMoves = _generateAllSimpleMoves(board);
    return <CheckersMove>[...filteredCaptures, ...simpleMoves];
  }

  static List<CheckersMove> generateMandatoryCapturesOnly(BoardState board) {
    final rawCaptures = _generateAllCaptures(board);
    if (rawCaptures.isEmpty) {
      return const [];
    }
    return _filterByQuantityAndQualityLaw(rawCaptures, board.ruleset);
  }

  static List<CheckersMove> _generateAllCaptures(BoardState board) {
    final captures = <CheckersMove>[];
    final total = board.ruleset.totalSquares;
    for (var index = 0; index < total; index++) {
      _collectSquareCaptures(board, index, captures);
    }
    return captures;
  }

  static void _collectSquareCaptures(
    BoardState board,
    int index,
    List<CheckersMove> outCaptures,
  ) {
    final size = board.ruleset.boardSize;
    final pos = BoardPosition(index ~/ size, index % size);
    final piece = board.pieceAt(pos);
    if (piece == null || piece.color != board.turn) {
      return;
    }
    if (piece.isKing) {
      _expandKingCaptures(board, pos, pos, piece, [], [], outCaptures);
      return;
    }
    _expandPawnCaptures(board, pos, pos, piece, [], [], outCaptures);
  }

  static void _expandPawnCaptures(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    List<BoardPosition> stepsSoFar,
    List<CapturedPieceRecord> capturedSoFar,
    List<CheckersMove> results,
  ) {
    if (_shouldPromoteMidJump(board.ruleset, piece, current, capturedSoFar)) {
      final promoted = piece.promoteToKing();
      _expandKingCaptures(
        board,
        origin,
        current,
        promoted,
        stepsSoFar,
        capturedSoFar,
        results,
      );
      return;
    }
    final nextJumps = _findImmediatePawnJumps(
      board,
      origin,
      current,
      piece,
      capturedSoFar,
    );
    if (nextJumps.isEmpty) {
      _commitCaptureSequenceIfValid(
        board.ruleset,
        origin,
        current,
        piece,
        stepsSoFar,
        capturedSoFar,
        results,
      );
      return;
    }
    for (final jump in nextJumps) {
      _expandPawnCaptures(
        board,
        origin,
        jump.landing,
        piece,
        [...stepsSoFar, jump.landing],
        [...capturedSoFar, jump.capturedRecord],
        results,
      );
    }
  }

  static bool _shouldPromoteMidJump(
    CheckersRuleset ruleset,
    CheckersPiece piece,
    BoardPosition current,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (!ruleset.promoteMidJump || piece.isKing || capturedSoFar.isEmpty) {
      return false;
    }
    return current.row == piece.color.promotionRowForSize(ruleset.boardSize);
  }

  static List<_JumpStep> _findImmediatePawnJumps(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final directions = _pawnCaptureDirections(board.ruleset, piece.color);
    final jumps = <_JumpStep>[];
    for (final dir in directions) {
      final candidate = _tryBuildShortJump(
        board,
        origin,
        current,
        piece,
        dir[0],
        dir[1],
        capturedSoFar,
      );
      if (candidate != null) {
        jumps.add(candidate);
      }
    }
    return jumps;
  }

  static List<List<int>> _pawnCaptureDirections(
    CheckersRuleset ruleset,
    PlayerColor color,
  ) {
    final fwd = color.forwardRowDelta;
    if (ruleset.orthogonalMovement) {
      return [
        [fwd, 0],
        [0, -1],
        [0, 1],
      ];
    }
    if (ruleset.pawnCapturesBackward) {
      return _allDiagonals;
    }
    return [
      [fwd, -1],
      [fwd, 1],
    ];
  }

  static _JumpStep? _tryBuildShortJump(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    int rowDelta,
    int colDelta,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final ruleset = board.ruleset;
    final midRow = current.row + rowDelta;
    final midCol = current.col + colDelta;
    final landRow = current.row + (rowDelta * 2);
    final landCol = current.col + (colDelta * 2);
    if (!BoardPosition.isPlayableForRuleset(landRow, landCol, ruleset)) {
      return null;
    }
    final midPos = BoardPosition(midRow, midCol);
    final landPos = BoardPosition(landRow, landCol);
    if (_isAlreadyCaptured(midPos, capturedSoFar)) {
      return null;
    }
    final midPiece = board.pieceAt(midPos);
    if (!_isValidCaptureVictim(ruleset, piece, midPiece)) {
      return null;
    }
    if (!_isSquareEmptyDuringJump(board, origin, landPos, capturedSoFar)) {
      return null;
    }
    return _JumpStep(
      landing: landPos,
      capturedRecord: CapturedPieceRecord(position: midPos, piece: midPiece!),
    );
  }

  static bool _isValidCaptureVictim(
    CheckersRuleset ruleset,
    CheckersPiece attacker,
    CheckersPiece? victim,
  ) {
    if (victim == null || victim.color == attacker.color) {
      return false;
    }
    if (!ruleset.pawnCanCaptureKing && !attacker.isKing && victim.isKing) {
      return false;
    }
    return true;
  }

  static void _expandKingCaptures(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    List<BoardPosition> stepsSoFar,
    List<CapturedPieceRecord> capturedSoFar,
    List<CheckersMove> results,
  ) {
    final nextJumps = _findImmediateKingJumps(
      board,
      origin,
      current,
      piece,
      capturedSoFar,
    );
    if (nextJumps.isEmpty) {
      _commitCaptureSequenceIfValid(
        board.ruleset,
        origin,
        current,
        piece,
        stepsSoFar,
        capturedSoFar,
        results,
      );
      return;
    }
    for (final jump in nextJumps) {
      _expandKingCaptures(
        board,
        origin,
        jump.landing,
        piece,
        [...stepsSoFar, jump.landing],
        [...capturedSoFar, jump.capturedRecord],
        results,
      );
    }
  }

  static List<_JumpStep> _findImmediateKingJumps(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final directions = board.ruleset.orthogonalMovement
        ? _allOrthogonals
        : _allDiagonals;
    final jumps = <_JumpStep>[];
    for (final dir in directions) {
      final dirJumps = _scanDirectionForKingJumps(
        board,
        origin,
        current,
        piece,
        dir[0],
        dir[1],
        capturedSoFar,
      );
      jumps.addAll(dirJumps);
    }
    return jumps;
  }

  static List<_JumpStep> _scanDirectionForKingJumps(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    int dRow,
    int dCol,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (!board.ruleset.flyingKings) {
      final step = _tryBuildShortJump(
        board,
        origin,
        current,
        piece,
        dRow,
        dCol,
        capturedSoFar,
      );
      return step != null ? [step] : const [];
    }
    return _scanDiagonalForKingJumps(
      board,
      origin,
      current,
      piece,
      dRow,
      dCol,
      capturedSoFar,
    );
  }

  static List<_JumpStep> _scanDiagonalForKingJumps(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    int dRow,
    int dCol,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final enemyRecord = _findFirstObstacleOnRay(
      board,
      origin,
      current,
      piece,
      dRow,
      dCol,
      capturedSoFar,
    );
    if (enemyRecord == null) {
      return const [];
    }
    return _collectEmptyLandingsBeyondEnemy(
      board,
      origin,
      enemyRecord,
      dRow,
      dCol,
      capturedSoFar,
    );
  }

  static CapturedPieceRecord? _findFirstObstacleOnRay(
    BoardState board,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    int dRow,
    int dCol,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final ruleset = board.ruleset;
    var r = current.row + dRow;
    var c = current.col + dCol;
    while (BoardPosition.isPlayableForRuleset(r, c, ruleset)) {
      final pos = BoardPosition(r, c);
      if (_blocksRayByPriorCapture(ruleset, pos, capturedSoFar)) {
        return null;
      }
      final obstacle = _checkSquareForRayObstacle(
        board,
        origin,
        pos,
        piece,
        capturedSoFar,
      );
      if (obstacle != null) {
        return obstacle.isFriendlyBlocker ? null : obstacle.enemyRecord;
      }
      r += dRow;
      c += dCol;
    }
    return null;
  }

  static bool _blocksRayByPriorCapture(
    CheckersRuleset ruleset,
    BoardPosition pos,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (ruleset.immediateCaptureRemoval) {
      return false;
    }
    return _isAlreadyCaptured(pos, capturedSoFar);
  }

  static _RayObstacleResult? _checkSquareForRayObstacle(
    BoardState board,
    BoardPosition origin,
    BoardPosition pos,
    CheckersPiece attacker,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (_isAlreadyCaptured(pos, capturedSoFar)) {
      return null;
    }
    final occupant = _occupantDuringJump(board, origin, pos, capturedSoFar);
    if (occupant == null) {
      return null;
    }
    if (occupant.color == attacker.color) {
      return const _RayObstacleResult(
        isFriendlyBlocker: true,
        enemyRecord: null,
      );
    }
    return _RayObstacleResult(
      isFriendlyBlocker: false,
      enemyRecord: CapturedPieceRecord(position: pos, piece: occupant),
    );
  }

  static List<_JumpStep> _collectEmptyLandingsBeyondEnemy(
    BoardState board,
    BoardPosition origin,
    CapturedPieceRecord enemyRecord,
    int dRow,
    int dCol,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    final ruleset = board.ruleset;
    final landings = <_JumpStep>[];
    var r = enemyRecord.position.row + dRow;
    var c = enemyRecord.position.col + dCol;
    while (BoardPosition.isPlayableForRuleset(r, c, ruleset)) {
      final landPos = BoardPosition(r, c);
      if (!_isSquareEmptyDuringJump(board, origin, landPos, capturedSoFar)) {
        break;
      }
      landings.add(
        _JumpStep(landing: landPos, capturedRecord: enemyRecord),
      );
      r += dRow;
      c += dCol;
    }
    return landings;
  }

  static void _commitCaptureSequenceIfValid(
    CheckersRuleset ruleset,
    BoardPosition origin,
    BoardPosition current,
    CheckersPiece piece,
    List<BoardPosition> stepsSoFar,
    List<CapturedPieceRecord> capturedSoFar,
    List<CheckersMove> results,
  ) {
    if (capturedSoFar.isEmpty) {
      return;
    }
    final promoRow = piece.color.promotionRowForSize(ruleset.boardSize);
    final promotes = piece.isKing || current.row == promoRow;
    results.add(
      CheckersMove(
        from: origin,
        to: current,
        stepPath: stepsSoFar,
        captures: capturedSoFar,
        promotesToKing: promotes,
      ),
    );
  }

  // RN-005: Filtro paramétrico de Ley de Cantidad y Ley de Calidad.
  static List<CheckersMove> _filterByQuantityAndQualityLaw(
    List<CheckersMove> captures,
    CheckersRuleset ruleset,
  ) {
    assert(captures.isNotEmpty, 'Lista de capturas no puede estar vacía');
    if (!ruleset.enforceQuantityLaw) {
      return captures;
    }
    var maxQuantity = 0;
    var maxQuality = 0;
    for (final move in captures) {
      if (_isStrictlyBetterCapture(move, maxQuantity, maxQuality, ruleset)) {
        maxQuantity = move.capturedCount;
        maxQuality = move.capturedKingsCount;
      }
    }
    final filtered = <CheckersMove>[];
    for (final move in captures) {
      if (_matchesBestCaptureScore(move, maxQuantity, maxQuality, ruleset)) {
        filtered.add(move);
      }
    }
    assert(filtered.isNotEmpty, 'El filtro RN-005 debe conservar jugadas');
    return filtered;
  }

  static bool _isStrictlyBetterCapture(
    CheckersMove move,
    int currentMaxQuantity,
    int currentMaxQuality,
    CheckersRuleset ruleset,
  ) {
    if (move.capturedCount != currentMaxQuantity) {
      return move.capturedCount > currentMaxQuantity;
    }
    if (!ruleset.enforceQualityLaw) {
      return false;
    }
    return move.capturedKingsCount > currentMaxQuality;
  }

  static bool _matchesBestCaptureScore(
    CheckersMove move,
    int maxQuantity,
    int maxQuality,
    CheckersRuleset ruleset,
  ) {
    if (move.capturedCount != maxQuantity) {
      return false;
    }
    if (!ruleset.enforceQualityLaw) {
      return true;
    }
    return move.capturedKingsCount == maxQuality;
  }

  static List<CheckersMove> _generateAllSimpleMoves(BoardState board) {
    final moves = <CheckersMove>[];
    final total = board.ruleset.totalSquares;
    for (var index = 0; index < total; index++) {
      _collectSquareSimpleMoves(board, index, moves);
    }
    return moves;
  }

  static void _collectSquareSimpleMoves(
    BoardState board,
    int index,
    List<CheckersMove> outMoves,
  ) {
    final size = board.ruleset.boardSize;
    final pos = BoardPosition(index ~/ size, index % size);
    final piece = board.pieceAt(pos);
    if (piece == null || piece.color != board.turn) {
      return;
    }
    if (piece.isKing) {
      _collectKingSimpleMoves(board, pos, outMoves);
      return;
    }
    _collectPawnSimpleMoves(board, pos, piece, outMoves);
  }

  static void _collectPawnSimpleMoves(
    BoardState board,
    BoardPosition from,
    CheckersPiece piece,
    List<CheckersMove> outMoves,
  ) {
    final ruleset = board.ruleset;
    final fwd = piece.color.forwardRowDelta;
    final directions = ruleset.orthogonalMovement
        ? [
            [fwd, 0],
            [0, -1],
            [0, 1],
          ]
        : [
            [fwd, -1],
            [fwd, 1],
          ];
    for (final dir in directions) {
      _tryAddPawnStep(
        board,
        from,
        piece,
        from.row + dir[0],
        from.col + dir[1],
        outMoves,
      );
    }
  }

  static void _tryAddPawnStep(
    BoardState board,
    BoardPosition from,
    CheckersPiece piece,
    int nextRow,
    int nextCol,
    List<CheckersMove> outMoves,
  ) {
    final ruleset = board.ruleset;
    if (!BoardPosition.isPlayableForRuleset(nextRow, nextCol, ruleset)) {
      return;
    }
    final to = BoardPosition(nextRow, nextCol);
    if (board.pieceAt(to) != null) {
      return;
    }
    final promotes =
        to.row == piece.color.promotionRowForSize(ruleset.boardSize);
    outMoves.add(
      CheckersMove(
        from: from,
        to: to,
        stepPath: [to],
        captures: const [],
        promotesToKing: promotes,
      ),
    );
  }

  static void _collectKingSimpleMoves(
    BoardState board,
    BoardPosition from,
    List<CheckersMove> outMoves,
  ) {
    final directions = board.ruleset.orthogonalMovement
        ? _allOrthogonals
        : _allDiagonals;
    for (final dir in directions) {
      _scanKingSimpleRay(board, from, dir[0], dir[1], outMoves);
    }
  }

  static void _scanKingSimpleRay(
    BoardState board,
    BoardPosition from,
    int dRow,
    int dCol,
    List<CheckersMove> outMoves,
  ) {
    final ruleset = board.ruleset;
    var r = from.row + dRow;
    var c = from.col + dCol;
    while (BoardPosition.isPlayableForRuleset(r, c, ruleset)) {
      final to = BoardPosition(r, c);
      if (board.pieceAt(to) != null) {
        return;
      }
      outMoves.add(
        CheckersMove(
          from: from,
          to: to,
          stepPath: [to],
          captures: const [],
          promotesToKing: false,
        ),
      );
      if (!ruleset.flyingKings) {
        return;
      }
      r += dRow;
      c += dCol;
    }
  }

  static bool _isAlreadyCaptured(
    BoardPosition pos,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    for (final rec in capturedSoFar) {
      if (rec.position == pos) {
        return true;
      }
    }
    return false;
  }

  static CheckersPiece? _occupantDuringJump(
    BoardState board,
    BoardPosition origin,
    BoardPosition pos,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (pos == origin) {
      return null;
    }
    if (board.ruleset.immediateCaptureRemoval &&
        _isAlreadyCaptured(pos, capturedSoFar)) {
      return null;
    }
    return board.pieceAt(pos);
  }

  static bool _isSquareEmptyDuringJump(
    BoardState board,
    BoardPosition origin,
    BoardPosition pos,
    List<CapturedPieceRecord> capturedSoFar,
  ) {
    if (!board.ruleset.immediateCaptureRemoval &&
        _isAlreadyCaptured(pos, capturedSoFar)) {
      return false;
    }
    return _occupantDuringJump(board, origin, pos, capturedSoFar) == null;
  }
}

class _JumpStep {
  final BoardPosition landing;
  final CapturedPieceRecord capturedRecord;

  const _JumpStep({
    required this.landing,
    required this.capturedRecord,
  });
}

class _RayObstacleResult {
  final bool isFriendlyBlocker;
  final CapturedPieceRecord? enemyRecord;

  const _RayObstacleResult({
    required this.isFriendlyBlocker,
    required this.enemyRecord,
  });
}


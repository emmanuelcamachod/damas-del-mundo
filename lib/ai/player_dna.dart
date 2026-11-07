// Radiografía "ADN del Jugador" (RF-003 / RN-007).
// Analiza las jugadas del usuario humano para perfilar su estilo y mostrar cómo se adapta la IA.

import '../domain/checkers_engine.dart';

class PlayerDnaProfile {
  final int analyzedMoves;
  final int aggressionScorePct;
  final int backRowDisciplinePct;
  final String preferredFlank;
  final int huffViolationsCount;
  final String tacticalSummary;
  final String aiCounterStrategy;

  const PlayerDnaProfile({
    required this.analyzedMoves,
    required this.aggressionScorePct,
    required this.backRowDisciplinePct,
    required this.preferredFlank,
    required this.huffViolationsCount,
    required this.tacticalSummary,
    required this.aiCounterStrategy,
  })  : assert(aggressionScorePct >= 0 && aggressionScorePct <= 100, 'Agresividad 0..100'),
        assert(backRowDisciplinePct >= 0 && backRowDisciplinePct <= 100, 'Disciplina 0..100');

  factory PlayerDnaProfile.initial() {
    return const PlayerDnaProfile(
      analyzedMoves: 0,
      aggressionScorePct: 50,
      backRowDisciplinePct: 100,
      preferredFlank: 'Equilibrado (Centro)',
      huffViolationsCount: 0,
      tacticalSummary: 'Juega tus primeros turnos para que la IA escanee tu ADN táctico.',
      aiCounterStrategy: 'Motor Maestro Alfa-Beta en calibración inicial.',
    );
  }
}

class PlayerDnaTracker {
  int _totalHumanMoves = 0;
  int _aggressiveMoves = 0;
  int _earlyBackRowMoves = 0;
  int _leftFlankMoves = 0;
  int _rightFlankMoves = 0;
  int _huffViolations = 0;

  void recordHumanMove({
    required BoardState boardBefore,
    required CheckersMove move,
  }) {
    _totalHumanMoves++;
    if (move.isCapture || move.promotesToKing) {
      _aggressiveMoves++;
    }
    if (_isEarlyBackRowMove(boardBefore, move)) {
      _earlyBackRowMoves++;
    }
    final midCol = boardBefore.ruleset.boardSize ~/ 2;
    if (move.to.col < midCol) {
      _leftFlankMoves++;
    } else {
      _rightFlankMoves++;
    }
    if (boardBefore.ruleset.allowHuffing &&
        boardBefore.hasMandatoryCapture &&
        !move.isCapture) {
      _huffViolations++;
    }
  }

  static bool _isEarlyBackRowMove(BoardState board, CheckersMove move) {
    final size = board.ruleset.boardSize;
    final homeRow = board.turn == PlayerColor.white ? size - 1 : 0;
    return move.from.row == homeRow && board.countPieces(board.turn) >= 8;
  }

  PlayerDnaProfile buildProfile() {
    if (_totalHumanMoves == 0) {
      return PlayerDnaProfile.initial();
    }
    final aggression = ((_aggressiveMoves * 100) ~/ _totalHumanMoves).clamp(15, 98);
    final backRowPenalty = _earlyBackRowMoves * 18;
    final discipline = (100 - backRowPenalty).clamp(10, 100);
    final flank = _resolvePreferredFlank();

    return PlayerDnaProfile(
      analyzedMoves: _totalHumanMoves,
      aggressionScorePct: aggression,
      backRowDisciplinePct: discipline,
      preferredFlank: flank,
      huffViolationsCount: _huffViolations,
      tacticalSummary: _buildSummaryText(aggression, discipline, flank),
      aiCounterStrategy: _buildCounterStrategyText(aggression, discipline),
    );
  }

  String _resolvePreferredFlank() {
    if ((_leftFlankMoves - _rightFlankMoves).abs() <= 1) {
      return 'Centro Equilibrado';
    }
    return _leftFlankMoves > _rightFlankMoves
        ? 'Flanco Izquierdo (Columnas a-d)'
        : 'Flanco Derecho (Columnas e-h)';
  }

  static String _buildSummaryText(
    int aggression,
    int discipline,
    String flank,
  ) {
    final styleLabel = aggression >= 55 ? 'Táctico-Agresivo' : 'Posicional-Cauto';
    return 'Estilo $styleLabel ($aggression% ataque) con preferencia por $flank y $discipline% de solidez en Fila Real.';
  }

  static String _buildCounterStrategyText(int aggression, int discipline) {
    if (discipline < 75) {
      return 'La IA detectó que abres huecos en tu Fila Base temprano: ha incrementado su peso de infiltración y coronación rápida.';
    }
    if (aggression >= 60) {
      return 'La IA detectó alta agresividad: prioriza trampas de sacrificio 2-por-1 y control del centro para castigar avances prematuros.';
    }
    return 'La IA aplica presión posicional en las casillas centrales y busca bloqueos de oposición a largo plazo.';
  }

  void reset() {
    _totalHumanMoves = 0;
    _aggressiveMoves = 0;
    _earlyBackRowMoves = 0;
    _leftFlankMoves = 0;
    _rightFlankMoves = 0;
    _huffViolations = 0;
  }

  Map<String, int> toJson() {
    return <String, int>{
      'totalHumanMoves': _totalHumanMoves,
      'aggressiveMoves': _aggressiveMoves,
      'earlyBackRowMoves': _earlyBackRowMoves,
      'leftFlankMoves': _leftFlankMoves,
      'rightFlankMoves': _rightFlankMoves,
      'huffViolations': _huffViolations,
    };
  }

  void restoreFromJson(Map<String, dynamic> json) {
    assert(json.isNotEmpty, 'El mapa JSON de ADN no puede ser vacío');
    _totalHumanMoves = _readSafeInt(json, 'totalHumanMoves');
    _aggressiveMoves = _readSafeInt(json, 'aggressiveMoves');
    _earlyBackRowMoves = _readSafeInt(json, 'earlyBackRowMoves');
    _leftFlankMoves = _readSafeInt(json, 'leftFlankMoves');
    _rightFlankMoves = _readSafeInt(json, 'rightFlankMoves');
    _huffViolations = _readSafeInt(json, 'huffViolations');
  }

  static int _readSafeInt(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is int && val >= 0) {
      return val;
    }
    return 0;
  }
}

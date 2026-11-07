// Aprendizaje Adaptativo Local por Diferencias Temporales (TD-Learning) y Libro de Patrones del Rival.
// Cumple RF-003 y RN-007 (pesos estrictamente acotados con clamp).

import '../domain/checkers_engine.dart';
import 'heuristic_weights.dart';
import 'player_dna.dart';

class AdaptiveLearner {
  static const double learningRate = 0.14;

  HeuristicWeights _currentWeights;
  final Map<int, double> _opponentPatternBias = <int, double>{};
  int _gamesLearned = 0;
  int _aiWins = 0;
  int _humanWins = 0;
  int _draws = 0;

  AdaptiveLearner({
    HeuristicWeights initialWeights = const HeuristicWeights(),
  }) : _currentWeights = initialWeights;

  HeuristicWeights get currentWeights => _currentWeights;
  int get gamesLearned => _gamesLearned;
  int get aiWins => _aiWins;
  int get humanWins => _humanWins;
  int get draws => _draws;

  Map<int, double> get opponentPatternBias =>
      Map<int, double>.unmodifiable(_opponentPatternBias);

  // Genera pesos dinámicos modulados por el ADN del rival para contrarrestar su estrategia activa.
  HeuristicWeights getCounterStrategyWeights(PlayerDnaProfile dna) {
    var king = _currentWeights.kingValue;
    var advance = _currentWeights.advancementBonus;
    var center = _currentWeights.centerControlBonus;
    var backRow = _currentWeights.backRowGuardBonus;
    var vuln = _currentWeights.vulnerabilityPenalty;

    if (dna.backRowDisciplinePct < 75) {
      king += 25.0;
      advance += 5.0;
    }
    if (dna.aggressionScorePct >= 60) {
      backRow += 10.0;
      center += 8.0;
      vuln += 8.0;
    }
    return _currentWeights.clampedCopy(
      pawn: _currentWeights.pawnValue,
      king: king,
      center: center,
      backRow: backRow,
      advance: advance,
      vulnerability: vuln,
    );
  }

  // Ajusta los pesos heurísticos al finalizar una partida según la trayectoria observada.
  HeuristicWeights learnFromCompletedGame({
    required List<BoardState> stateTrajectory,
    required PlayerColor aiColor,
    required GameStatus finalStatus,
  }) {
    assert(stateTrajectory.isNotEmpty, 'La trayectoria no puede estar vacía');
    _recordGameOutcome(finalStatus, aiColor);
    final outcomeReward = _rewardForOutcome(finalStatus, aiColor);
    _updateOpponentBook(stateTrajectory, outcomeReward);
    _applyTemporalDifferenceUpdate(stateTrajectory, aiColor, outcomeReward);
    _gamesLearned++;
    return _currentWeights;
  }

  void _recordGameOutcome(GameStatus status, PlayerColor aiColor) {
    if (status == GameStatus.drawByFortyMoves ||
        status == GameStatus.drawByRepetition) {
      _draws++;
      return;
    }
    final aiWon = (status == GameStatus.whiteWins && aiColor == PlayerColor.white) ||
        (status == GameStatus.blackWins && aiColor == PlayerColor.black);
    if (aiWon) {
      _aiWins++;
      return;
    }
    _humanWins++;
  }

  static double _rewardForOutcome(GameStatus status, PlayerColor aiColor) {
    if (status == GameStatus.whiteWins) {
      return aiColor == PlayerColor.white ? 1.0 : -1.0;
    }
    if (status == GameStatus.blackWins) {
      return aiColor == PlayerColor.black ? 1.0 : -1.0;
    }
    return 0.0;
  }

  void _updateOpponentBook(
    List<BoardState> trajectory,
    double outcomeReward,
  ) {
    final limit = trajectory.length < 12 ? trajectory.length : 12;
    for (var i = 0; i < limit; i++) {
      final hash = trajectory[i].zobristHash;
      final prior = _opponentPatternBias[hash] != null
          ? _opponentPatternBias[hash]!
          : 0.0;
      final updated = _clampDouble(prior + (outcomeReward * 6.5), -35.0, 35.0);
      _opponentPatternBias[hash] = updated;
    }
  }

  void _applyTemporalDifferenceUpdate(
    List<BoardState> trajectory,
    PlayerColor aiColor,
    double outcomeReward,
  ) {
    // Si la IA perdió o empató, refuerza defensa de fila base, control del centro y valor de Dama.
    final adaptationSignal = -outcomeReward;
    final delta = learningRate * adaptationSignal;

    _currentWeights = _currentWeights.clampedCopy(
      pawn: _currentWeights.pawnValue + (delta * 15.0),
      king: _currentWeights.kingValue + (delta * 45.0),
      center: _currentWeights.centerControlBonus + (delta * 12.0),
      backRow: _currentWeights.backRowGuardBonus + (delta * 16.0),
      advance: _currentWeights.advancementBonus + (delta * 5.0),
      vulnerability: _currentWeights.vulnerabilityPenalty + (delta * 14.0),
    );
  }

  void resetMemory() {
    _currentWeights = const HeuristicWeights();
    _opponentPatternBias.clear();
    _gamesLearned = 0;
    _aiWins = 0;
    _humanWins = 0;
    _draws = 0;
  }

  Map<String, dynamic> toJson() {
    final serializedPatterns = <String, double>{};
    for (final entry in _opponentPatternBias.entries) {
      serializedPatterns[entry.key.toString()] = entry.value;
    }
    return <String, dynamic>{
      'weights': _currentWeights.toMap(),
      'patternBook': serializedPatterns,
      'gamesLearned': _gamesLearned,
      'aiWins': _aiWins,
      'humanWins': _humanWins,
      'draws': _draws,
    };
  }

  void restoreFromJson(Map<String, dynamic> json) {
    assert(json.isNotEmpty, 'JSON de AdaptiveLearner no puede ser vacío');
    final rawWeights = json['weights'];
    if (rawWeights is Map<String, dynamic> && rawWeights.isNotEmpty) {
      _currentWeights = HeuristicWeights.fromMap(rawWeights);
    }
    _restorePatternBook(json['patternBook']);
    _gamesLearned = _readNonNegativeInt(json, 'gamesLearned');
    _aiWins = _readNonNegativeInt(json, 'aiWins');
    _humanWins = _readNonNegativeInt(json, 'humanWins');
    _draws = _readNonNegativeInt(json, 'draws');
  }

  void _restorePatternBook(Object? rawBook) {
    _opponentPatternBias.clear();
    if (rawBook is! Map<String, dynamic>) {
      return;
    }
    for (final entry in rawBook.entries) {
      _insertPatternEntry(entry.key, entry.value);
    }
  }

  void _insertPatternEntry(String keyText, Object? rawBias) {
    final parsedHash = int.tryParse(keyText);
    if (parsedHash != null && rawBias is num) {
      _opponentPatternBias[parsedHash] = _clampDouble(
        rawBias.toDouble(),
        -35.0,
        35.0,
      );
    }
  }

  static int _readNonNegativeInt(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is int && val >= 0) {
      return val;
    }
    return 0;
  }

  static double _clampDouble(double val, double minVal, double maxVal) {
    if (val < minVal) {
      return minVal;
    }
    if (val > maxVal) {
      return maxVal;
    }
    return val;
  }
}

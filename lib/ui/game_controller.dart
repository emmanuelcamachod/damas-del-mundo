// Controlador de estado multivariante, IA Adaptativa, Academia 10 Niveles, Coach y Detector de Errores.
// Cumple RF-001 a RF-006 y RNF-004 (5 estados visuales, anidación <= 2).

import 'package:flutter/foundation.dart';
import '../academy/academy_engine.dart';
import '../ai/ai_engine.dart';
import '../domain/checkers_engine.dart';
import '../storage/local_storage_service.dart';

enum UiFeedbackState {
  loading,
  empty,
  humanError,
  success,
  disabled,
}

class MoveHistoryEntry {
  final int moveNumber;
  final PlayerColor player;
  final String notation;
  final int capturedCount;
  final bool promoted;

  const MoveHistoryEntry({
    required this.moveNumber,
    required this.player,
    required this.notation,
    required this.capturedCount,
    required this.promoted,
  });
}

class GameController extends ChangeNotifier {
  final LocalStorageService _storageService;
  BoardState _currentBoard = BoardState.initial();
  final List<BoardState> _boardHistory = <BoardState>[];
  final List<MoveHistoryEntry> _moveLog = <MoveHistoryEntry>[];
  final List<BlunderRecord> _detectedBlunders = <BlunderRecord>[];

  final AdaptiveLearner _adaptiveLearner = AdaptiveLearner();
  final PlayerDnaTracker _dnaTracker = PlayerDnaTracker();
  final AcademyProgressMap _academyProgress = AcademyProgressMap();
  final Set<String> _completedLessonIds = <String>{};

  GameController({
    LocalStorageService? storageService,
  }) : _storageService =
            storageService ?? LocalStorageService.defaultDeviceStorage();

  TacticalLesson? _activeLesson;
  int _infinitePuzzleSeed = 1;
  int _infinitePuzzlesSolved = 0;

  BoardPosition? _selectedPosition;
  String? _humanErrorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _vsAiEnabled = true;
  int _aiSearchDepth = 4;
  double _lastEvaluationCp = 0.0;

  BoardState get currentBoard => _currentBoard;
  BoardPosition? get selectedPosition => _selectedPosition;
  String? get humanErrorMessage => _humanErrorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get vsAiEnabled => _vsAiEnabled;
  int get aiSearchDepth => _aiSearchDepth;
  double get lastEvaluationCp => _lastEvaluationCp;
  AdaptiveLearner get adaptiveLearner => _adaptiveLearner;
  PlayerDnaProfile get playerDnaProfile => _dnaTracker.buildProfile();
  AcademyProgressMap get academyProgress => _academyProgress;
  TacticalLesson? get activeLesson => _activeLesson;
  int get infinitePuzzlesSolved => _infinitePuzzlesSolved;

  bool saveProfileToDisk() {
    return _storageService.saveAll(
      learner: _adaptiveLearner,
      dnaTracker: _dnaTracker,
      academyProgress: _academyProgress,
      completedLessons: _completedLessonIds,
      infinitePuzzlesSolved: _infinitePuzzlesSolved,
    );
  }

  void loadProfileFromDisk() {
    final snapshot = _storageService.loadSnapshot();
    _storageService.restoreInto(
      learner: _adaptiveLearner,
      dnaTracker: _dnaTracker,
      academyProgress: _academyProgress,
      completedLessonsOutput: _completedLessonIds,
    );
    _infinitePuzzlesSolved = snapshot.infinitePuzzlesSolved;
    notifyListeners();
  }

  Set<String> get completedLessonIds =>
      Set<String>.unmodifiable(_completedLessonIds);

  List<MoveHistoryEntry> get moveLog =>
      List<MoveHistoryEntry>.unmodifiable(_moveLog);

  List<BlunderRecord> get detectedBlunders =>
      List<BlunderRecord>.unmodifiable(_detectedBlunders);

  bool get canUndo => !_isLoading && _boardHistory.isNotEmpty;

  UiFeedbackState get currentVisualState {
    if (_isLoading) {
      return UiFeedbackState.loading;
    }
    if (_humanErrorMessage != null) {
      return UiFeedbackState.humanError;
    }
    if (_currentBoard.status.isTerminal || _successMessage != null) {
      return UiFeedbackState.success;
    }
    if (_moveLog.isEmpty) {
      return UiFeedbackState.empty;
    }
    return UiFeedbackState.disabled;
  }

  List<CheckersMove> get legalMovesForCurrentTurn => _currentBoard.legalMoves();

  List<CheckersMove> get movesForSelectedPiece {
    if (_selectedPosition == null) {
      return const [];
    }
    final filtered = <CheckersMove>[];
    for (final move in legalMovesForCurrentTurn) {
      if (move.from == _selectedPosition) {
        filtered.add(move);
      }
    }
    return filtered;
  }

  void startAcademyLesson(TacticalLesson lesson) {
    _activeLesson = lesson;
    _currentBoard = lesson.initialBoard;
    _boardHistory.clear();
    _moveLog.clear();
    _selectedPosition = null;
    _humanErrorMessage = null;
    _successMessage =
        '[${lesson.techniqueName}] ${lesson.theoryExplanation} Objetivo: ${lesson.objectivePrompt}';
    notifyListeners();
  }

  void startNextInfinitePuzzle() {
    final puzzle = InfinitePuzzleGenerator.generateProceduralPuzzle(
      seed: _infinitePuzzleSeed++,
      ruleset: _currentBoard.ruleset,
    );
    startAcademyLesson(puzzle);
  }

  void exitAcademyMode() {
    _activeLesson = null;
    resetGame();
  }

  void requestCoachAdvice() {
    if (_currentBoard.status.isTerminal || _isLoading) {
      return;
    }
    final advice = TacticalCoach.analyzePosition(
      _currentBoard,
      weights: _adaptiveLearner.currentWeights,
    );
    _selectedPosition = advice.recommendedMove.from;
    _humanErrorMessage = null;
    _successMessage = advice.tacticalExplanation;
    notifyListeners();
  }

  void changeRuleset(CheckersRuleset newRuleset) {
    _activeLesson = null;
    _currentBoard = BoardState.initial(ruleset: newRuleset);
    _boardHistory.clear();
    _moveLog.clear();
    _detectedBlunders.clear();
    _selectedPosition = null;
    _lastEvaluationCp = 0.0;
    _clearFeedbackMessages();
    notifyListeners();
  }

  void toggleHuffingRule(bool enabled) {
    final updated = _currentBoard.ruleset.copyWith(allowHuffing: enabled);
    changeRuleset(updated);
  }

  void toggleVsAiMode(bool enabled) {
    _activeLesson = null;
    _vsAiEnabled = enabled;
    resetGame();
  }

  void huffOpponentPiece(BoardPosition target) {
    if (!_currentBoard.canHuff) {
      return;
    }
    _boardHistory.add(_currentBoard);
    _currentBoard = _currentBoard.applyHuff(target);
    _successMessage =
        '¡Soplido ejecutado! Retiraste la ficha en ${target.toAlgebraicLabel(_currentBoard.ruleset.boardSize)} por omitir captura.';
    notifyListeners();
  }

  void onSquareTapped(BoardPosition tapped) {
    final size = _currentBoard.ruleset.boardSize;
    assert(BoardPosition.isValidBounds(tapped.row, tapped.col, size), 'Fuera de rango');
    if (_isLoading || _currentBoard.status.isTerminal) {
      return;
    }
    if (_currentBoard.canHuff && _currentBoard.huffablePositions.contains(tapped)) {
      huffOpponentPiece(tapped);
      return;
    }
    if (!BoardPosition.isPlayableForRuleset(tapped.row, tapped.col, _currentBoard.ruleset)) {
      _setHumanError('En esta variante esa casilla no es jugable.');
      return;
    }
    final matchingMove = _findMoveToTarget(tapped);
    if (matchingMove != null) {
      _handleChosenMove(matchingMove);
      return;
    }
    _selectPieceAt(tapped);
  }

  void _handleChosenMove(CheckersMove move) {
    if (_activeLesson != null) {
      _evaluateAcademyAttempt(move);
      return;
    }
    _executeHumanMove(move);
  }

  void _evaluateAcademyAttempt(CheckersMove move) {
    final lesson = _activeLesson!;
    if (!lesson.isMatchingSolution(move)) {
      _setHumanError('Jugada incorrecta para "${lesson.techniqueName}". Pista: ${lesson.failureHint}');
      return;
    }
    _completedLessonIds.add(lesson.id);
    if (lesson.id.startsWith('INF_PUZZLE_')) {
      _infinitePuzzlesSolved++;
    }
    _applyMoveInternal(move);
    _successMessage = '¡Lección Superada! ${lesson.successExplanation}';
    notifyListeners();
  }

  CheckersMove? _findMoveToTarget(BoardPosition target) {
    for (final move in movesForSelectedPiece) {
      if (move.to == target) {
        return move;
      }
    }
    return null;
  }

  void _selectPieceAt(BoardPosition pos) {
    final piece = _currentBoard.pieceAt(pos);
    if (piece == null) {
      _selectedPosition = null;
      _clearFeedbackMessages();
      notifyListeners();
      return;
    }
    if (piece.color != _currentBoard.turn) {
      _setHumanError('Es el turno de las ${_currentBoard.turn.displayName}.');
      return;
    }
    if (!_pieceHasLegalMoves(pos)) {
      _explainWhyPieceCannotMove();
      return;
    }
    _selectedPosition = pos;
    _clearFeedbackMessages();
    notifyListeners();
  }

  bool _pieceHasLegalMoves(BoardPosition pos) {
    for (final move in legalMovesForCurrentTurn) {
      if (move.from == pos) {
        return true;
      }
    }
    return false;
  }

  void _explainWhyPieceCannotMove() {
    _selectedPosition = null;
    if (_currentBoard.hasMandatoryCapture && !_currentBoard.ruleset.allowHuffing) {
      _setHumanError(
        'Captura obligatoria activa (${_currentBoard.ruleset.displayName}): '
        'debes mover la ficha resaltada que cumple la ley de captura.',
      );
      return;
    }
    _setHumanError('Esta ficha está bloqueada y no tiene movimientos libres.');
  }

  void _executeHumanMove(CheckersMove move) {
    final boardBefore = _currentBoard;
    final historyIdx = _boardHistory.length;
    final moveNum = _moveLog.length + 1;

    _dnaTracker.recordHumanMove(boardBefore: boardBefore, move: move);
    final blunder = BlunderDetector.inspectHumanMove(
      boardBefore: boardBefore,
      playedMove: move,
      moveNumber: moveNum,
      boardHistoryIndex: historyIdx,
      weights: _adaptiveLearner.currentWeights,
    );
    if (blunder != null) {
      _detectedBlunders.add(blunder);
    }

    _applyMoveInternal(move);
    if (_vsAiEnabled &&
        !_currentBoard.status.isTerminal &&
        _currentBoard.turn == PlayerColor.black) {
      _triggerAiResponse();
    }
  }

  void _applyMoveInternal(CheckersMove move) {
    final movingColor = _currentBoard.turn;
    final size = _currentBoard.ruleset.boardSize;
    _boardHistory.add(_currentBoard);
    _currentBoard = _currentBoard.applyMove(move);
    _selectedPosition = null;
    _clearFeedbackMessages();

    _moveLog.add(
      MoveHistoryEntry(
        moveNumber: _moveLog.length + 1,
        player: movingColor,
        notation: move.toNotation(size),
        capturedCount: move.capturedCount,
        promoted: move.promotesToKing,
      ),
    );
    _lastEvaluationCp = BoardEvaluator.evaluate(
      _currentBoard,
      PlayerColor.white,
      _adaptiveLearner.currentWeights,
    );
    _handleTerminalIfReached();
    notifyListeners();
  }

  Future<void> _triggerAiResponse() async {
    _isLoading = true;
    notifyListeners();

    final dna = _dnaTracker.buildProfile();
    final counterWeights = _adaptiveLearner.getCounterStrategyWeights(dna);
    final decision = await AlphaBetaSolver.computeInBackground(
      board: _currentBoard,
      maxDepth: _aiSearchDepth,
      weights: counterWeights,
      opponentPatternBias: _adaptiveLearner.opponentPatternBias,
    );

    _isLoading = false;
    if (decision.recommendedHuffPosition != null && _currentBoard.canHuff) {
      _currentBoard = _currentBoard.applyHuff(decision.recommendedHuffPosition!);
    }
    if (decision.bestMove != null && !_currentBoard.status.isTerminal) {
      _applyMoveInternal(decision.bestMove!);
      return;
    }
    notifyListeners();
  }

  void _handleTerminalIfReached() {
    if (!_currentBoard.status.isTerminal || _activeLesson != null) {
      return;
    }
    _adaptiveLearner.learnFromCompletedGame(
      stateTrajectory: [..._boardHistory, _currentBoard],
      aiColor: PlayerColor.black,
      finalStatus: _currentBoard.status,
    );
    saveProfileToDisk();
    _updateTerminalSuccessBanner();
  }

  void _updateTerminalSuccessBanner() {
    switch (_currentBoard.status) {
      case GameStatus.whiteWins:
        _successMessage =
            '¡Victoria de las Blancas! La IA ha ajustado sus pesos TD-Learning tras la partida.';
        return;
      case GameStatus.blackWins:
        _successMessage =
            '¡Victoria de las Negras (IA Némesis)! Revisa el Detector de Errores para reintentar tu jugada clave.';
        return;
      case GameStatus.drawByFortyMoves:
        _successMessage = 'Tablas reglamentarias por 40 jugadas sin progreso (RN-006).';
        return;
      case GameStatus.drawByRepetition:
        _successMessage = 'Tablas reglamentarias por triple repetición de posición (RN-006).';
        return;
      case GameStatus.inProgress:
        return;
    }
  }

  void retryFromBlunder(BlunderRecord record) {
    if (record.boardHistoryIndex < 0 ||
        record.boardHistoryIndex >= _boardHistory.length) {
      return;
    }
    _activeLesson = null;
    _currentBoard = record.stateBeforeError;
    _boardHistory.removeRange(record.boardHistoryIndex, _boardHistory.length);
    if (_moveLog.length >= record.moveNumber) {
      _moveLog.removeRange(record.moveNumber - 1, _moveLog.length);
    }
    _detectedBlunders.removeWhere((b) => b.moveNumber >= record.moveNumber);
    _selectedPosition = record.optimalMove.from;
    _humanErrorMessage = null;
    final size = _currentBoard.ruleset.boardSize;
    _successMessage =
        'Partida rebobinada al turno #${record.moveNumber}. Pista: prueba ${record.optimalMove.toNotation(size)}.';
    notifyListeners();
  }

  void undoLastMove() {
    if (!canUndo) {
      return;
    }
    _currentBoard = _boardHistory.removeLast();
    if (_moveLog.isNotEmpty) {
      _moveLog.removeLast();
    }
    _selectedPosition = null;
    _humanErrorMessage = null;
    _successMessage = 'Jugada deshecha correctamente. Puedes probar otra variante.';
    notifyListeners();
  }

  void resetGame() {
    _isLoading = true;
    notifyListeners();
    if (_activeLesson != null) {
      startAcademyLesson(_activeLesson!);
      _isLoading = false;
      notifyListeners();
      return;
    }
    _currentBoard = BoardState.initial(ruleset: _currentBoard.ruleset);
    _boardHistory.clear();
    _moveLog.clear();
    _detectedBlunders.clear();
    _selectedPosition = null;
    _lastEvaluationCp = 0.0;
    _clearFeedbackMessages();
    _isLoading = false;
    notifyListeners();
  }

  void _setHumanError(String message) {
    _humanErrorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _clearFeedbackMessages() {
    _humanErrorMessage = null;
    _successMessage = null;
  }
}

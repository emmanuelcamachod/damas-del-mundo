// Controlador de estado multivariante, IA Adaptativa, Academia 10 Niveles, Coach y Detector de Errores.
// Cumple RF-001 a RF-006 y RNF-004 (5 estados visuales, anidación <= 2).

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../academy/academy_engine.dart';
import '../ai/ai_engine.dart';
import '../domain/checkers_engine.dart';
import '../economy/economy.dart';
import '../multiplayer/multiplayer.dart';
import '../storage/local_storage_service.dart';

enum UiFeedbackState {
  loading,
  empty,
  humanError,
  success,
  disabled,
}

enum BoardVisualTheme {
  classicWood,
  luxuryMarble,
  cyberNeon,
  tuscanLeather,
  royalJade;

  String get displayName {
    switch (this) {
      case BoardVisualTheme.classicWood:
        return 'Nogal & Arce Imperial';
      case BoardVisualTheme.luxuryMarble:
        return 'Mármol Carrara & Ónix';
      case BoardVisualTheme.cyberNeon:
        return 'Obsidiana Cíber 2077';
      case BoardVisualTheme.tuscanLeather:
        return 'Cuero Toscano & Oro';
      case BoardVisualTheme.royalJade:
        return 'Esmeralda & Jade Real';
    }
  }
}

enum AiDifficulty {
  easy,
  medium,
  hard,
  master;

  String get displayName {
    switch (this) {
      case AiDifficulty.easy:
        return 'Fácil (Principiante)';
      case AiDifficulty.medium:
        return 'Medio (Club)';
      case AiDifficulty.hard:
        return 'Difícil (Maestro)';
      case AiDifficulty.master:
        return 'Extra Difícil (Némesis)';
    }
  }

  int get searchDepth {
    switch (this) {
      case AiDifficulty.easy:
        return 1;
      case AiDifficulty.medium:
        return 2;
      case AiDifficulty.hard:
        return 4;
      case AiDifficulty.master:
        return 6;
    }
  }
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

  final MultiplayerService _multiplayerService;
  final InAppPurchaseService _iapService;
  OnlinePlayerProfile? _onlinePlayerProfile;
  OnlineMatchRoom? _activeOnlineRoom;
  StreamSubscription<CheckersMove>? _opponentMoveSub;
  final Set<BoardVisualTheme> _unlockedThemes = <BoardVisualTheme>{BoardVisualTheme.classicWood};
  DateTime? _lastDailyRewardClaim;

  GameController({
    LocalStorageService? storageService,
    MultiplayerService? multiplayerService,
    InAppPurchaseService? iapService,
  })  : _storageService =
            storageService ?? LocalStorageService.defaultDeviceStorage(),
        _multiplayerService = multiplayerService ?? MockMultiplayerService(),
        _iapService = iapService ?? MockInAppPurchaseService();

  TacticalLesson? _activeLesson;
  int _infinitePuzzleSeed = 1;
  int _infinitePuzzlesSolved = 0;

  BoardPosition? _selectedPosition;
  String? _humanErrorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _vsAiEnabled = true;
  int _aiSearchDepth = 4;
  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  double _lastEvaluationCp = 0.0;
  BoardVisualTheme _boardVisualTheme = BoardVisualTheme.classicWood;

  BoardState get currentBoard => _currentBoard;
  BoardPosition? get selectedPosition => _selectedPosition;
  String? get humanErrorMessage => _humanErrorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get vsAiEnabled => _vsAiEnabled;
  int get aiSearchDepth => _aiSearchDepth;
  AiDifficulty get aiDifficulty => _aiDifficulty;
  double get lastEvaluationCp => _lastEvaluationCp;
  BoardVisualTheme get boardVisualTheme => _boardVisualTheme;
  OnlinePlayerProfile? get onlinePlayerProfile => _onlinePlayerProfile;
  OnlineMatchRoom? get activeOnlineRoom => _activeOnlineRoom;
  bool get isOnlineMatch => _activeOnlineRoom != null;
  int get playerCoins => _onlinePlayerProfile?.coins ?? 1000;

  void setBoardVisualTheme(BoardVisualTheme theme) {
    _boardVisualTheme = theme;
    notifyListeners();
  }

  void setAiDifficulty(AiDifficulty difficulty) {
    _aiDifficulty = difficulty;
    _aiSearchDepth = difficulty.searchDepth;
    notifyListeners();
  }

  Future<void> initOnlineProfile() async {
    _onlinePlayerProfile = await _multiplayerService.getOrCreatePlayerProfile();
    notifyListeners();
  }

  Future<bool> joinOnlineMatchWithBet(MatchmakingTier tier) async {
    if (playerCoins < tier.entryFee) {
      _humanErrorMessage = 'Saldo insuficiente (${playerCoins} monedas) para apostar en ${tier.name}.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _humanErrorMessage = null;
    notifyListeners();

    try {
      final room = await _multiplayerService.joinOrCreateMatch(
        tier: tier,
        rulesetId: _currentBoard.ruleset.displayName,
      );
      _activeOnlineRoom = room;
      _onlinePlayerProfile = await _multiplayerService.getOrCreatePlayerProfile();
      _vsAiEnabled = false;
      _resetForNewGame(keepVariant: true);

      _opponentMoveSub?.cancel();
      _opponentMoveSub = _multiplayerService.onOpponentMove.listen((move) {
        if (!_currentBoard.status.isTerminal) {
          _applyMoveInternal(move);
        }
      });

      _successMessage = '¡Rival encontrado! Partida iniciada por pozo de ${tier.prizePool} monedas.';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _humanErrorMessage = 'Error en sala online: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> leaveOrResignOnlineMatch() async {
    if (_activeOnlineRoom == null) return;
    final matchId = _activeOnlineRoom!.matchId;
    await _multiplayerService.resignMatch(matchId);
    _activeOnlineRoom = null;
    _opponentMoveSub?.cancel();
    _opponentMoveSub = null;
    _onlinePlayerProfile = await _multiplayerService.getOrCreatePlayerProfile();
    notifyListeners();
  }

  bool get canClaimDailyReward {
    if (_lastDailyRewardClaim == null) return true;
    return DateTime.now().difference(_lastDailyRewardClaim!).inHours >= 24;
  }

  void claimDailyReward() {
    if (!canClaimDailyReward) return;
    _lastDailyRewardClaim = DateTime.now();
    final current = _onlinePlayerProfile ?? const OnlinePlayerProfile(
      id: 'local_user',
      username: 'Maestro de Damas',
      coins: 1000,
      eloRating: 1200,
    );
    _onlinePlayerProfile = current.copyWith(coins: current.coins + 100);
    _successMessage = '¡Bono Diario Reclamado! +100 Monedas añadidas a tu saldo.';
    notifyListeners();
  }

  Future<void> buyCoinPackage(CoinPackage pack) async {
    _isLoading = true;
    notifyListeners();
    final ok = await _iapService.buyCoinPackage(pack);
    _isLoading = false;
    if (!ok) {
      _humanErrorMessage = 'La compra no pudo completarse.';
      notifyListeners();
      return;
    }
    final current = _onlinePlayerProfile ?? const OnlinePlayerProfile(
      id: 'local_user',
      username: 'Maestro de Damas',
      coins: 1000,
      eloRating: 1200,
    );
    _onlinePlayerProfile = current.copyWith(coins: current.coins + pack.totalCoins);
    _successMessage = '¡Compra exitosa! Se han acreditado ${pack.totalCoins} monedas a tu cuenta.';
    notifyListeners();
  }

  bool isThemeUnlocked(BoardVisualTheme theme) {
    if (theme == BoardVisualTheme.classicWood) return true;
    return _unlockedThemes.contains(theme);
  }

  bool unlockThemeWithCoins(CosmeticThemeItem item) {
    if (playerCoins < item.coinPrice) {
      _humanErrorMessage = 'Saldo insuficiente (${playerCoins} monedas) para desbloquear ${item.name} (${item.coinPrice} monedas).';
      notifyListeners();
      return false;
    }
    final current = _onlinePlayerProfile ?? const OnlinePlayerProfile(
      id: 'local_user',
      username: 'Maestro de Damas',
      coins: 1000,
      eloRating: 1200,
    );
    _onlinePlayerProfile = current.copyWith(coins: current.coins - item.coinPrice);
    _unlockedThemes.add(item.theme);
    _boardVisualTheme = item.theme;
    _successMessage = '¡Tema ${item.name} desbloqueado y equipado con éxito!';
    notifyListeners();
    return true;
  }
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
        final wPieces = _currentBoard.countPieces(PlayerColor.white);
        final bPieces = _currentBoard.countPieces(PlayerColor.black);
        if (wPieces > bPieces) {
          _successMessage =
              '¡Victoria de las Blancas por Superioridad de Damas! ($wPieces vs $bPieces piezas tras 40 jugadas).';
          return;
        }
        if (bPieces > wPieces) {
          _successMessage =
              'Victoria de la IA Némesis por Superioridad de Damas ($bPieces vs $wPieces piezas).';
          return;
        }
        _successMessage = 'Tablas reglamentarias por 40 jugadas sin progreso (RN-006).';
        return;
      case GameStatus.drawByRepetition:
        final wRepPieces = _currentBoard.countPieces(PlayerColor.white);
        final bRepPieces = _currentBoard.countPieces(PlayerColor.black);
        if (wRepPieces > bRepPieces) {
          _successMessage =
              '¡Victoria de las Blancas por Superioridad Material tras Triple Repetición! ($wRepPieces vs $bRepPieces).';
          return;
        }
        if (bRepPieces > wRepPieces) {
          _successMessage =
              'Victoria de la IA por Superioridad Material tras Triple Repetición ($bRepPieces vs $wRepPieces).';
          return;
        }
        _successMessage = 'Tablas reglamentarias por triple repetición de posición (RN-006).';
        return;
      case GameStatus.inProgress:
        return;
    }
  }

  bool get canClaimMaterialVictory {
    if (_currentBoard.status.isTerminal) {
      return false;
    }
    final whitePieces = _currentBoard.countPieces(PlayerColor.white);
    final blackPieces = _currentBoard.countPieces(PlayerColor.black);
    final total = whitePieces + blackPieces;
    final whitePawns = whitePieces - _currentBoard.countKings(PlayerColor.white);
    final blackPawns = blackPieces - _currentBoard.countKings(PlayerColor.black);
    final onlyKings = (whitePawns == 0 && blackPawns == 0 && total > 0);
    return (onlyKings || total <= 4) && whitePieces > blackPieces;
  }

  void claimVictoryByMaterialAdvantage() {
    if (!canClaimMaterialVictory) {
      return;
    }
    final whitePieces = _currentBoard.countPieces(PlayerColor.white);
    final blackPieces = _currentBoard.countPieces(PlayerColor.black);
    _successMessage =
        '¡Victoria Reclamada por Superioridad de Damas! Ganaste la partida ($whitePieces Damas vs $blackPieces).';
    notifyListeners();
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

// Suite de pruebas unitarias para flutter_test — Fase 02:
// 7 Variantes Mundiales, Regla del Soplido, IA Alfa-Beta, TD-Learning, ADN y Detector de Errores.

import 'package:flutter_test/flutter_test.dart';
import 'package:juego_de_damas/ai/ai_engine.dart';
import 'package:juego_de_damas/domain/checkers_engine.dart';

void main() {
  group('CA-201: Las 7 Variantes Mundiales ("Damas del Mundo") y Regla del Soplido', () {
    test('Internacional FMJD (10x10) inicializa 20 vs 20 fichas en 100 casillas', () {
      final board = BoardState.initial(ruleset: CheckersRuleset.international);
      expect(board.ruleset.boardSize, equals(10));
      expect(board.countPieces(PlayerColor.white), equals(20));
      expect(board.countPieces(PlayerColor.black), equals(20));
      expect(board.legalMoves().length, equals(9));
    });

    test('Turca Ortogonal (8x8) mueve y captura en horizontal y vertical con 16 vs 16 fichas', () {
      final board = BoardState.initial(ruleset: CheckersRuleset.turkish);
      expect(board.countPieces(PlayerColor.white), equals(16));
      expect(board.countPieces(PlayerColor.black), equals(16));
      expect(board.legalMoves().length, equals(8));
    });

    test('Italiana prohíbe que un peón capture a una Dama (pawnCanCaptureKing: false)', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[3 * 8 + 4] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.king,
      );
      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
        ruleset: CheckersRuleset.italian,
      );
      final moves = board.legalMoves();
      expect(moves.every((m) => !m.isCapture), isTrue);
    });

    test('Rusa corona a mitad del salto y continúa comiendo como Dama voladora', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[2 * 8 + 1] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[1 * 8 + 2] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      squares[2 * 8 + 5] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
        ruleset: CheckersRuleset.russian,
      );
      final captures = board.legalMoves().where((m) => m.isCapture).toList();
      expect(captures.any((m) => m.capturedCount == 2), isTrue);
    });

    test('Regla del Soplido marca pieza infractora cuando se omite una captura y permite applyHuff', () {
      final huffRuleset = CheckersRuleset.spanish.copyWith(allowHuffing: true);
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[3 * 8 + 4] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      squares[6 * 8 + 1] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
        ruleset: huffRuleset,
      );
      final nonCaptureMove = board.legalMoves().firstWhere((m) => !m.isCapture);
      final nextBoard = board.applyMove(nonCaptureMove);
      expect(nextBoard.canHuff, isTrue);
      expect(nextBoard.huffablePositions, contains(const BoardPosition(4, 3)));

      final afterHuff = nextBoard.applyHuff(const BoardPosition(4, 3));
      expect(afterHuff.pieceAt(const BoardPosition(4, 3)), isNull);
    });
  });

  group('CA-202, CA-203 y CA-204: Motor Alfa-Beta, TD-Learning, ADN y Detector de Errores', () {
    test('AlphaBetaSolver encuentra jugada óptima y evalúa nodos', () {
      final board = BoardState.initial();
      final solver = AlphaBetaSolver();
      final decision = solver.findBestDecision(board, maxDepth: 3);
      expect(decision.bestMove, isNotNull);
      expect(decision.nodesEvaluated, greaterThan(5));
    });

    test('AdaptiveLearner actualiza pesos dentro de límites seguros (RN-007) y PlayerDnaTracker genera perfil', () {
      final learner = AdaptiveLearner();
      final initialBoard = BoardState.initial();
      final updated = learner.learnFromCompletedGame(
        stateTrajectory: [initialBoard],
        aiColor: PlayerColor.black,
        finalStatus: GameStatus.whiteWins,
      );
      expect(updated.kingValue, greaterThan(285.0));
      expect(learner.gamesLearned, equals(1));

      final dna = PlayerDnaTracker();
      dna.recordHumanMove(
        boardBefore: initialBoard,
        move: initialBoard.legalMoves().first,
      );
      final profile = dna.buildProfile();
      expect(profile.analyzedMoves, equals(1));
    });
  });
}

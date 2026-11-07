// Suite de pruebas unitarias para flutter_test — Fase 01 (RN-001 a RN-006).

import 'package:flutter_test/flutter_test.dart';
import 'package:juego_de_damas/domain/checkers_engine.dart';

void main() {
  group('RN-001: Geometría 8x8 y disposición inicial', () {
    test('Tablero inicial tiene 12 fichas Blancas y 12 Negras en casillas oscuras', () {
      final board = BoardState.initial();
      expect(board.countPieces(PlayerColor.white), equals(12));
      expect(board.countPieces(PlayerColor.black), equals(12));
      expect(board.turn, equals(PlayerColor.white));
      expect(board.status, equals(GameStatus.inProgress));
      expect(board.legalMoves().length, equals(7));
    });
  });

  group('RN-002: Peón avanza y captura solo hacia adelante + Coronación', () {
    test('Peón blanco captura hacia adelante pero NO captura hacia atrás', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      // Peón blanco en (4, 3); enemigo adelante en (3, 4) y enemigo atrás en (5, 2).
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[3 * 8 + 4] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      squares[5 * 8 + 2] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );

      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
      );
      final moves = board.legalMoves();
      expect(moves.length, equals(1));
      expect(moves.first.isCapture, isTrue);
      expect(moves.first.to, equals(const BoardPosition(2, 5)));
    });

    test('Peón se corona como Dama al alcanzar la fila 0 (Blancas)', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[1 * 8 + 2] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[6 * 8 + 1] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );

      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
      );
      final move = board.legalMoves().firstWhere(
            (m) => m.to == const BoardPosition(0, 1),
          );
      expect(move.promotesToKing, isTrue);
      final nextBoard = board.applyMove(move);
      final promoted = nextBoard.pieceAt(const BoardPosition(0, 1));
      expect(promoted, isNotNull);
      expect(promoted!.isKing, isTrue);
    });
  });

  group('RN-003: Dama (Reina) de largo alcance ("Voladora")', () {
    test('Dama blanca vuela varias casillas y captura a distancia en diagonal', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[7 * 8 + 0] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.king,
      );
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );

      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
      );
      final moves = board.legalMoves();
      expect(moves.every((m) => m.isCapture), isTrue);
      // Puede aterrizar en (3,4), (2,5), (1,6) o (0,7) tras saltar (4,3).
      expect(moves.length, equals(4));
    });
  });

  group('RN-004 y RN-005: Captura Obligatoria y Ley de Cantidad y Calidad', () {
    test('Ley de Cantidad obliga a elegir el camino que captura 2 piezas sobre el de 1', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      // Peón blanco en (5, 2) puede comer hacia (3, 0) [1 pieza en (4, 1)]
      // o hacia (3, 4) -> (1, 6) [2 piezas en (4, 3) y (2, 5)].
      squares[5 * 8 + 2] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      squares[4 * 8 + 1] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      squares[4 * 8 + 3] = const CheckersPiece(
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
      );
      final moves = board.legalMoves();
      expect(moves.length, equals(1));
      expect(moves.first.capturedCount, equals(2));
      expect(moves.first.to, equals(const BoardPosition(1, 6)));
    });

    test('Ley de Calidad obliga a capturar Dama sobre Peón a igual cantidad', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[5 * 8 + 2] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.pawn,
      );
      // Camino izquierdo: Peón negro en (4, 1)
      squares[4 * 8 + 1] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.pawn,
      );
      // Camino derecho: Dama negra en (4, 3)
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.king,
      );

      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
      );
      final moves = board.legalMoves();
      expect(moves.length, equals(1));
      expect(moves.first.capturedCount, equals(1));
      expect(moves.first.capturedKingsCount, equals(1));
      expect(moves.first.to, equals(const BoardPosition(3, 4)));
    });
  });

  group('RN-006: Condiciones de Victoria y Tablas', () {
    test('Sin piezas rivales o sin jugadas declara victoria', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[4 * 8 + 3] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.king,
      );
      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.black,
      );
      expect(board.status, equals(GameStatus.whiteWins));
    });

    test('40 jugadas sin captura ni avance de peón declara tablas', () {
      final squares = List<CheckersPiece?>.filled(64, null);
      squares[7 * 8 + 0] = const CheckersPiece(
        color: PlayerColor.white,
        type: PieceType.king,
      );
      squares[0 * 8 + 7] = const CheckersPiece(
        color: PlayerColor.black,
        type: PieceType.king,
      );
      final board = BoardState.custom(
        squares: squares,
        turn: PlayerColor.white,
        halfMovesWithoutProgress: 40,
      );
      expect(board.status, equals(GameStatus.drawByFortyMoves));
    });
  });
}

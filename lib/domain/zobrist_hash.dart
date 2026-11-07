// Generador determinista de hashes Zobrist de 64 bits para tableros 8x8 (64) y 10x10 (100).

import 'checkers_types.dart';

class ZobristHash {
  static final List<int> _table = _generateDeterministicTable();
  static const int _blackTurnKey = 0x5A17C9E3B2D48F01;

  static List<int> _generateDeterministicTable() {
    final values = <int>[];
    var state = 0x243F6A8885A308D3;
    for (var i = 0; i < 100 * 4; i++) {
      state ^= (state << 13) & 0x7FFFFFFFFFFFFFFF;
      state ^= (state >> 7);
      state ^= (state << 17) & 0x7FFFFFFFFFFFFFFF;
      values.add(state);
    }
    assert(values.length == 400, 'Tabla Zobrist debe contener 400 llaves');
    return List<int>.unmodifiable(values);
  }

  static int computeHash(
    List<CheckersPiece?> squares,
    PlayerColor turn,
  ) {
    assert(
      squares.length == 64 || squares.length == 100,
      'El tablero debe tener 64 (8x8) o 100 (10x10) celdas',
    );
    var hash = turn == PlayerColor.black ? _blackTurnKey : 0;
    for (var index = 0; index < squares.length; index++) {
      hash = _mixSquareIntoHash(hash, index, squares[index]);
    }
    return hash;
  }

  static int _mixSquareIntoHash(int currentHash, int index, CheckersPiece? piece) {
    if (piece == null) {
      return currentHash;
    }
    final slotOffset = _pieceSlotOffset(piece);
    return currentHash ^ _table[index * 4 + slotOffset];
  }

  static int _pieceSlotOffset(CheckersPiece piece) {
    if (piece.color == PlayerColor.white) {
      return piece.isKing ? 1 : 0;
    }
    return piece.isKing ? 3 : 2;
  }
}

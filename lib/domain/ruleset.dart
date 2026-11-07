// Configuración paramétrica para las 7 variantes mundiales de Damas y Regla del Soplido.
// Cumple RN-001 a RN-005 con Negative Space Programming (RNF-003).

enum CheckersVariant {
  spanish,
  brazilian,
  english,
  russian,
  italian,
  international,
  turkish,
}

class CheckersRuleset {
  final CheckersVariant variant;
  final String displayName;
  final int boardSize;
  final int initialPiecesPerSide;
  final bool orthogonalMovement;
  final bool flyingKings;
  final bool pawnCapturesBackward;
  final bool enforceQuantityLaw;
  final bool enforceQualityLaw;
  final bool promoteMidJump;
  final bool pawnCanCaptureKing;
  final bool immediateCaptureRemoval;
  final bool allowHuffing;

  const CheckersRuleset({
    required this.variant,
    required this.displayName,
    required this.boardSize,
    required this.initialPiecesPerSide,
    required this.orthogonalMovement,
    required this.flyingKings,
    required this.pawnCapturesBackward,
    required this.enforceQuantityLaw,
    required this.enforceQualityLaw,
    required this.promoteMidJump,
    required this.pawnCanCaptureKing,
    required this.immediateCaptureRemoval,
    this.allowHuffing = false,
  })  : assert(boardSize == 8 || boardSize == 10, 'Tablero debe ser 8x8 o 10x10'),
        assert(initialPiecesPerSide >= 12 && initialPiecesPerSide <= 20, 'Fichas entre 12 y 20');

  int get totalSquares => boardSize * boardSize;

  int get playableSquaresCount =>
      orthogonalMovement ? totalSquares : (totalSquares ~/ 2);

  CheckersRuleset copyWith({bool? allowHuffing}) {
    return CheckersRuleset(
      variant: variant,
      displayName: displayName,
      boardSize: boardSize,
      initialPiecesPerSide: initialPiecesPerSide,
      orthogonalMovement: orthogonalMovement,
      flyingKings: flyingKings,
      pawnCapturesBackward: pawnCapturesBackward,
      enforceQuantityLaw: enforceQuantityLaw,
      enforceQualityLaw: enforceQualityLaw,
      promoteMidJump: promoteMidJump,
      pawnCanCaptureKing: pawnCanCaptureKing,
      immediateCaptureRemoval: immediateCaptureRemoval,
      allowHuffing: allowHuffing != null ? allowHuffing : this.allowHuffing,
    );
  }

  static const CheckersRuleset spanish = CheckersRuleset(
    variant: CheckersVariant.spanish,
    displayName: 'Española (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 12,
    orthogonalMovement: false,
    flyingKings: true,
    pawnCapturesBackward: false,
    enforceQuantityLaw: true,
    enforceQualityLaw: true,
    promoteMidJump: false,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset brazilian = CheckersRuleset(
    variant: CheckersVariant.brazilian,
    displayName: 'Brasileña (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 12,
    orthogonalMovement: false,
    flyingKings: true,
    pawnCapturesBackward: true,
    enforceQuantityLaw: true,
    enforceQualityLaw: false,
    promoteMidJump: false,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset english = CheckersRuleset(
    variant: CheckersVariant.english,
    displayName: 'Inglesa / Americana (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 12,
    orthogonalMovement: false,
    flyingKings: false,
    pawnCapturesBackward: false,
    enforceQuantityLaw: false,
    enforceQualityLaw: false,
    promoteMidJump: false,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset russian = CheckersRuleset(
    variant: CheckersVariant.russian,
    displayName: 'Rusa / Shashki (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 12,
    orthogonalMovement: false,
    flyingKings: true,
    pawnCapturesBackward: true,
    enforceQuantityLaw: false,
    enforceQualityLaw: false,
    promoteMidJump: true,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset italian = CheckersRuleset(
    variant: CheckersVariant.italian,
    displayName: 'Italiana (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 12,
    orthogonalMovement: false,
    flyingKings: false,
    pawnCapturesBackward: false,
    enforceQuantityLaw: true,
    enforceQualityLaw: true,
    promoteMidJump: false,
    pawnCanCaptureKing: false,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset international = CheckersRuleset(
    variant: CheckersVariant.international,
    displayName: 'Internacional FMJD (10x10)',
    boardSize: 10,
    initialPiecesPerSide: 20,
    orthogonalMovement: false,
    flyingKings: true,
    pawnCapturesBackward: true,
    enforceQuantityLaw: true,
    enforceQualityLaw: false,
    promoteMidJump: false,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: false,
  );

  static const CheckersRuleset turkish = CheckersRuleset(
    variant: CheckersVariant.turkish,
    displayName: 'Turca Ortogonal (8x8)',
    boardSize: 8,
    initialPiecesPerSide: 16,
    orthogonalMovement: true,
    flyingKings: true,
    pawnCapturesBackward: false,
    enforceQuantityLaw: true,
    enforceQualityLaw: false,
    promoteMidJump: false,
    pawnCanCaptureKing: true,
    immediateCaptureRemoval: true,
  );

  static const List<CheckersRuleset> allWorldPresets = [
    spanish,
    brazilian,
    english,
    russian,
    italian,
    international,
    turkish,
  ];
}

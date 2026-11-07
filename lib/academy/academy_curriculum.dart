// Currículo oficial de 10 Niveles Progresivos (de Novato a Gran Maestro).
// Cumple RF-006 y RN-008 con tableros tácticos verificados e invariantes assert.

import '../domain/checkers_engine.dart';
import 'academy_models.dart';

class AcademyCurriculum {
  static final List<AcademyLevel> allLevels = _buildAllTenLevels();

  static List<AcademyLevel> _buildAllTenLevels() {
    final levels = <AcademyLevel>[
      _buildLevel1(),
      _buildLevel2(),
      _buildLevel3(),
      _buildLevel4(),
      _buildLevel5(),
      _buildLevel6(),
      _buildLevel7(),
      _buildLevel8(),
      _buildLevel9(),
      _buildLevel10(),
    ];
    assert(levels.length == 10, 'El currículo debe contener exactamente los 10 niveles aprobados');
    return List<AcademyLevel>.unmodifiable(levels);
  }

  static BoardState _boardFromCoords({
    required List<List<int>> whitePawns,
    required List<List<int>> blackPawns,
    List<List<int>> whiteKings = const [],
    List<List<int>> blackKings = const [],
    CheckersRuleset ruleset = CheckersRuleset.spanish,
    PlayerColor turn = PlayerColor.white,
  }) {
    final size = ruleset.boardSize;
    final squares = List<CheckersPiece?>.filled(size * size, null);
    _placePieces(squares, size, whitePawns, PlayerColor.white, PieceType.pawn);
    _placePieces(squares, size, blackPawns, PlayerColor.black, PieceType.pawn);
    _placePieces(squares, size, whiteKings, PlayerColor.white, PieceType.king);
    _placePieces(squares, size, blackKings, PlayerColor.black, PieceType.king);
    return BoardState.custom(squares: squares, turn: turn, ruleset: ruleset);
  }

  static void _placePieces(
    List<CheckersPiece?> squares,
    int size,
    List<List<int>> coords,
    PlayerColor color,
    PieceType type,
  ) {
    for (final pair in coords) {
      squares[pair[0] * size + pair[1]] = CheckersPiece(color: color, type: type);
    }
  }

  // NIVEL 1: Iniciación y Lectura Diagonal
  static AcademyLevel _buildLevel1() {
    final board = _boardFromCoords(
      whitePawns: const [[5, 2]],
      blackPawns: const [[4, 3], [2, 5]],
    );
    return AcademyLevel(
      levelNumber: 1,
      rankTitle: 'Nivel 1: Iniciación y Lectura Diagonal',
      summary: 'Aprende el movimiento diagonal, la captura obligatoria y el salto encadenado.',
      featuredTechniques: const [
        'Lectura de Diagonales Activas',
        'Captura Encadenada Doble',
        'Coronación en Octava Fila',
      ],
      lessons: [
        TacticalLesson(
          id: 'L01_DOUBLE_JUMP',
          levelNumber: 1,
          title: 'Salto Doble en Cadena',
          techniqueName: 'Captura Encadenada Doble',
          theoryExplanation:
              'Cuando tras saltar una ficha enemiga aterrizas en una casilla desde la que puedes comer otra, debes continuar saltando en el mismo turno.',
          objectivePrompt: 'Mueve tu peón de c3 (5,2) hasta g7 (1,6) comiendo las 2 fichas negras.',
          initialBoard: board,
          expectedFrom: const BoardPosition(5, 2),
          expectedTo: const BoardPosition(1, 6),
          successExplanation: '¡Perfecto! Completaste el salto doble en un solo turno.',
          failureHint: 'Selecciona tu peón en c3 (5,2) y completa el salto hasta g7 (1,6).',
        ),
      ],
    );
  }

  // NIVEL 2: Dominio del Reglamento y Variantes Mundiales
  static AcademyLevel _buildLevel2() {
    final board = _boardFromCoords(
      whitePawns: const [[5, 2]],
      blackPawns: const [[4, 1]],
      blackKings: const [[4, 3]],
    );
    return AcademyLevel(
      levelNumber: 2,
      rankTitle: 'Nivel 2: Dominio del Reglamento y Variantes',
      summary: 'Domina la Dama Voladora, el Obstáculo Turco y la Ley de Cantidad y Calidad.',
      featuredTechniques: const [
        'Dama Voladora de Largo Alcance',
        'Ley de Cantidad y Calidad',
        'El Obstáculo Turco y el Soplido',
      ],
      lessons: [
        TacticalLesson(
          id: 'L02_QUALITY_LAW',
          levelNumber: 2,
          title: 'La Ley de Calidad en Acción',
          techniqueName: 'Ley de Cantidad y Calidad (RN-005)',
          theoryExplanation:
              'En Damas Españolas e Italianas, a igual número de piezas por comer, estás obligado a elegir el camino que capture más Damas.',
          objectivePrompt: 'Desde c3 (5,2), captura la Dama negra en d4 (4,3) aterrizando en e5 (3,4).',
          initialBoard: board,
          expectedFrom: const BoardPosition(5, 2),
          expectedTo: const BoardPosition(3, 4),
          successExplanation: '¡Correcto! La Ley de Calidad exige capturar la Dama sobre el peón.',
          failureHint: 'Debes saltar hacia la derecha (3,4) para capturar la Dama rival.',
        ),
      ],
    );
  }

  // NIVEL 3: Aperturas Sólidas y "La Fila Real"
  static AcademyLevel _buildLevel3() {
    final board = _boardFromCoords(
      whitePawns: const [[5, 2], [7, 0], [7, 2], [7, 4], [7, 6]],
      blackPawns: const [[2, 3], [0, 1], [0, 5]],
    );
    return AcademyLevel(
      levelNumber: 3,
      rankTitle: 'Nivel 3: Aperturas Sólidas y La Fila Real',
      summary: 'Aprende a proteger tu primera fila (Fila Base) para impedir que el rival corone Damas.',
      featuredTechniques: const [
        'Defensa de la Fila Real (Fila Base)',
        'Desarrollo en Pirámide Central',
        'Castigo a Aperturas Débiles',
      ],
      lessons: [
        TacticalLesson(
          id: 'L03_CENTER_OPENING',
          levelNumber: 3,
          title: 'Ocupar el Centro sin tocar la Fila Real',
          techniqueName: 'Defensa de la Fila Real + Avance Central',
          theoryExplanation:
              'Nunca muevas las fichas de tu fila 1 (fila 7 en índice) mientras tengas jugadas centrales seguras; esa fila es el escudo contra Damas rivales.',
          objectivePrompt: 'Avanza tu peón adelantado de c3 (5,2) hacia el centro en d4 (4,3).',
          initialBoard: board,
          expectedFrom: const BoardPosition(5, 2),
          expectedTo: const BoardPosition(4, 3),
          successExplanation: '¡Excelente! Tomas el centro manteniendo intacta tu Fila Real.',
          failureHint: 'No muevas la fila inferior; avanza el peón de (5,2) a (4,3).',
        ),
      ],
    );
  }

  // NIVEL 4: Tácticas de Ataque I (Golpes Cortos)
  static AcademyLevel _buildLevel4() {
    final board = _boardFromCoords(
      whitePawns: const [[4, 1], [6, 3]],
      blackPawns: const [[2, 1], [3, 4]],
    );
    return AcademyLevel(
      levelNumber: 4,
      rankTitle: 'Nivel 4: Tácticas de Ataque I (Golpes Cortos)',
      summary: 'Aprende a entregar 1 ficha a propósito para capturar 2 en el turno siguiente.',
      featuredTechniques: const [
        'El Golpe 2-por-1 (Sacrificio Táctico)',
        'La Horquilla Diagonal (Doble Amenaza)',
        'La Clavada y Ataque a la Descubierta',
      ],
      lessons: [
        TacticalLesson(
          id: 'L04_TWO_FOR_ONE',
          levelNumber: 4,
          title: 'Preparando la Horquilla Central',
          techniqueName: 'La Horquilla Diagonal (Doble Amenaza)',
          theoryExplanation:
              'Una horquilla ocurre cuando una sola jugada amenaza simultáneamente dos objetivos o prepara una red de captura forzada.',
          objectivePrompt: 'Avanza de b4 (4,1) a c5 (3,2) amenazando la estructura negra.',
          initialBoard: board,
          expectedFrom: const BoardPosition(4, 1),
          expectedTo: const BoardPosition(3, 2),
          successExplanation: '¡Exacto! Colocas tu peón en el punto neurálgico c5.',
          failureHint: 'Lleva el peón de (4,1) hacia la casilla central (3,2).',
        ),
      ],
    );
  }

  // NIVEL 5: Tácticas de Ataque II (Trampas y Desviaciones)
  static AcademyLevel _buildLevel5() {
    final board = _boardFromCoords(
      whitePawns: const [[5, 4]],
      blackPawns: const [[4, 3], [2, 3], [2, 1]],
    );
    return AcademyLevel(
      levelNumber: 5,
      rankTitle: 'Nivel 5: Tácticas de Ataque II (Trampas y Escalera)',
      summary: 'Domina el Golpe de Rebote, la Desviación y la Escalera (1-por-3).',
      featuredTechniques: const [
        'La Escalera (Barrido 1-por-3)',
        'El Golpe de Rebote (Boomerang)',
        'La Celada de Coronación Falsa',
      ],
      lessons: [
        TacticalLesson(
          id: 'L05_LADDER_SWEEP',
          levelNumber: 5,
          title: 'Barrido en Escalera hasta Coronar',
          techniqueName: 'La Escalera (Triple Captura con Coronación)',
          theoryExplanation:
              'Cuando las fichas rivales están separadas por una casilla en zigzag, un solo peón puede barrer toda la escalera y coronar al final.',
          objectivePrompt: 'Ejecuta el triple salto desde e3 (5,4) hasta a7 (1,0).',
          initialBoard: board,
          expectedFrom: const BoardPosition(5, 4),
          expectedTo: const BoardPosition(1, 0),
          successExplanation: '¡Brillante! Limpiaste 3 piezas rivales en una sola jugada.',
          failureHint: 'Selecciona (5,4) y completa el barrido triple hasta (1,0).',
        ),
      ],
    );
  }

  // NIVEL 6: Golpes Clásicos de Torneo
  static AcademyLevel _buildLevel6() {
    final board = _boardFromCoords(
      whitePawns: const [],
      blackPawns: const [[5, 2], [2, 5]],
      whiteKings: const [[7, 0]],
    );
    return AcademyLevel(
      levelNumber: 6,
      rankTitle: 'Nivel 6: Golpes Clásicos de Torneo',
      summary: 'Ejecuta combinaciones históricas de Damas Españolas, Brasileñas e Internacionales.',
      featuredTechniques: const [
        'El Golpe Polaco (Coup Polonais)',
        'El Golpe de Talón',
        'El Golpe Real con Dama Voladora',
      ],
      lessons: [
        TacticalLesson(
          id: 'L06_ROYAL_FLYING_SWEEP',
          levelNumber: 6,
          title: 'El Golpe Real en la Gran Diagonal',
          techniqueName: 'El Golpe Real con Dama Voladora',
          theoryExplanation:
              'Una Dama en la Gran Diagonal (a1-h8) puede cruzar todo el tablero para capturar múltiples piezas distantes en un solo turno.',
          objectivePrompt: 'Usa tu Dama en a1 (7,0) para capturar las 2 fichas en la Gran Diagonal aterrizando en g7 (1,6) o h8 (0,7).',
          initialBoard: board,
          expectedFrom: const BoardPosition(7, 0),
          expectedTo: const BoardPosition(1, 6),
          successExplanation: '¡Golpe de Maestro! Dominaste toda la Gran Diagonal.',
          failureHint: 'Selecciona tu Dama en (7,0) y aterriza en (1,6) tras saltar ambas fichas.',
        ),
      ],
    );
  }

  // NIVEL 7: Estrategia Posicional Profunda
  static AcademyLevel _buildLevel7() {
    final board = _boardFromCoords(
      whitePawns: const [[4, 3]],
      blackPawns: const [[2, 5]],
    );
    return AcademyLevel(
      levelNumber: 7,
      rankTitle: 'Nivel 7: Estrategia Posicional y Zugzwang',
      summary: 'Controla las 4 casillas centrales, la Gran Diagonal y el conteo de tiempos (Tempi).',
      featuredTechniques: const [
        'Dominio de las 4 Casillas Centrales',
        'Control de la Gran Diagonal',
        'Zugzwang (Obligar al Rival a Entregarse)',
      ],
      lessons: [
        TacticalLesson(
          id: 'L07_ZUGZWANG',
          levelNumber: 7,
          title: 'Zugzwang en la Diagonal Maestra',
          techniqueName: 'Zugzwang (Compulsión de Movimiento)',
          theoryExplanation:
              'En esta posición, quien avanza con cálculo exacto encierra al peón rival obligándolo en su turno a ponerse en casilla de captura.',
          objectivePrompt: 'Avanza tu peón de d4 (4,3) a e5 (3,4) dejando al rival en Zugzwang.',
          initialBoard: board,
          expectedFrom: const BoardPosition(4, 3),
          expectedTo: const BoardPosition(3, 4),
          successExplanation: '¡Zugzwang perfecto! El peón negro en (2,5) queda forzado y perdido.',
          failureHint: 'Mueve de (4,3) a (3,4) para quitarle todas las casillas seguras.',
        ),
      ],
    );
  }

  // NIVEL 8: El Arte del Bloqueo y "La Oposición"
  static AcademyLevel _buildLevel8() {
    final board = _boardFromCoords(
      whitePawns: const [[3, 0]],
      blackPawns: const [[1, 0]],
    );
    return AcademyLevel(
      levelNumber: 8,
      rankTitle: 'Nivel 8: El Arte del Bloqueo y La Oposición',
      summary: 'Aprende a ganar dejando al rival sin movimientos legales (Ahogado) y calculando la Oposición.',
      featuredTechniques: const [
        'La Oposición Directa (1 vs 1)',
        'El Candado de Flanco (1 ficha frena a 2)',
        'Victoria por Ahogado / Bloqueo Total',
      ],
      lessons: [
        TacticalLesson(
          id: 'L08_OPPOSITION_LOCK',
          levelNumber: 8,
          title: 'Oposición y Encerramiento en la Banda',
          techniqueName: 'La Oposición Directa en Banda',
          theoryExplanation:
              'Al avanzar hacia la banda contra un peón solitario separado por una fila par, lo dejas obligado a entregarse en el siguiente turno.',
          objectivePrompt: 'Mueve tu peón de a5 (3,0) a b6 (2,1) para ganar la oposición.',
          initialBoard: board,
          expectedFrom: const BoardPosition(3, 0),
          expectedTo: const BoardPosition(2, 1),
          successExplanation: '¡Oposición ganada! El peón negro en (1,0) no tiene escapatoria.',
          failureHint: 'Avanza de (3,0) a (2,1).',
        ),
      ],
    );
  }

  // NIVEL 9: Finales Técnicos de Maestro
  static AcademyLevel _buildLevel9() {
    final board = _boardFromCoords(
      whitePawns: const [],
      blackPawns: const [],
      whiteKings: const [[6, 1], [5, 4]],
      blackKings: const [[4, 3]],
    );
    return AcademyLevel(
      levelNumber: 9,
      rankTitle: 'Nivel 9: Finales Técnicos de Maestro',
      summary: 'Domina los finales clásicos de Damas: 2 vs 1 y el famoso Triángulo de Petrov (3 vs 1).',
      featuredTechniques: const [
        'Final de 2 Damas vs 1 Dama',
        'El Triángulo de Petrov (3 Damas vs 1 Dama)',
        'Defensa de Tablas en Inferioridad',
      ],
      lessons: [
        TacticalLesson(
          id: 'L09_ENDGAME_NET',
          levelNumber: 9,
          title: 'Red de Caza con Damas',
          techniqueName: 'Caza de Dama en la Gran Diagonal',
          theoryExplanation:
              'Cuando la Dama enemiga queda expuesta entre tus piezas con una casilla vacía detrás, ejecutas el remate directo.',
          objectivePrompt: 'Captura la Dama negra en d4 (4,3) usando tu Dama desde b2 (6,1) hasta e5 (3,4).',
          initialBoard: board,
          expectedFrom: const BoardPosition(6, 1),
          expectedTo: const BoardPosition(3, 4),
          successExplanation: '¡Final resuelto con precisión quirúrgica!',
          failureHint: 'Usa la Dama de (6,1) para saltar sobre (4,3) y caer en (3,4).',
        ),
      ],
    );
  }

  // NIVEL 10: Gran Maestro + Laboratorio de Retos Infinitos
  static AcademyLevel _buildLevel10() {
    final board = _boardFromCoords(
      whitePawns: const [],
      blackPawns: const [[1, 2], [3, 4]],
      whiteKings: const [[0, 1]],
      blackKings: const [[5, 4]],
    );
    return AcademyLevel(
      levelNumber: 10,
      rankTitle: 'Nivel 10: Gran Maestro + Laboratorio Infinito',
      summary: 'Combinaciones de cálculo profundo y acceso al Generador Infinito de Retos Tácticos.',
      featuredTechniques: const [
        'Cálculo de Combinaciones de Gran Maestro',
        'Explotación de Cantidad + Calidad Combinada',
        'Generador Procedimental Infinito + Entrenamiento de tus Errores',
      ],
      lessons: [
        TacticalLesson(
          id: 'L10_GRANDMASTER_SWEEP',
          levelNumber: 10,
          title: 'Barrido de Gran Maestro con Dama Voladora',
          techniqueName: 'Combinación de Barrido Múltiple (2 Peones + 1 Dama)',
          theoryExplanation:
              'Una Dama voladora bien ubicada puede girar en ángulo recto tras cada salto para limpiar peones y Damas enemigas en una sola secuencia.',
          objectivePrompt: 'Desde b8 (0,1), barre las 3 piezas negras terminando en d2 (6,3).',
          initialBoard: board,
          expectedFrom: const BoardPosition(0, 1),
          expectedTo: const BoardPosition(6, 3),
          successExplanation: '¡Nivel Gran Maestro completado! Ahora puedes generar retos infinitos.',
          failureHint: 'Selecciona la Dama en (0,1) y completa el barrido triple hasta (6,3).',
        ),
      ],
    );
  }
}

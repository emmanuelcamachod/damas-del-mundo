// Modelos inmutables para la Academia de 10 Niveles, Retos Infinitos y Entrenador Táctico.
// Cumple RF-006, RN-008 y RNF-003 (Negative Space Programming con assert explícitos).

import '../domain/checkers_engine.dart';

class TacticalLesson {
  final String id;
  final int levelNumber;
  final String title;
  final String techniqueName;
  final String theoryExplanation;
  final String objectivePrompt;
  final BoardState initialBoard;
  final BoardPosition expectedFrom;
  final BoardPosition expectedTo;
  final String successExplanation;
  final String failureHint;

  TacticalLesson({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.techniqueName,
    required this.theoryExplanation,
    required this.objectivePrompt,
    required this.initialBoard,
    required this.expectedFrom,
    required this.expectedTo,
    required this.successExplanation,
    required this.failureHint,
  })  : assert(id != '', 'El ID de la lección no puede ser vacío'),
        assert(levelNumber >= 1 && levelNumber <= 10, 'Nivel debe estar entre 1 y 10'),
        assert(title != '', 'El título no puede ser vacío'),
        assert(techniqueName != '', 'El nombre de la técnica no puede ser vacío'),
        assert(!initialBoard.status.isTerminal, 'El tablero de la lección debe ser jugable') {
    _assertExpectedMoveIsLegal();
  }

  void _assertExpectedMoveIsLegal() {
    final legalMoves = initialBoard.legalMoves();
    var found = false;
    for (final move in legalMoves) {
      if (move.from == expectedFrom && move.to == expectedTo) {
        found = true;
      }
    }
    assert(
      found,
      'La jugada esperada ($expectedFrom -> $expectedTo) debe ser legal en la lección $id',
    );
  }

  bool isMatchingSolution(CheckersMove move) {
    return move.from == expectedFrom && move.to == expectedTo;
  }
}

class AcademyLevel {
  final int levelNumber;
  final String rankTitle;
  final String summary;
  final List<String> featuredTechniques;
  final List<TacticalLesson> lessons;

  AcademyLevel({
    required this.levelNumber,
    required this.rankTitle,
    required this.summary,
    required List<String> featuredTechniques,
    required List<TacticalLesson> lessons,
  })  : featuredTechniques = List<String>.unmodifiable(featuredTechniques),
        lessons = List<TacticalLesson>.unmodifiable(lessons) {
    assert(levelNumber >= 1 && levelNumber <= 10, 'Nivel fuera de rango 1..10');
    assert(rankTitle != '', 'El título de rango no puede ser vacío');
    assert(this.featuredTechniques.isNotEmpty, 'Debe listar técnicas destacadas');
    assert(this.lessons.isNotEmpty, 'Cada nivel debe tener al menos 1 lección interactiva');
  }
}

class CoachAdvice {
  final CheckersMove recommendedMove;
  final String techniqueName;
  final String tacticalExplanation;
  final double evaluationScoreCp;

  const CoachAdvice({
    required this.recommendedMove,
    required this.techniqueName,
    required this.tacticalExplanation,
    required this.evaluationScoreCp,
  })  : assert(techniqueName != '', 'Nombre de técnica requerido'),
        assert(tacticalExplanation != '', 'Explicación táctica requerida');
}

class AcademyProgressMap {
  final Map<String, int> _starsByLessonId = <String, int>{};

  Map<String, int> get starsByLessonId =>
      Map<String, int>.unmodifiable(_starsByLessonId);

  int starsForLesson(String lessonId) {
    assert(lessonId != '', 'ID de lección no puede ser vacío');
    final recorded = _starsByLessonId[lessonId];
    if (recorded != null) {
      return recorded;
    }
    return 0;
  }

  void recordStars(String lessonId, int stars) {
    assert(lessonId != '', 'ID de lección no puede ser vacío');
    assert(stars >= 0 && stars <= 3, 'Estrellas deben estar entre 0 y 3');
    final existing = starsForLesson(lessonId);
    if (stars > existing) {
      _starsByLessonId[lessonId] = stars;
    }
  }

  Map<String, int> toJson() {
    return Map<String, int>.from(_starsByLessonId);
  }

  void restoreFromJson(Map<String, dynamic> json) {
    _starsByLessonId.clear();
    for (final entry in json.entries) {
      _insertValidatedStar(entry.key, entry.value);
    }
  }

  void _insertValidatedStar(String lessonId, Object? rawStars) {
    if (lessonId != '' && rawStars is int) {
      final clamped = rawStars.clamp(0, 3);
      _starsByLessonId[lessonId] = clamped;
    }
  }
}


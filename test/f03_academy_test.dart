// Suite de pruebas unitarias para flutter_test — Fase 03:
// Academia de 10 Niveles Progresivos, Generador Infinito de Retos y Entrenador Táctico (Coach).

import 'package:flutter_test/flutter_test.dart';
import 'package:juego_de_damas/academy/academy_engine.dart';
import 'package:juego_de_damas/domain/checkers_engine.dart';

void main() {
  group('CA-301: Currículo Oficial de 10 Niveles Progresivos', () {
    test('AcademyCurriculum contiene exactamente los 10 niveles con tableros y soluciones legales', () {
      final levels = AcademyCurriculum.allLevels;
      expect(levels.length, equals(10));
      for (var i = 0; i < 10; i++) {
        expect(levels[i].levelNumber, equals(i + 1));
        expect(levels[i].lessons, isNotEmpty);
        final lesson = levels[i].lessons.first;
        final legal = lesson.initialBoard.legalMoves();
        expect(
          legal.any((m) => lesson.isMatchingSolution(m)),
          isTrue,
          reason: 'La lección ${lesson.id} debe tener solución legal',
        );
      }
    });
  });

  group('CA-302: Generador Infinito de Retos Tácticos Procedimentales', () {
    test('InfinitePuzzleGenerator crea retos válidos para distintas semillas y variantes', () {
      final p1 = InfinitePuzzleGenerator.generateProceduralPuzzle(
        seed: 1,
        ruleset: CheckersRuleset.spanish,
      );
      final p2 = InfinitePuzzleGenerator.generateProceduralPuzzle(
        seed: 2,
        ruleset: CheckersRuleset.brazilian,
      );
      expect(p1.id, equals('INF_PUZZLE_1'));
      expect(p2.id, equals('INF_PUZZLE_2'));
      expect(
        p1.initialBoard.legalMoves().any((m) => p1.isMatchingSolution(m)),
        isTrue,
      );
    });
  });

  group('CA-303: Entrenador Táctico en Tiempo Real (TacticalCoach)', () {
    test('TacticalCoach analiza posición y devuelve jugada recomendada con técnica explicada', () {
      final board = BoardState.initial();
      final advice = TacticalCoach.analyzePosition(board);
      expect(advice.techniqueName, isNotEmpty);
      expect(advice.tacticalExplanation, contains('Coach Táctico'));
      expect(board.legalMoves(), contains(advice.recommendedMove));
    });
  });
}

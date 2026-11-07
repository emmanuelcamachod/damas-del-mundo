// Suite de pruebas unitarias para la Fase 04: Persistencia Atómica en Disco y Cierre Android.
// Cumple CA-401..CA-404 y RNF-003 (anidamiento <= 2).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:juego_de_damas/academy/academy_engine.dart';
import 'package:juego_de_damas/ai/ai_engine.dart';
import 'package:juego_de_damas/domain/checkers_engine.dart';
import 'package:juego_de_damas/storage/local_storage_service.dart';
import 'package:juego_de_damas/ui/game_controller.dart';

void main() {
  group('Fase 04 — Persistencia Local Atómica y Perfil ADN/Academia', () {
    test('TEST 1 (CA-401): Round-trip atómico guarda y restaura TD-Learning, ADN y Academia', () {
      final tempDir = Directory.systemTemp.createTempSync('damas_f04_t1_');
      final storage = LocalStorageService(
        storageFilePath: '${tempDir.path}/profile.json',
      );

      final learner = AdaptiveLearner();
      final trajectory = <BoardState>[BoardState.initial()];
      learner.learnFromCompletedGame(
        stateTrajectory: trajectory,
        aiColor: PlayerColor.black,
        finalStatus: GameStatus.whiteWins,
      );

      final dna = PlayerDnaTracker();
      final board = BoardState.initial();
      final firstMove = board.legalMoves().first;
      dna.recordHumanMove(boardBefore: board, move: firstMove);

      final progress = AcademyProgressMap();
      progress.recordStars('L01_DIAGONAL_VIVA', 3);

      final savedOk = storage.saveAll(
        learner: learner,
        dnaTracker: dna,
        academyProgress: progress,
        completedLessons: <String>{'L01_DIAGONAL_VIVA'},
        infinitePuzzlesSolved: 4,
      );
      expect(savedOk, isTrue);

      final restoredLearner = AdaptiveLearner();
      final restoredDna = PlayerDnaTracker();
      final restoredProgress = AcademyProgressMap();
      final restoredLessons = <String>{};

      storage.restoreInto(
        learner: restoredLearner,
        dnaTracker: restoredDna,
        academyProgress: restoredProgress,
        completedLessonsOutput: restoredLessons,
      );

      expect(restoredLearner.gamesLearned, equals(1));
      expect(restoredLearner.humanWins, equals(1));
      expect(restoredDna.buildProfile().analyzedMoves, equals(1));
      expect(restoredProgress.starsForLesson('L01_DIAGONAL_VIVA'), equals(3));
      expect(restoredLessons.contains('L01_DIAGONAL_VIVA'), isTrue);
      tempDir.deleteSync(recursive: true);
    });

    test('TEST 2 (CA-401): Recuperación tolerante ante archivo inexistente o JSON corrupto', () {
      final tempDir = Directory.systemTemp.createTempSync('damas_f04_t2_');
      final filePath = '${tempDir.path}/corrupt.json';
      final storage = LocalStorageService(storageFilePath: filePath);

      final missingSnapshot = storage.loadSnapshot();
      expect(missingSnapshot.infinitePuzzlesSolved, equals(0));
      expect(missingSnapshot.completedLessonIds, isEmpty);

      File(filePath).writeAsStringSync('{corrupted_json: [1, 2, ');
      final corruptSnapshot = storage.loadSnapshot();
      expect(corruptSnapshot.adaptiveLearnerData, isEmpty);
      expect(corruptSnapshot.playerDnaData, isEmpty);
      tempDir.deleteSync(recursive: true);
    });

    test('TEST 3 (RN-007 / CA-401): HeuristicWeights.fromMap acota valores extremos por seguridad', () {
      final extremeMap = <String, dynamic>{
        'pawnValue': 9999.0,
        'kingValue': 10.0,
        'centerControlBonus': 500.0,
        'backRowGuardBonus': -20.0,
        'advancementBonus': 99.0,
        'vulnerabilityPenalty': 1.0,
      };
      final clamped = HeuristicWeights.fromMap(extremeMap);
      expect(clamped.pawnValue, equals(140.0));
      expect(clamped.kingValue, equals(200.0));
      expect(clamped.centerControlBonus, equals(40.0));
      expect(clamped.backRowGuardBonus, equals(4.0));
      expect(clamped.advancementBonus, equals(20.0));
      expect(clamped.vulnerabilityPenalty, equals(5.0));
    });

    test('TEST 4 (CA-401): AcademyProgressMap conserva siempre la máxima calificación de estrellas', () {
      final progress = AcademyProgressMap();
      progress.recordStars('L03_GOLPE_2X1', 3);
      progress.recordStars('L03_GOLPE_2X1', 1);
      expect(progress.starsForLesson('L03_GOLPE_2X1'), equals(3));
    });

    test('TEST 5 (CA-401): GameController autoguarda al superar una lección y restaura el perfil', () {
      final tempDir = Directory.systemTemp.createTempSync('damas_f04_t5_');
      final storage = LocalStorageService(
        storageFilePath: '${tempDir.path}/controller_profile.json',
      );
      final controllerA = GameController(storageService: storage);
      final lesson = AcademyCurriculum.allLevels.first.lessons.first;

      controllerA.startAcademyLesson(lesson);
      controllerA.onSquareTapped(lesson.expectedFrom);
      controllerA.onSquareTapped(lesson.expectedTo);
      expect(controllerA.completedLessonIds.contains(lesson.id), isTrue);

      final controllerB = GameController(storageService: storage);
      controllerB.loadProfileFromDisk();
      expect(controllerB.completedLessonIds.contains(lesson.id), isTrue);
      expect(controllerB.academyProgress.starsForLesson(lesson.id), equals(3));
      tempDir.deleteSync(recursive: true);
    });
  });
}

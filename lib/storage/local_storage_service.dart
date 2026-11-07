// Servicio de Persistencia Local Atómica en Disco (Fase 04 — GEM V4.0).
// Cumple RF-003, RF-006, RNF-002 (100% offline-first) y RNF-003 (Negative Space Programming, 0 '?.'/'??').

import 'dart:convert';
import 'dart:io';

import '../academy/academy_engine.dart';
import '../ai/ai_engine.dart';

class LocalProfileSnapshot {
  final Map<String, dynamic> adaptiveLearnerData;
  final Map<String, dynamic> playerDnaData;
  final Map<String, dynamic> academyStarsData;
  final List<String> completedLessonIds;
  final int infinitePuzzlesSolved;

  const LocalProfileSnapshot({
    required this.adaptiveLearnerData,
    required this.playerDnaData,
    required this.academyStarsData,
    required this.completedLessonIds,
    required this.infinitePuzzlesSolved,
  }) : assert(infinitePuzzlesSolved >= 0, 'Retos resueltos no puede ser negativo');

  factory LocalProfileSnapshot.empty() {
    return const LocalProfileSnapshot(
      adaptiveLearnerData: <String, dynamic>{},
      playerDnaData: <String, dynamic>{},
      academyStarsData: <String, dynamic>{},
      completedLessonIds: <String>[],
      infinitePuzzlesSolved: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': 1,
      'adaptiveLearner': adaptiveLearnerData,
      'playerDna': playerDnaData,
      'academyStars': academyStarsData,
      'completedLessonIds': completedLessonIds,
      'infinitePuzzlesSolved': infinitePuzzlesSolved,
    };
  }
}

class LocalStorageService {
  static const String defaultFileName = 'nemesis_damas_profile_v1.json';

  final String storageFilePath;

  const LocalStorageService({
    required this.storageFilePath,
  }) : assert(storageFilePath != '', 'La ruta de almacenamiento no puede ser vacía');

  factory LocalStorageService.defaultDeviceStorage() {
    final baseDir = Directory.systemTemp.path;
    return LocalStorageService(
      storageFilePath: '$baseDir/$defaultFileName',
    );
  }

  // Guarda de forma atómica escribiendo primero en un archivo .tmp y renombrándolo.
  bool saveAll({
    required AdaptiveLearner learner,
    required PlayerDnaTracker dnaTracker,
    required AcademyProgressMap academyProgress,
    required Set<String> completedLessons,
    required int infinitePuzzlesSolved,
  }) {
    assert(infinitePuzzlesSolved >= 0, 'Contador de retos no puede ser negativo');
    final snapshot = LocalProfileSnapshot(
      adaptiveLearnerData: learner.toJson(),
      playerDnaData: dnaTracker.toJson(),
      academyStarsData: academyProgress.toJson(),
      completedLessonIds: List<String>.from(completedLessons),
      infinitePuzzlesSolved: infinitePuzzlesSolved,
    );
    return writeSnapshotAtomically(snapshot);
  }

  bool writeSnapshotAtomically(LocalProfileSnapshot snapshot) {
    final targetFile = File(storageFilePath);
    final tempFile = File('$storageFilePath.tmp');
    try {
      final parentDir = targetFile.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      final encoded = const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
      tempFile.writeAsStringSync(encoded, flush: true);
      tempFile.renameSync(targetFile.path);
      assert(targetFile.existsSync(), 'El archivo final debe existir tras renameSync');
      return true;
    } on Object {
      return false;
    }
  }

  // Carga el estado desde disco; si no existe o está corrupto devuelve un snapshot limpio.
  LocalProfileSnapshot loadSnapshot() {
    final targetFile = File(storageFilePath);
    if (!targetFile.existsSync()) {
      return LocalProfileSnapshot.empty();
    }
    try {
      final rawText = targetFile.readAsStringSync();
      return _decodeValidatedSnapshot(rawText);
    } on Object {
      return LocalProfileSnapshot.empty();
    }
  }

  void restoreInto({
    required AdaptiveLearner learner,
    required PlayerDnaTracker dnaTracker,
    required AcademyProgressMap academyProgress,
    required Set<String> completedLessonsOutput,
  }) {
    final snapshot = loadSnapshot();
    if (snapshot.adaptiveLearnerData.isNotEmpty) {
      learner.restoreFromJson(snapshot.adaptiveLearnerData);
    }
    if (snapshot.playerDnaData.isNotEmpty) {
      dnaTracker.restoreFromJson(snapshot.playerDnaData);
    }
    if (snapshot.academyStarsData.isNotEmpty) {
      academyProgress.restoreFromJson(snapshot.academyStarsData);
    }
    completedLessonsOutput
      ..clear()
      ..addAll(snapshot.completedLessonIds);
  }

  static LocalProfileSnapshot _decodeValidatedSnapshot(String rawText) {
    if (rawText.trim().isEmpty) {
      return LocalProfileSnapshot.empty();
    }
    final decoded = jsonDecode(rawText);
    if (decoded is! Map<String, dynamic>) {
      return LocalProfileSnapshot.empty();
    }
    return LocalProfileSnapshot(
      adaptiveLearnerData: _extractMap(decoded, 'adaptiveLearner'),
      playerDnaData: _extractMap(decoded, 'playerDna'),
      academyStarsData: _extractMap(decoded, 'academyStars'),
      completedLessonIds: _extractStringList(decoded, 'completedLessonIds'),
      infinitePuzzlesSolved: _extractPositiveInt(decoded, 'infinitePuzzlesSolved'),
    );
  }

  static Map<String, dynamic> _extractMap(
    Map<String, dynamic> root,
    String key,
  ) {
    final section = root[key];
    if (section is Map<String, dynamic>) {
      return section;
    }
    return <String, dynamic>{};
  }

  static List<String> _extractStringList(
    Map<String, dynamic> root,
    String key,
  ) {
    final rawList = root[key];
    if (rawList is! List) {
      return <String>[];
    }
    final result = <String>[];
    for (final item in rawList) {
      if (item is String && item != '') {
        result.add(item);
      }
    }
    return result;
  }

  static int _extractPositiveInt(Map<String, dynamic> root, String key) {
    final raw = root[key];
    if (raw is int && raw >= 0) {
      return raw;
    }
    return 0;
  }
}

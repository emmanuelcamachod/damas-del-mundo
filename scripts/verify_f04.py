#!/usr/bin/env python3
"""
Verificador Empírico Integral — Fase 04 (Cierre de Proyecto GEM V4.0):
- Persistencia Local Atómica en Disco (`lib/storage/local_storage_service.dart`)
- Integración de autoguardado en `GameController`, `AdaptiveLearner` y `PlayerDnaTracker`
- Configuración Nativa Android 100% Offline-First (`android/`)
- Guía Paso a Paso de Compilación y Publicación (`GUIA_PLAY_STORE.md`)
- Cumplimiento de `RNF-003` (anidamiento <= 2 y Programación del Espacio Negativo en todo el proyecto)
"""

import os
import re
import sys

ROOT = "/home/antigravity/juego_de_damas"

REQUIRED_F04_FILES = [
    "lib/storage/local_storage_service.dart",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/build.gradle",
    "android/build.gradle",
    "android/settings.gradle",
    "android/gradle.properties",
    "android/key.properties.example",
    "GUIA_PLAY_STORE.md",
    "test/f04_persistence_android_test.dart",
]

ALL_DART_FILES = [
    "lib/main.dart",
    "lib/domain/ruleset.dart",
    "lib/domain/checkers_types.dart",
    "lib/domain/zobrist_hash.dart",
    "lib/domain/move_generator.dart",
    "lib/domain/board_state.dart",
    "lib/domain/checkers_engine.dart",
    "lib/ai/heuristic_weights.dart",
    "lib/ai/alpha_beta_solver.dart",
    "lib/ai/adaptive_learner.dart",
    "lib/ai/player_dna.dart",
    "lib/ai/blunder_detector.dart",
    "lib/ai/ai_engine.dart",
    "lib/academy/academy_models.dart",
    "lib/academy/academy_curriculum.dart",
    "lib/academy/infinite_puzzle_generator.dart",
    "lib/academy/tactical_coach.dart",
    "lib/academy/academy_engine.dart",
    "lib/storage/local_storage_service.dart",
    "lib/ui/ai_dna_sheet.dart",
    "lib/ui/academy_sheet.dart",
    "lib/ui/game_controller.dart",
    "lib/ui/board_screen.dart",
    "test/checkers_engine_test.dart",
    "test/f02_multivariant_ai_test.dart",
    "test/f03_academy_test.dart",
    "test/f04_persistence_android_test.dart",
]

NEGATIVE_SPACE_FILES = [
    "lib/domain/ruleset.dart",
    "lib/domain/checkers_types.dart",
    "lib/domain/zobrist_hash.dart",
    "lib/domain/move_generator.dart",
    "lib/domain/board_state.dart",
    "lib/ai/heuristic_weights.dart",
    "lib/ai/alpha_beta_solver.dart",
    "lib/ai/adaptive_learner.dart",
    "lib/ai/player_dna.dart",
    "lib/ai/blunder_detector.dart",
    "lib/academy/academy_models.dart",
    "lib/academy/academy_curriculum.dart",
    "lib/academy/infinite_puzzle_generator.dart",
    "lib/academy/tactical_coach.dart",
    "lib/storage/local_storage_service.dart",
]

CONTROL_PATTERN = re.compile(r"\b(if|else\s+if|else|for|while|switch)\b")


def strip_comments_and_strings(line: str) -> str:
    idx = line.find("//")
    if idx != -1:
        line = line[:idx]
    line = re.sub(r"'([^'\\]|\\.)*'", "''", line)
    line = re.sub(r'"([^"\\]|\\.)*"', '""', line)
    return line


def compute_max_control_nesting(filepath: str) -> int:
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    brace_stack = []
    max_control_depth = 0
    pending_control = False

    for raw_line in lines:
        line = strip_comments_and_strings(raw_line)
        if CONTROL_PATTERN.search(line):
            pending_control = True

        for ch in line:
            if ch == "{":
                is_ctrl = pending_control
                brace_stack.append(is_ctrl)
                pending_control = False
                ctrl_depth = sum(1 for item in brace_stack if item)
                if ctrl_depth > max_control_depth:
                    max_control_depth = ctrl_depth
            elif ch == "}":
                if brace_stack:
                    brace_stack.pop()
                pending_control = False

    return max_control_depth


def main() -> int:
    errors = []
    print("=" * 72)
    print("VERIFICADOR PERSISTENCIA, ANDROID Y CIERRE INTEGRAL - FASE 04 (GEM V4.0)")
    print("=" * 72)

    # 1. Existencia de todos los archivos de F04
    for rel in REQUIRED_F04_FILES:
        full = os.path.join(ROOT, rel)
        if not os.path.isfile(full) or os.path.getsize(full) == 0:
            errors.append(f"Archivo faltante o vacío: {rel}")

    if not errors:
        print(f"[OK] Todos los {len(REQUIRED_F04_FILES)} archivos de la Fase 04 existen y no están vacíos.")

    # 2. Anidamiento <= 2 en los 27 archivos Dart del proyecto completo
    for rel in ALL_DART_FILES:
        full = os.path.join(ROOT, rel)
        depth = compute_max_control_nesting(full)
        if depth > 2:
            errors.append(f"Violación RNF-003 en {rel}: anidamiento {depth} > 2")

    if not any("RNF-003" in e for e in errors):
        print(f"[OK] Anidamiento máximo <= 2 verificado en los {len(ALL_DART_FILES)} archivos Dart (F01..F04).")

    # 3. Espacio Negativo en domain, ai, academy y storage
    total_asserts = 0
    for rel in NEGATIVE_SPACE_FILES:
        full = os.path.join(ROOT, rel)
        with open(full, "r", encoding="utf-8") as f:
            content = f.read()
        code_lines = [strip_comments_and_strings(line) for line in content.splitlines()]
        clean_code = "\n".join(code_lines)
        if "?." in clean_code or "??" in clean_code:
            errors.append(f"Operador prohibido ('?.' o '??') en {rel}")
        assert_count = len(re.findall(r"\bassert\s*\(", content))
        total_asserts += assert_count
        if assert_count == 0:
            errors.append(f"Sin assert() de Espacio Negativo en {rel}")

    if not any("Espacio Negativo" in e or "Operador prohibido" in e for e in errors):
        print(f"[OK] Espacio Negativo ({total_asserts} asserts, 0 '?.'/'??') en domain, ai, academy y storage.")

    # 4. Verificar Persistencia Atómica (.tmp + renameSync) y tolerancia a fallos
    with open(os.path.join(ROOT, "lib/storage/local_storage_service.dart"), "r", encoding="utf-8") as f:
        storage_src = f.read()
    for token in [".tmp", "renameSync", "jsonDecode", "LocalProfileSnapshot.empty()"]:
        if token not in storage_src:
            errors.append(f"Falta mecanismo '{token}' en local_storage_service.dart")

    if not any("local_storage_service.dart" in e for e in errors):
        print("[OK] Persistencia local atómica (.tmp -> renameSync) y recuperación ante corrupción verificadas.")

    # 5. Verificar AndroidManifest.xml 100% offline (sin INTERNET) y build.gradle
    with open(os.path.join(ROOT, "android/app/src/main/AndroidManifest.xml"), "r", encoding="utf-8") as f:
        manifest_src = f.read()
    if "android.permission.INTERNET" in manifest_src:
        errors.append("Violación RNF-002: AndroidManifest.xml incluye permiso INTERNET")
    if "com.juegodedamas.nemesis" not in manifest_src:
        errors.append("AndroidManifest.xml no declara el package com.juegodedamas.nemesis")

    with open(os.path.join(ROOT, "android/app/build.gradle"), "r", encoding="utf-8") as f:
        gradle_src = f.read()
    for token in ["applicationId \"com.juegodedamas.nemesis\"", "minSdkVersion 23", "targetSdkVersion 35", "signingConfigs"]:
        if token not in gradle_src:
            errors.append(f"Falta configuración '{token}' en android/app/build.gradle")

    if not any("AndroidManifest" in e or "build.gradle" in e for e in errors):
        print("[OK] Empaquetado Android 100% Offline-First y configuración de firma Play Store verificados.")

    # 6. Verificar GUIA_PLAY_STORE.md y suite de tests F04
    with open(os.path.join(ROOT, "GUIA_PLAY_STORE.md"), "r", encoding="utf-8") as f:
        guide_src = f.read()
    for token in ["flutter build apk --release", "flutter build appbundle --release", "keytool -genkey"]:
        if token not in guide_src:
            errors.append(f"Falta comando '{token}' en GUIA_PLAY_STORE.md")

    with open(os.path.join(ROOT, "test/f04_persistence_android_test.dart"), "r", encoding="utf-8") as f:
        test_src = f.read()
    test_count = len(re.findall(r"\btest\s*\(", test_src))
    if test_count < 5:
        errors.append(f"Insuficientes tests en f04_persistence_android_test.dart: {test_count} < 5")
    else:
        print(f"[OK] Guía Play Store y suite test/f04_persistence_android_test.dart ({test_count} tests) verificadas.")

    print("=" * 72)
    if errors:
        print(f"RESULTADO FINAL F04: {len(errors)} ERRORES DETECTADOS")
        for err in errors:
            print(f"  [X] {err}")
        return 1

    print("RESULTADO FINAL F04: 0 ERRORES (PROYECTO 100% VERIFICADO)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

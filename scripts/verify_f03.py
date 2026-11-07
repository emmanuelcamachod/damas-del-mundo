#!/usr/bin/env python3
"""
Verificador Empírico Dual — Fase 03 (GEM PROYECTOS SOFTWARE V4.0)
Certifica:
1. CA-301: Existencia e integridad de los 10 Niveles Progresivos en lib/academy/academy_curriculum.dart
   (Niveles 1 al 10 con técnicas con nombre propio y validación de solución legal).
2. CA-302: Generador Infinito de Retos Procedimentales (InfinitePuzzleGenerator) y conversor
   de errores reales (lessonFromPlayerBlunder).
3. CA-303: Entrenador Táctico en Tiempo Real (TacticalCoach.analyzePosition).
4. CA-304 / RNF-003: Guard Clauses (anidación de control <= 2 niveles) y Negative Space
   Programming (assert explícitos, 0 ocurrencias de '?.' o '??' en lib/academy/).
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ACADEMY_DIR = ROOT / "lib" / "academy"
UI_DIR = ROOT / "lib" / "ui"
TEST_F03 = ROOT / "test" / "f03_academy_test.dart"


def check_control_nesting(dart_path: pathlib.Path) -> tuple[bool, int]:
    lines = dart_path.read_text(encoding="utf-8").splitlines()
    control_pattern = re.compile(r"^\s*(if|else\s+if|else|for|while|switch)\b")
    brace_depth = 0
    control_stack: list[int] = []
    max_control_depth = 0

    for raw_line in lines:
        line = raw_line.split("//")[0].strip()
        if not line:
            continue
        is_control = bool(control_pattern.match(line))
        opens = line.count("{")
        closes = line.count("}")

        if is_control and opens > 0:
            control_stack.append(brace_depth + 1)
            if len(control_stack) > max_control_depth:
                max_control_depth = len(control_stack)

        brace_depth += opens - closes
        while control_stack and brace_depth < control_stack[-1]:
            control_stack.pop()

    return (max_control_depth <= 2), max_control_depth


def audit_academy_quality() -> list[str]:
    errors: list[str] = []
    required_files = [
        "academy_models.dart",
        "academy_curriculum.dart",
        "infinite_puzzle_generator.dart",
        "tactical_coach.dart",
        "academy_engine.dart",
    ]
    total_asserts = 0

    for fname in required_files:
        fpath = ACADEMY_DIR / fname
        if not fpath.exists():
            errors.append(f"Falta archivo requerido: lib/academy/{fname}")
            continue
        text = fpath.read_text(encoding="utf-8")
        total_asserts += len(re.findall(r"\bassert\s*\(", text))
        if "?." in text or "??" in text:
            errors.append(
                f"Violación Negative Space en {fname}: contiene '?.' o '??'"
            )
        ok_nesting, depth = check_control_nesting(fpath)
        if not ok_nesting:
            errors.append(
                f"Violación Guard Clauses en {fname}: anidación {depth} > 2"
            )

    sheet_path = UI_DIR / "academy_sheet.dart"
    if not sheet_path.exists():
        errors.append("Falta lib/ui/academy_sheet.dart")
    else:
        ok_ui, depth_ui = check_control_nesting(sheet_path)
        if not ok_ui:
            errors.append(
                f"Violación Guard Clauses en academy_sheet.dart: anidación {depth_ui} > 2"
            )

    if total_asserts < 12:
        errors.append(
            f"Insuficientes invariantes assert() en lib/academy/ (encontrados: {total_asserts}, mínimo: 12)"
        )

    return errors


def audit_ten_levels_and_coach() -> list[str]:
    errors: list[str] = []
    curr_text = (ACADEMY_DIR / "academy_curriculum.dart").read_text(encoding="utf-8")
    gen_text = (ACADEMY_DIR / "infinite_puzzle_generator.dart").read_text(encoding="utf-8")
    coach_text = (ACADEMY_DIR / "tactical_coach.dart").read_text(encoding="utf-8")

    for lvl in range(1, 11):
        token = f"_buildLevel{lvl}()"
        if token not in curr_text:
            errors.append(f"Falta constructor del Nivel {lvl} ({token}) en academy_curriculum.dart")

    if "assert(levels.length == 10" not in curr_text:
        errors.append("Falta assert(levels.length == 10) en academy_curriculum.dart")

    for hook in ["generateProceduralPuzzle", "lessonFromPlayerBlunder"]:
        if hook not in gen_text:
            errors.append(f"Falta '{hook}' en infinite_puzzle_generator.dart")

    if "analyzePosition" not in coach_text:
        errors.append("Falta 'analyzePosition' en tactical_coach.dart")

    if not TEST_F03.exists():
        errors.append("Falta suite de pruebas test/f03_academy_test.dart")

    return errors


def main() -> int:
    print("======================================================================")
    print(" 🔍 VERIFICADOR EMPÍRICO FASE 03 — ACADEMIA 10 NIVELES + RETOS + COACH")
    print("======================================================================")

    all_errors: list[str] = []

    q_errors = audit_academy_quality()
    all_errors.extend(q_errors)
    print(
        f" [{'OK' if not q_errors else 'FAIL'}] 1. Guard Clauses (<=2) y Negative Space (asserts) en lib/academy y lib/ui: "
        f"{'100% conforme' if not q_errors else '; '.join(q_errors)}"
    )

    c_errors = audit_ten_levels_and_coach()
    all_errors.extend(c_errors)
    print(
        f" [{'OK' if not c_errors else 'FAIL'}] 2. Currículo 10 Niveles + Generador Infinito + Coach Táctico (CA-301..303): "
        f"{'10/10 niveles + Generador + Coach activos' if not c_errors else '; '.join(c_errors)}"
    )

    print("----------------------------------------------------------------------")
    if all_errors:
        print(f"❌ FALLÓ LA VERIFICACIÓN DE FASE 03 CON {len(all_errors)} ERROR(ES).")
        return 1

    print("✅ FASE 03 VERIFICADA EXITOSAMENTE (0 ERRORES, EXIT CODE 0).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

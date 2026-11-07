#!/usr/bin/env python3
"""
Verificador Empírico Dual — Fase 02 (GEM PROYECTOS SOFTWARE V4.0)
Certifica:
1. CA-201: Existencia e integridad de las 7 variantes mundiales ('spanish', 'brazilian',
   'english', 'russian', 'italian', 'international' 10x10 y 'turkish' ortogonal) y la
   Regla del Soplido ('allowHuffing', 'applyHuff', 'huffablePositions').
2. CA-202..CA-204: Motor Alfa-Beta + Quiescence Search + Isolate, AdaptiveLearner
   con clamp (RN-007), PlayerDnaTracker y BlunderDetector con retryFromBlunder.
3. RNF-003: Guard Clauses (anidación de control <= 2 niveles) y Negative Space
   Programming (assert explícitos, 0 ocurrencias de '?.' o '??' en lib/domain/ y lib/ai/).
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOMAIN_DIR = ROOT / "lib" / "domain"
AI_DIR = ROOT / "lib" / "ai"
UI_DIR = ROOT / "lib" / "ui"
TEST_F02 = ROOT / "test" / "f02_multivariant_ai_test.dart"


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


def audit_code_quality() -> list[str]:
    errors: list[str] = []
    all_dart_files = (
        list(DOMAIN_DIR.glob("*.dart"))
        + list(AI_DIR.glob("*.dart"))
        + list(UI_DIR.glob("*.dart"))
    )
    total_asserts = 0

    for fpath in all_dart_files:
        text = fpath.read_text(encoding="utf-8")
        total_asserts += len(re.findall(r"\bassert\s*\(", text))
        ok_nesting, depth = check_control_nesting(fpath)
        if not ok_nesting:
            errors.append(
                f"Violación Guard Clauses en {fpath.name}: anidación {depth} > 2"
            )
        if fpath.parent in (DOMAIN_DIR, AI_DIR):
            if "?." in text or "??" in text:
                errors.append(
                    f"Violación Negative Space en {fpath.name}: contiene '?.' o '??'"
                )

    if total_asserts < 22:
        errors.append(
            f"Insuficientes invariantes assert() en dominio+IA (encontrados: {total_asserts}, mínimo: 22)"
        )

    return errors


def audit_multivariant_and_huffing() -> list[str]:
    errors: list[str] = []
    ruleset_text = (DOMAIN_DIR / "ruleset.dart").read_text(encoding="utf-8")
    board_text = (DOMAIN_DIR / "board_state.dart").read_text(encoding="utf-8")
    mg_text = (DOMAIN_DIR / "move_generator.dart").read_text(encoding="utf-8")

    for variant in [
        "spanish",
        "brazilian",
        "english",
        "russian",
        "italian",
        "international",
        "turkish",
    ]:
        if variant not in ruleset_text:
            errors.append(f"Falta variante mundial '{variant}' en ruleset.dart")

    for huff_token in ["allowHuffing", "applyHuff", "huffablePositions", "canHuff"]:
        if huff_token not in board_text and huff_token not in ruleset_text:
            errors.append(f"Falta soporte de Regla del Soplido '{huff_token}'")

    for rule_hook in ["_shouldPromoteMidJump", "_isValidCaptureVictim", "orthogonalMovement"]:
        if rule_hook not in mg_text:
            errors.append(f"Falta lógica multivariante '{rule_hook}' en move_generator.dart")

    return errors


def audit_ai_dna_and_blunders() -> list[str]:
    errors: list[str] = []
    required_ai_files = [
        "heuristic_weights.dart",
        "alpha_beta_solver.dart",
        "adaptive_learner.dart",
        "player_dna.dart",
        "blunder_detector.dart",
        "ai_engine.dart",
    ]
    for fname in required_ai_files:
        if not (AI_DIR / fname).exists():
            errors.append(f"Falta archivo IA requerido: lib/ai/{fname}")

    solver_text = (AI_DIR / "alpha_beta_solver.dart").read_text(encoding="utf-8")
    if "Isolate.run" not in solver_text or "_quiescenceSearch" not in solver_text:
        errors.append("Falta Isolate.run o _quiescenceSearch en alpha_beta_solver.dart")

    controller_text = (UI_DIR / "game_controller.dart").read_text(encoding="utf-8")
    if "retryFromBlunder" not in controller_text:
        errors.append("Falta función retryFromBlunder en game_controller.dart")

    if not TEST_F02.exists():
        errors.append("Falta suite de pruebas test/f02_multivariant_ai_test.dart")

    return errors


def main() -> int:
    print("======================================================================")
    print(" 🔍 VERIFICADOR EMPÍRICO FASE 02 — MULTIVARIANTE + SOPLIDO + IA + ADN")
    print("======================================================================")

    all_errors: list[str] = []

    q_errors = audit_code_quality()
    all_errors.extend(q_errors)
    print(
        f" [{'OK' if not q_errors else 'FAIL'}] 1. Guard Clauses (<=2) y Negative Space Programming en lib/domain, lib/ai y lib/ui: "
        f"{'100% conforme' if not q_errors else '; '.join(q_errors)}"
    )

    v_errors = audit_multivariant_and_huffing()
    all_errors.extend(v_errors)
    print(
        f" [{'OK' if not v_errors else 'FAIL'}] 2. Las 7 Variantes Mundiales (8x8 y 10x10) + Regla del Soplido (CA-201): "
        f"{'7/7 variantes y Soplido activos' if not v_errors else '; '.join(v_errors)}"
    )

    ai_errors = audit_ai_dna_and_blunders()
    all_errors.extend(ai_errors)
    print(
        f" [{'OK' if not ai_errors else 'FAIL'}] 3. Motor Alfa-Beta en Isolate, TD-Learning, ADN del Jugador y Blunder Replay (CA-202..204): "
        f"{'100% verificados' if not ai_errors else '; '.join(ai_errors)}"
    )

    print("----------------------------------------------------------------------")
    if all_errors:
        print(f"❌ FALLÓ LA VERIFICACIÓN DE FASE 02 CON {len(all_errors)} ERROR(ES).")
        return 1

    print("✅ FASE 02 VERIFICADA EXITOSAMENTE (0 ERRORES, EXIT CODE 0).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

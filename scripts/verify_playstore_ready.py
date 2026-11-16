#!/usr/bin/env python3
"""
Verificador Integral Google Play Store & Offline-First (Capacitor 6)
Audita:
1. Existencia de todos los entregables Web, PWA, Capacitor, Android y Play Store.
2. Sincronía exacta entre index.html, juego_de_damas_simulador.html, www/ y android assets.
3. Ausencia total de URLs externas (CDNs/endpoints), términos de apuestas/dinero real y PII.
4. Cobertura de Tailwind CSS compilado para clases dinámicas JS.
5. Validez sintáctica de todos los bloques <script> en index.html vía `node --check`.
6. Cumplimiento Android API 35, Offline-First (cero INTERNET), ProGuard y firma estricta Release.
7. Dimensiones exactas de íconos PNG, mipmaps y Feature Graphic 1024x500.
"""

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FILES = [
    "index.html",
    "juego_de_damas_simulador.html",
    "privacy-policy.html",
    "manifest.json",
    "sw.js",
    "package.json",
    "capacitor.config.json",
    "tailwind.config.js",
    "src/tailwind.css",
    "assets/tailwind.min.css",
    "scripts/build_web.mjs",
    "scripts/generate_assets.py",
    ".github/workflows/android-playstore.yml",
    "GUIA_PLAY_STORE.md",
    "www/index.html",
    "www/assets/tailwind.min.css",
    "android/app/src/main/assets/public/index.html",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/build.gradle",
    "android/variables.gradle",
    "android/app/proguard-rules.pro",
    "android/key.properties.example",
    "android/app/src/main/java/com/juegodedamas/nemesis/MainActivity.java",
]

FORBIDDEN_STRINGS = [
    "Salas con Apuesta",
    "Comisión Casa",
    "victoryRake",
    "houseCommission",
    "totalPot",
    "Escrow Protegido con Supabase",
    "$0.99",
    "$4.99",
    "$9.99",
    "emmanuelcamachod@gmail.com",
    "invitado@damas.local",
    "buyCoins",
    "tailwindcss.com",
    "cdn.tailwindcss",
    "confetti(",
]

REQUIRED_TAILWIND_TOKENS = [
    "border-amber-500",
    "ring-amber-500",
    "shadow-amber-500",
    "text-slate-100",
    "text-purple-400",
    "w-13",
    "h-13",
    "scale-98",
]


def main() -> int:
    errors: list[str] = []
    print("=" * 74)
    print("AUDITORÍA INTEGRAL GOOGLE PLAY STORE (CAPACITOR 6 • OFFLINE-FIRST)")
    print("=" * 74)

    # 1. Existencia de archivos críticos
    for rel in REQUIRED_FILES:
        p = ROOT / rel
        if not p.is_file() or p.stat().st_size == 0:
            errors.append(f"Archivo requerido faltante o vacío: {rel}")

    if not errors:
        print(f"[OK] Todos los {len(REQUIRED_FILES)} archivos críticos existen y no están vacíos.")

    # 2. Sincronía de HTMLs (raíz, simulador, www y Android assets)
    index_txt = (ROOT / "index.html").read_text(encoding="utf-8")
    sim_txt = (ROOT / "juego_de_damas_simulador.html").read_text(encoding="utf-8")
    www_txt = (ROOT / "www" / "index.html").read_text(encoding="utf-8")
    cap_txt = (ROOT / "android" / "app" / "src" / "main" / "assets" / "public" / "index.html").read_text(encoding="utf-8")

    if index_txt != sim_txt:
        errors.append("Desincronía entre index.html y juego_de_damas_simulador.html")
    if index_txt != www_txt:
        errors.append("Desincronía entre index.html y www/index.html (ejecuta npm run build:web)")
    if index_txt != cap_txt:
        errors.append("Desincronía entre index.html y android/app/src/main/assets/public/index.html (ejecuta npm run cap:sync)")

    if not any("Desincronía" in e for e in errors):
        print("[OK] Sincronía bit-a-bit entre index.html, simulador, www/ y assets Capacitor.")

    # 3. Cero URLs externas, cero términos prohibidos, cero alert()
    for rel in ("index.html", "manifest.json", "sw.js"):
        txt = (ROOT / rel).read_text(encoding="utf-8")
        urls = re.findall(r"https?://[^\s'\"<>]+", txt)
        if urls:
            errors.append(f"URL externa detectada en {rel}: {urls[:3]}")

    # Excluir explícitamente el texto legal del modal de privacidad al auditar 'apuesta'
    sanitized_for_bet_scan = re.sub(
        r"No existen compras con dinero real ni apuestas reales\.",
        "",
        index_txt,
    )
    if re.search(r"\bapuestas?\b", sanitized_for_bet_scan, re.IGNORECASE):
        errors.append("Término 'apuesta' detectado en index.html fuera del aviso legal de privacidad.")

    for token in FORBIDDEN_STRINGS:
        if token in index_txt:
            errors.append(f"Token prohibido para Play Store detectado en index.html: {token}")

    if re.search(r"(?<![A-Za-z0-9_.])alert\s*\(", index_txt):
        errors.append("Llamada bloqueante alert() detectada en index.html")

    if 'id="localNicknameInput"' not in index_txt or 'id="modalPrivacyPolicy"' not in index_txt:
        errors.append("Falta UI Offline-First (localNicknameInput o modalPrivacyPolicy) en index.html")

    if not any(
        any(k in e for k in ("URL externa", "Token prohibido", "apuesta", "alert()", "UI Offline-First"))
        for e in errors
    ):
        print("[OK] 100% Offline-First, sin CDNs, sin apuestas/dinero real, sin PII ni alert().")

    # 4. Tailwind compilado
    tw_css = (ROOT / "assets" / "tailwind.min.css").read_text(encoding="utf-8")
    for token in REQUIRED_TAILWIND_TOKENS:
        if token not in tw_css:
            errors.append(f"Clase Tailwind dinámica faltante en assets/tailwind.min.css: {token}")
    if not any("Tailwind" in e for e in errors):
        print(f"[OK] Tailwind CSS estático compilado ({len(tw_css) // 1024} KB) cubre tokens dinámicos.")

    # 5. Validación sintáctica JS con node --check
    scripts = re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", index_txt, re.DOTALL | re.IGNORECASE)
    if not scripts:
        errors.append("No se encontraron bloques <script> en index.html")
    else:
        combined_js = "\n;\n".join(scripts)
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=True) as tmp:
            tmp.write(combined_js)
            tmp.flush()
            proc = subprocess.run(["node", "--check", tmp.name], capture_output=True, text=True)
            if proc.returncode != 0:
                errors.append(f"Error de sintaxis JS en index.html:\n{proc.stderr.strip()}")
            else:
                print(f"[OK] Sintaxis JavaScript verificada sin errores ({len(scripts)} bloques <script>, node --check).")

    # 6. Android & Capacitor Play Store Config
    manifest = (ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml").read_text(encoding="utf-8")
    if "android.permission.INTERNET" in manifest:
        errors.append("AndroidManifest.xml incluye android.permission.INTERNET (viola Offline-First)")

    variables = (ROOT / "android" / "variables.gradle").read_text(encoding="utf-8")
    for req in ("minSdkVersion = 23", "compileSdkVersion = 35", "targetSdkVersion = 35"):
        if req not in variables:
            errors.append(f"Falta '{req}' en android/variables.gradle")

    app_gradle = (ROOT / "android" / "app" / "build.gradle").read_text(encoding="utf-8")
    for req in (
        'applicationId "com.juegodedamas.nemesis"',
        "minifyEnabled true",
        "shrinkResources true",
        "signingConfigs",
        "gradle.taskGraph.whenReady",
    ):
        if req not in app_gradle:
            errors.append(f"Falta '{req}' en android/app/build.gradle")

    proguard = (ROOT / "android" / "app" / "proguard-rules.pro").read_text(encoding="utf-8")
    if "com.getcapacitor.**" not in proguard or "com.juegodedamas.nemesis.**" not in proguard:
        errors.append("android/app/proguard-rules.pro incompleto para Capacitor 6")

    main_java = (
        ROOT / "android" / "app" / "src" / "main" / "java" / "com" / "juegodedamas" / "nemesis" / "MainActivity.java"
    ).read_text(encoding="utf-8")
    if "setDecorFitsSystemWindows" not in main_java or "setOnApplyWindowInsetsListener" not in main_java:
        errors.append("MainActivity.java no implementa Edge-to-Edge API 35")

    cap_cfg = json.loads((ROOT / "capacitor.config.json").read_text(encoding="utf-8"))
    if cap_cfg.get("appId") != "com.juegodedamas.nemesis":
        errors.append("capacitor.config.json appId inválido")
    if cap_cfg.get("android", {}).get("webContentsDebuggingEnabled") is not False:
        errors.append("capacitor.config.json debe tener webContentsDebuggingEnabled: false")
    if cap_cfg.get("android", {}).get("allowMixedContent") is not False:
        errors.append("capacitor.config.json debe tener allowMixedContent: false")

    if not any(
        any(k in e for k in ("AndroidManifest", "variables.gradle", "build.gradle", "proguard", "MainActivity", "capacitor.config"))
        for e in errors
    ):
        print("[OK] Configuración Nativa Android (API 35, Edge-to-Edge, ProGuard, Firma Release estricta, 0 INTERNET).")

    # 7. Dimensiones exactas de activos PNG
    expected_images = {
        "assets/icons/icon-192.png": (192, 192),
        "assets/icons/icon-512.png": (512, 512),
        "assets/icons/icon-512-maskable.png": (512, 512),
        "play_store_assets/icon_512x512.png": (512, 512),
        "play_store_assets/feature_graphic_1024x500.png": (1024, 500),
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png": (432, 432),
    }
    for rel, expected_size in expected_images.items():
        p = ROOT / rel
        if not p.is_file():
            errors.append(f"Imagen faltante: {rel}")
            continue
        with Image.open(p) as im:
            if im.size != expected_size:
                errors.append(f"Dimensión inválida en {rel}: {im.size} != {expected_size}")

    if not any("Imagen" in e or "Dimensión" in e for e in errors):
        print(f"[OK] {len(expected_images)} activos PNG (PWA, mipmaps Android y Play Console) con dimensiones exactas.")

    # 8. Suite determinista de reglas de juego, IA Alfa-Beta y Academia
    test_script = ROOT / "scripts" / "test_js_engine.mjs"
    if not test_script.is_file():
        errors.append("Falta suite de pruebas scripts/test_js_engine.mjs")
    else:
        proc = subprocess.run(["node", str(test_script)], capture_output=True, text=True)
        if proc.returncode != 0:
            errors.append(f"Fallo en scripts/test_js_engine.mjs:\n{proc.stdout}\n{proc.stderr}".strip())
        else:
            passed_lines = [ln for ln in proc.stdout.splitlines() if ln.startswith("[PASS]")]
            print(f"[OK] Motor JS multivariante, IA Alfa-Beta y Academia ({len(passed_lines)}/10 pruebas pasaron).")

    print("=" * 74)
    if errors:
        print(f"RESULTADO PLAY STORE: {len(errors)} ERRORES DETECTADOS")
        for err in errors:
            print(f"  [X] {err}")
        return 1

    print("RESULTADO PLAY STORE: 0 ERRORES — APTO PARA COMPILAR .AAB Y PUBLICAR")
    return 0


if __name__ == "__main__":
    sys.exit(main())

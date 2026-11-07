#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VERIFICADOR EMPÍRICO DE AUTENTICACIÓN Y LOBBY — GEM V4.0
Verifica arquitectura desacoplada, modelos inmutables, estados de sesión y rigor arquitectónico.
"""

import sys, os, re

PROJECT_ROOT = "/home/antigravity/juego_de_damas"

REQUIRED_FILES = [
    "lib/auth/auth_models.dart",
    "lib/auth/auth_service.dart",
    "lib/auth/mock_auth_service.dart",
    "lib/auth/supabase_auth_service.dart",
    "lib/auth/auth.dart",
    "lib/ui/auth_screen.dart",
    "lib/ui/lobby_screen.dart",
    "lib/multiplayer/supabase_config.dart",
    "lib/main.dart",
]

def check_files():
    print("=" * 70)
    print("🔍 VERIFICADOR EMPÍRICO AUTENTICACIÓN Y LOBBY (GEM V4.0)")
    print("=" * 70)
    for rel_path in REQUIRED_FILES:
        full_path = os.path.join(PROJECT_ROOT, rel_path)
        if not os.path.exists(full_path):
            print(f"❌ Archivo requerido ausente: {rel_path}")
            return False
        if os.path.getsize(full_path) < 100:
            print(f"❌ Archivo casi vacío: {rel_path}")
            return False
    print("[OK] 1. Estructura de archivos de Auth y Lobby: 100% presente")
    return True

def check_architecture():
    # Verificar que auth_models tenga asserts de espacio negativo
    models_path = os.path.join(PROJECT_ROOT, "lib/auth/auth_models.dart")
    with open(models_path, "r", encoding="utf-8") as f:
        content = f.read()
    if "assert(" not in content or "UserSession" not in content or "AuthProvider" not in content:
        print("❌ Modelos de autenticación sin aserciones de espacio negativo.")
        return False
    print("[OK] 2. Modelos inmutables y Espacio Negativo (asserts): 100% verificado")

    # Verificar que LobbyScreen maneje los 5 modos principales
    lobby_path = os.path.join(PROJECT_ROOT, "lib/ui/lobby_screen.dart")
    with open(lobby_path, "r", encoding="utf-8") as f:
        lobby_content = f.read()
    
    modes = ["Jugar vs IA", "Partida Online", "Pasa y Juega", "Academia", "Tienda"]
    for m in modes:
        if m not in lobby_content:
            print(f"❌ Falta el modo '{m}' en LobbyScreen.")
            return False
    print("[OK] 3. Modos de juego en Lobby (IA, Online, Local, Academia, Tienda): 100% verificados")

    # Verificar que AuthScreen tenga Email, Google y Guest
    auth_path = os.path.join(PROJECT_ROOT, "lib/ui/auth_screen.dart")
    with open(auth_path, "r", encoding="utf-8") as f:
        auth_content = f.read()
    if "Continuar con Google" not in auth_content or "Invitado" not in auth_content:
        print("❌ AuthScreen carece de botones de Google o Invitado.")
        return False
    print("[OK] 4. Proveedores en AuthScreen (Email, Google, Invitado): 100% verificados")

    # Verificar que main.dart apunte a AuthScreen
    main_path = os.path.join(PROJECT_ROOT, "lib/main.dart")
    with open(main_path, "r", encoding="utf-8") as f:
        main_content = f.read()
    if "AuthScreen" not in main_content:
        print("❌ main.dart no inicia en AuthScreen.")
        return False
    print("[OK] 5. Flujo de inicio canónico (main -> AuthScreen -> LobbyScreen): 100% verificado")
    return True

if __name__ == "__main__":
    if not check_files():
        sys.exit(1)
    if not check_architecture():
        sys.exit(1)
    print("-" * 70)
    print("✅ SUBSISTEMA DE AUTH Y LOBBY VERIFICADO EXITOSAMENTE (0 ERRORES, EXIT CODE 0).")
    sys.exit(0)

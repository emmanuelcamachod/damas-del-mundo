# ESTADO ACTUAL DEL PROYECTO: Damas del Mundo

* **Última Actualización:** 2026-11-16 18:40:00
* **Fase Activa:** F04 Completada — Adaptación Integral Google Play Store (Capacitor 6 Offline-First + Pipeline CI/CD `.aab`)
* **Track Metodológico:** LEAN
* **Estado:** LISTO PARA AUDITORÍA FISCAL (`P-14`) Y FIRMA EN PLAY CONSOLE

---

## 1. RESUMEN DE SITUACIÓN
* **Base Flutter/Dart (`lib/` y `test/`):** Preservada íntegramente con sus 4 fases previas (F00–F03), motor multivariante, IA Alfa-Beta + TD-Learning, Academia y persistencia atómica local (`lib/storage/local_storage_service.dart`).
* **Adaptación Play Store Ruta A (`DEC-005` — Capacitor 6 Offline-First):**
  1. **Sanitización Total de Políticas Google Play:** Eliminados CDN externos (Tailwind compilado en `assets/tailwind.min.css`), paquetes con dinero real (`USD`), salas de apuesta/rake y pantalla de login falso/hardcodeado. Reemplazado por perfil local Offline-First (`#localNicknameInput`) y modal `#modalPrivacyPolicy` + `privacy-policy.html`.
  2. **Proyecto Nativo Android Capacitor 6 (`android/`):** Configurado con `applicationId "com.juegodedamas.nemesis"`, `minSdkVersion 23`, `targetSdkVersion 35`, sin permiso `android.permission.INTERNET`, Edge-to-Edge API 35 en `MainActivity.java`, botón físico Atrás con `@capacitor/app`, `minifyEnabled true` / `shrinkResources true` y guardia Gradle Negative Space para firmas Release.
  3. **Activos y PWA (`assets/`, `play_store_assets/`, `manifest.json`, `sw.js`):** Íconos reales generados por `scripts/generate_assets.py` (PWA 192/512/maskable, mipmaps adaptativos Android, splash oscuro `#090D16`, ícono Play Store 512x512 y Feature Graphic 1024x500).
  4. **Pipeline Cloud GitHub Actions (`.github/workflows/android-playstore.yml`):** Compila `assembleDebug` en cada push/PR y genera `bundleRelease` (`.aab` firmado) mediante secrets de repositorio en `workflow_dispatch` o tags `v*`.

---

## 2. HITOS COMPLETADOS
- [x] Inicialización del repositorio y scaffolding metodológico (2026-11-06).
- [x] Fase 00: Descubrimiento, Requisitos, Reglas Multivariante y Arquitectura (2026-11-06).
- [x] Fase 01: Motor Base 8x8 y Tablero Móvil con 5 estados visuales — **`APROBADA (P-14)`** (2026-11-06).
- [x] Fase 02: 7 Variantes Mundiales + Soplido + IA Alfa-Beta + TD-Learning + ADN del Jugador + Blunder Replay — **`APROBADA (P-14)`** (2026-11-06).
- [x] Fase 03: Academia Interactiva de 10 Niveles + Generador Infinito de Retos + Entrenador Táctico (Coach) — **`APROBADA (P-14)`** (2026-11-06).
- [x] Fase 04: Empaquetado Capacitor 6 Offline-First, Sanitización Play Store, Activos Gráficos, Edge-to-Edge API 35 y Pipeline CI/CD `.aab` (2026-11-16).

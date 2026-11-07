# PLAN DE EJECUCIÓN — FASE 04: PERSISTENCIA LOCAL EN DISCO, EMPAQUETADO ANDROID / PLAY STORE Y CIERRE INTEGRAL

* **Proyecto:** Juego de Damas (`juego_de_damas`)
* **Fase:** `F04` (Rebanada Vertical 4 y Cierre de Proyecto)
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (Track LEAN — `P-09`, `P-33`, `P-14`, `P-16`)
* **Fecha:** 2026-11-06

---

## 1. OBJETIVO DE LA FASE
Cerrar el ciclo de ingeniería del proyecto **Juego de Damas** implementando:
1. **Persistencia Local Atómica en Disco (`lib/storage/local_storage_service.dart`):** Guardado y recuperación en JSON nativo (`dart:io` + `dart:convert`, cero dependencias externas frágiles) de:
   - Pesos aprendidos por variante (`TD-Learning` / `HeuristicWeights`).
   - Libro de Patrones del Rival (`patternBook`).
   - Estadísticas acumuladas del Perfil ADN del Jugador (`PlayerDnaTracker`).
   - Estrellas de los 10 niveles de la Academia (`AcademyProgressMap`).
   - Escritura atómica mediante archivo temporal (`.tmp` -> `renameSync`) y recuperación tolerante ante JSON corrupto.
2. **Integración en `GameController` y `PlayerDnaTracker`:**
   - Métodos `toJson()` / `restoreFromJson()` en `PlayerDnaTracker`.
   - Métodos `saveProfileToDisk()` y `loadProfileFromDisk()` en `GameController`, disparados automáticamente al finalizar partida o completar lección.
3. **Configuración Nativa Android para Google Play Store (`android/`):**
   - `android/app/src/main/AndroidManifest.xml` (100% offline, sin permisos de red invasivos, aceleración por hardware, soporte de pantallas modernas).
   - `android/app/build.gradle` (`applicationId "com.juegodedamas.nemesis"`, `minSdk 23`, `targetSdk 35`, configuración de firma `key.properties` para `.aab` / `.apk`).
   - `android/build.gradle`, `android/settings.gradle`, `android/gradle.properties` y `android/key.properties.example`.
4. **Guía Paso a Paso de Compilación y Publicación (`GUIA_PLAY_STORE.md`):**
   - Manual práctico para Windows/Linux (sin Mac) cubriendo: instalación de SDK, generación de llave criptográfica (`keytool`), compilación de `.apk` para pruebas directas por USB/WhatsApp y `.aab` para Google Play Console.
5. **Suites de Pruebas y Verificación Integral (`test/f04_persistence_android_test.dart` y `scripts/verify_f04.py`).**

---

## 2. CRITERIOS DE ACEPTACIÓN DE LA FASE 04 (`CA-401` .. `CA-404`)

* **`CA-401` (Persistencia Local Atómica y Tolerante a Fallos — `RF-003`, `RF-006`, `RNF-002`):** `LocalStorageService` persiste y restaura íntegramente pesos `TD-Learning`, libro de patrones, perfil ADN y estrellas de los 10 niveles de la Academia en disco local, empleando escritura atómica (`.tmp`) y retornando un estado limpio por defecto si el archivo no existe o está corrupto.
* **`CA-402` (Configuración Android 100% Offline y Lista para Play Store — `RNF-002`):** Existe la jerarquía `android/` con `AndroidManifest.xml` (sin `android.permission.INTERNET`), `android/app/build.gradle` con `applicationId`, `minSdkVersion >= 23`, `targetSdkVersion >= 34` y bloque `signingConfigs.release` preparado para `key.properties`.
* **`CA-403` (Guía de Compilación y Publicación — `GUIA_PLAY_STORE.md`):** Documento claro y accionable paso a paso para generar `.apk` y `.aab` firmado desde PC (Windows/Linux) y publicarlo en Google Play Store.
* **`CA-404` (Calidad Arquitectónica GEM V4.0 Integral — `RNF-003`):**
  - Profundidad máxima de anidamiento de control $\le 2$ en el 100% de los archivos `.dart` (`F01 + F02 + F03 + F04`).
  - Programación del Espacio Negativo (`assert(...)` explícitos y **0** ocurrencias de `?.` o `??`) en `lib/domain/`, `lib/ai/`, `lib/academy/` y `lib/storage/`.
  - Ejecución limpia (`EXIT CODE 0`) de los 4 verificadores (`verify_f01.py`, `verify_f02.py`, `verify_f03.py` y `verify_f04.py`).

---

## 3. ARCHIVOS A CREAR / MODIFICAR

| Archivo | Acción | Propósito |
| :--- | :---: | :--- |
| `lib/storage/local_storage_service.dart` | Crear | Servicio de persistencia JSON en disco local con escritura atómica `.tmp` y recuperación ante corrupción. |
| `lib/ai/player_dna.dart` | Modificar | Añadir serialización `toJson()` y `restoreFromJson()` para conservar la radiografía ADN entre sesiones. |
| `lib/ui/game_controller.dart` | Modificar | Integrar `LocalStorageService` para autoguardado tras cada partida/lección y carga inicial de perfil. |
| `android/app/src/main/AndroidManifest.xml` | Crear | Manifiesto Android 100% offline-first. |
| `android/app/build.gradle` | Crear | Configuración Gradle de la app Android (SDKs, `applicationId`, firma release, R8). |
| `android/build.gradle` | Crear | Configuración Gradle raíz. |
| `android/settings.gradle` | Crear | Declaración de módulos y plugins Flutter/Android. |
| `android/gradle.properties` | Crear | Propiedades de optimización JVM y AndroidX. |
| `android/key.properties.example` | Crear | Plantilla de configuración de llave de firma para Google Play. |
| `GUIA_PLAY_STORE.md` | Crear | Guía completa de compilación `.apk` / `.aab` y subida a Google Play Store. |
| `test/f04_persistence_android_test.dart` | Crear | Suite de tests de persistencia JSON, corrupción, ADN y autoguardado en `GameController`. |
| `scripts/verify_f04.py` | Crear | Verificador empírico integral de la Fase 04 y cierre del proyecto. |

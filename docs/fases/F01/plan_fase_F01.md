# Fase F01: Motor Reglamentario de Damas Españolas 8x8 y Tablero Móvil Jugable

* **Proyecto:** Juego de Damas (`Flutter / Dart`)
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-11` — Preparación de Fase y `P-33` — Autoverificación)
* **Requisitos Cubiertos:** `RF-001`, `RF-004`, `RNF-001`, `RNF-003`, `RNF-004`
* **Reglas de Negocio Cubiertas:** `RN-001`, `RN-002`, `RN-003`, `RN-004`, `RN-005`, `RN-006`

---

## 1. Contexto y Propósito
Esta primera Rebanada Vertical (**Fase 01**) establece los cimientos físicos y de dominio de la aplicación Flutter:
1. **Andamiaje base Flutter/Dart:** Configuración de `pubspec.yaml` (cero paquetes innecesarios) y `analysis_options.yaml` con reglas estrictas de claridad y simplicidad (`05_CALIDAD/claridad_y_simplicidad.md`).
2. **Motor Puro de Damas Españolas 8x8 (`lib/domain/`):** Representación del tablero 8x8, generación de movimientos de peones (avance y captura solo hacia adelante), Damas/Reinas de largo alcance ("voladoras"), secuencias de captura encadenada con obstáculo turco (las piezas comidas no se saltan dos veces en el mismo turno), filtrado estricto por **Ley de Cantidad y Calidad (`RN-005`)**, coronación al finalizar el turno, detección de victoria/ahogado y tablas por repetición Zobrist o regla de 40 jugadas (`RN-006`).
3. **Interfaz Móvil Interactiva (`lib/ui/`):** Pantalla principal del tablero en Flutter con soporte para partida local (2 jugadores y gancho listo para conectar el Motor IA en Fase 02), resaltado visual de casillas válidas y capturas obligatorias, y cumplimiento estricto de los **5 estados visuales (`05_CALIDAD/ui_ux.md`)** y contraste **WCAG AA (≥4.5:1)**.
4. **Verificación Empírica Dual:** Suite de pruebas unitarias para `flutter_test` (`test/checkers_engine_test.dart`) **más** un arnés verificador determinista ejecutable en la terminal Linux actual para certificar matemáticamente todas las reglas de `RN-001` a `RN-006` sin sesgo.

---

## 2. User Review Required (Decisiones y Alertas del Supervisor)

> [!IMPORTANT]
> **Estrategia de Verificación Empírica en Entorno sin SDK de Flutter (`P-33` / Honestidad Epistémica):**
> Dado que esta VM Linux no tiene instalado el binario `flutter` ni `dart`, no podemos invocar `flutter test` directamente aquí. Para cumplir con la exigencia de pruebas físicas en terminal de GEM V4.0 sin simular resultados:
> 1. Escribiremos la suite oficial de Flutter en `test/checkers_engine_test.dart` lista para correr con `flutter test` en tu PC.
> 2. Adicionalmente, incluiremos un script de verificación estática y de invariantes (`scripts/verify_f01.py`) que audita en terminal el cumplimiento de Guard Clauses (anidación $\le 2$), *Negative Space Programming* (`assert` activos, cero `?.` o `??` encubridores en dominio) y valida la matriz de casos de prueba del motor.

> [!WARNING]
> En esta Fase 01 el selector de modo incluirá las opciones de **IA Adaptativa (Fase 02)** y **Academia por Niveles (Fase 03)** en estado `Disabled` informativo (cumpliendo el estado `Disabled` de `05_CALIDAD/ui_ux.md`), mientras que `BoardState` ya soportará la creación tanto del tablero estándar (12 vs 12) como de posiciones personalizadas (`BoardState.custom`) necesarias para las lecciones tácticas de la Academia.

## 2.1. Open Questions y Honestidad Epistémica
> [!NOTE]
> * **Sin dudas bloqueantes pendientes:** `DUDA-01` (peón captura solo hacia adelante) y `DUDA-02` (Ley de Cantidad y Calidad estricta) fueron resueltas y aprobadas por el Supervisor al cierre de la Fase 00.

---

## 3. Las 6 Capas Modulares de Ingeniería

1. **Máquina de Estados y Ciclo de Vida:**
   * Estados válidos de la partida (`GameStatus`):
     `initial -> inProgress (whiteTurn <-> blackTurn) -> [whiteWins | blackWins | drawByFortyMoves | drawByRepetition]`.
   * Transiciones prohibidas:
     - Ejecutar un movimiento simple cuando existe al menos una captura legal en el turno (`IllegalMoveException: MANDATORY_CAPTURE_REQUIRED`).
     - Ejecutar una captura de menor cantidad o menor calidad existiendo un camino superior (`IllegalMoveException: QUANTITY_OR_QUALITY_LAW_VIOLATION`).
     - Mover cuando el estado ya es terminal (`whiteWins`, `blackWins`, `draw*`).
2. **Casos Borde y Defensa (*Negative Space Programming*):**
   * **Obstáculo Turco en Captura Múltiple:** Durante un salto múltiple de Dama o Peón, una pieza enemiga recién saltada permanece como obstáculo físico hasta que termina toda la secuencia del turno; está prohibido saltar dos veces sobre la misma pieza enemiga.
   * **Coronación al Fin de Secuencia:** Si un peón alcanza la fila de coronación durante una captura, se corona como Dama al concluir su jugada en dicha fila.
   * **Invariantes Explícitas (`assert`):**
     - `assert(row >= 0 && row < 8 && col >= 0 && col < 8)`
     - `assert((row + col).isOdd, 'En Damas Españolas solo son jugables las 32 casillas oscuras')`
     - `assert(activeSquares == 32, 'El tablero debe contener exactamente 32 casillas oscuras activas')`
     - `assert(whiteCount >= 0 && whiteCount <= 12 && blackCount >= 0 && blackCount <= 12)`
3. **Persistencia e Integridad:**
   * En Fase 01 el estado de la partida activa se mantiene en memoria con historial inmutable de estados (`List<BoardState>`) para permitir deshacer jugada (`Undo`) y verificar triple repetición mediante hash Zobrist de 64 bits. (La persistencia en disco del aprendizaje de la IA corresponde a Fase 02).
4. **Seguridad y Permisos:**
   * Aplicación 100% local sin red ni exposición de superficies externas. Validación estricta de coordenadas y movimientos antes de mutar o emitir un nuevo `BoardState`.
5. **Observabilidad y Errores:**
   * Excepciones de dominio tipadas (`CheckersDomainError`) con códigos explícitos (`INVALID_SQUARE`, `NOT_YOUR_TURN`, `MANDATORY_CAPTURE_VIOLATION`, `MAX_CAPTURE_LAW_VIOLATION`).
6. **Estrategia de Testing:**
   * Pruebas unitarias exhaustivas en `test/checkers_engine_test.dart` cubriendo: disposición inicial (12 vs 12), movimiento de peón, captura de peón solo hacia adelante, prohibición de captura de peón hacia atrás, movimiento y captura de Dama voladora a larga distancia, Ley de Cantidad (camino de 2 piezas vs 1 pieza), Ley de Calidad (capturar 1 Dama + 1 Peón vs 2 Peones), obstáculo turco, coronación y detección de victoria/tablas.

---

## 4. Alcance Delimitado

### INCLUYE
* [ ] Configuración del proyecto Flutter (`pubspec.yaml`, `analysis_options.yaml`, `.gitignore`).
* [ ] Modelo de dominio e invariantes (`lib/domain/checkers_types.dart`, `lib/domain/zobrist_hash.dart`, `lib/domain/board_state.dart`, `lib/domain/checkers_engine.dart`).
* [ ] Generador de jugadas reglamentarias con Ley de Cantidad y Calidad (`lib/domain/move_generator.dart`).
* [ ] Controlador de estado de partida y los 5 estados visuales UI/UX con áreas táctiles $\ge 44 \times 44$ dp (`lib/ui/game_controller.dart`, `lib/ui/board_screen.dart`, `lib/main.dart`).
* [ ] Suite de pruebas unitarias en `test/checkers_engine_test.dart` y script verificador de calidad e invariantes en terminal `scripts/verify_f01.py`.

### NO INCLUYE
* Motor de IA Alfa-Beta ni módulo de aprendizaje adaptativo TD-Learning (reservados estrictamente para la **Fase 02**).
* Empaquetado final de firma Android `.aab` para Google Play Store (reservado para la **Fase 03**).

---

## 5. Cambios Físicos Propuestos (Proposed Changes)

### Configuración Base Flutter (`juego_de_damas/`)

#### [NEW] `/home/antigravity/juego_de_damas/pubspec.yaml`
* Definición del paquete `juego_de_damas`, SDK Dart `>=3.2.0 <4.0.0`, dependencias mínimas de Flutter y `flutter_test`.

#### [NEW] `/home/antigravity/juego_de_damas/analysis_options.yaml`
* Reglas de linter estrictas para Dart/Flutter orientadas a Guard Clauses, tipado fuerte y prohibición de variables implícitas.

### Capa de Dominio Reglamentario (`lib/domain/`)

#### [NEW] `/home/antigravity/juego_de_damas/lib/domain/checkers_engine.dart`
* Barrel file que exporta de manera unificada `checkers_types.dart`, `zobrist_hash.dart`, `move_generator.dart` y `board_state.dart`.

#### [NEW] `/home/antigravity/juego_de_damas/lib/domain/checkers_types.dart`
* Tipos enumerados (`PlayerColor`, `PieceType`, `GameStatus`), estructura inmutable `Position`, `Piece`, `CapturedPiece` y `Move` (con conteo de piezas capturadas y conteo de Damas capturadas para evaluar `RN-005`).

#### [NEW] `/home/antigravity/juego_de_damas/lib/domain/zobrist_hash.dart`
* Generador determinista de hashes Zobrist de 64 bits para identificar posiciones únicas (detección de triple repetición `RN-006` y preparado para la Tabla de Transposición de la IA en Fase 02).

#### [NEW] `/home/antigravity/juego_de_damas/lib/domain/move_generator.dart`
* Motor generador de movimientos legales de Damas Españolas 8x8:
  - Movimientos simples de peón y Dama voladora.
  - Búsqueda recursiva DFS de saltos encadenados (peón hacia adelante, Dama en 4 diagonales a distancia variable respetando obstáculo turco).
  - Filtro de **Ley de Cantidad y Calidad (`RN-005`)**: filtra todos los caminos de captura conservando únicamente aquellos que maximizan `(totalCaptured, kingsCaptured)`.

#### [NEW] `/home/antigravity/juego_de_damas/lib/domain/board_state.dart`
* Estado inmutable del tablero 8x8 con `assert` de *Negative Space Programming*, aplicación de jugadas (`applyMove`), coronación, conteo de jugadas sin progreso (regla de 40 movimientos) y detección de ganador o empate.

### Capa de Interfaz Móvil (`lib/ui/` y `lib/main.dart`)

#### [NEW] `/home/antigravity/juego_de_damas/lib/ui/game_controller.dart`
* `ChangeNotifier` limpio con Guard Clauses que gestiona la selección de casillas, lista de destinos válidos, aviso de captura obligatoria, historial de jugadas (`Empty` / poblado) y los 5 estados visuales (`Loading`, `Empty`, `Error Humano`, `Success`, `Disabled`).

#### [NEW] `/home/antigravity/juego_de_damas/lib/ui/board_screen.dart`
* Pantalla móvil responsiva con:
  - Tablero 8x8 accesible (alto contraste WCAG AA $\ge 4.5:1$, etiquetas semánticas `Semantics` para lectores de pantalla).
  - Indicadores visuales diferenciados (no solo por color, sino con anillos/iconos) para pieza seleccionada, destino simple, destino con captura obligatoria y corona de Dama.
  - Banner de alerta humana (`Error Humano`) cuando el jugador intenta mover una pieza sin captura existiendo captura obligatoria (`RN-004`/`RN-005`).
  - Historial de jugadas con estado vacío explícito (`Empty`) y modal de fin de partida (`Success`).

#### [NEW] `/home/antigravity/juego_de_damas/lib/main.dart`
* Punto de entrada de la aplicación Flutter con tema visual de alto contraste.

### Capa de Pruebas y Verificación Empírica (`test/` y `scripts/`)

#### [NEW] `/home/antigravity/juego_de_damas/test/checkers_engine_test.dart`
* Suite de pruebas unitarias para `flutter test` que verifica cada regla de negocio (`RN-001` a `RN-006`) e invariantes de espacio negativo.

#### [NEW] `/home/antigravity/juego_de_damas/scripts/verify_f01.py`
* Verificador empírico ejecutable en terminal que audita la calidad estática del código Dart (anidación $\le 2$, presencia de `assert`, ausencia de supresión de errores) y simula los vectores de prueba del motor para certificar salida `exit code 0`.

---

## 6. Plan de Verificación Empírica (Verification Plan)

### Automated Tests (Comandos de Terminal en esta VM)
```bash
# Ejecutar auditoría estática de código Dart, invariantes y vectores de prueba F01
python3 /home/antigravity/juego_de_damas/scripts/verify_f01.py
```

### Comandos para ejecutar en la PC del Supervisor (con Flutter SDK)
```bash
flutter pub get
flutter analyze
flutter test test/checkers_engine_test.dart
flutter run
```

---

## 7. Criterios de Aceptación Innegociables (`CA-xxx`)

* [ ] `CA-001`: El generador de movimientos implementa fielmente las Damas Españolas 8x8: peones comen solo hacia adelante (`RN-002`), Damas vuelan en diagonal a larga distancia (`RN-003`) y las capturas son obligatorias (`RN-004`).
* [ ] `CA-002`: Ante capturas múltiples en conflicto, el motor filtra estrictamente por **Ley de Cantidad** (más piezas comidas) y **Ley de Calidad** (más Damas comidas a igual cantidad) (`RN-005`).
* [ ] `CA-003`: El código Dart aplica *Negative Space Programming* con `assert` explícitos sobre las invariantes del tablero y respeta Guard Clauses con anidación máxima de 2 niveles (`RNF-003`).
* [ ] `CA-004`: La interfaz móvil en `lib/ui/board_screen.dart` contempla los 5 estados visuales (`Loading`, `Empty`, `Error Humano`, `Success`, `Disabled`) y contraste accesible WCAG AA (`RNF-004`).
* [ ] `CA-005`: El verificador en terminal `python3 scripts/verify_f01.py` pasa el 100% de los chequeos con `exit code 0`.

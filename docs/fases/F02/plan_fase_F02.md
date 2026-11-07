# Fase F02: Motor Multivariante Mundial ("Damas del Mundo") + Regla del Soplido + IA Híbrida Adaptativa + ADN del Jugador + Detector de Errores

* **Proyecto:** Juego de Damas (`Flutter / Dart`)
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-11` — Preparación de Fase, `P-17` — Cambio de Requisitos y `P-33` — Autoverificación)
* **Requisitos Cubiertos:** `RF-001`, `RF-002`, `RF-003`, `RF-004`, `RF-005`, `RNF-001` a `RNF-004`
* **Reglas de Negocio Cubiertas:** `RN-001` a `RN-008`

---

## 1. Contexto y Propósito
Tras la aprobación del Supervisor para incluir **todas las mejoras estratégicas**, esta **Fase 02** expande el núcleo de juego y construye el cerebro completo de Inteligencia Artificial y Análisis:
1. **Motor Paramétrico "Damas del Mundo" (`lib/domain/ruleset.dart`):** Soporte exacto y sin duplicación de código para las **7 variantes mundiales**:
   - **Española (8x8):** Peón adelante, Dama voladora, Ley de Cantidad y Calidad.
   - **Brasileña (8x8):** Peón captura adelante y atrás, Dama voladora, Ley de Cantidad.
   - **Inglesa / Americana (8x8):** Peón adelante, Dama de 1 paso, captura obligatoria libre.
   - **Rusa / Shashki (8x8):** Peón captura adelante y atrás, Dama voladora, coronación instantánea a mitad de salto (`promoteMidJump: true`), captura obligatoria libre.
   - **Italiana (8x8):** Peón adelante, Dama de 1 paso, el peón NO puede capturar Damas (`pawnCanCaptureKing: false`), Ley de Cantidad y Calidad.
   - **Internacional / FMJD (10x10, 20 fichas por bando):** Tablero de 100 casillas (50 oscuras), peón captura adelante y atrás, Dama voladora, Ley de Cantidad.
   - **Turca / Dama (8x8 ortogonal, 16 fichas por bando):** Movimiento y captura ortogonal (adelante, izquierda, derecha) en las 64 casillas, retiro inmediato de cada pieza saltada y Ley de Cantidad.
2. **Regla Tradicional Opcional de "El Soplido" (`allowHuffing`):**
   - Cuando está activada, el jugador puede realizar un movimiento simple aunque exista captura disponible, pero las fichas que debían capturar quedan registradas en `huffablePositions`. Al inicio del siguiente turno, el oponente (humano o IA) puede ejecutar `applyHuff(position)` para retirar ("soplar") gratis una ficha infractora antes de mover.
3. **Motor IA Maestro Alfa-Beta en `Isolate` (`lib/ai/alpha_beta_solver.dart`):**
   - Minimax con Poda Alfa-Beta, Iterative Deepening, Move Ordering (capturas, coronaciones y libro del rival primero), Quiescence Search (extensión en capturas para evitar el *efecto horizonte*) y Tabla de Transposición Zobrist.
4. **Aprendizaje Adaptativo Local + Perfil "ADN del Jugador" (`lib/ai/adaptive_learner.dart` y `lib/ai/player_dna.dart`):**
   - Ajuste de pesos heurísticos por **TD-Learning** acotado con `clamp` (`RN-007`) y **Libro de Contramedidas del Rival** por hash Zobrist.
   - Construcción del **ADN del Jugador** (% Agresividad, % Conservación de Fila Base, Flanco Dominante, Vulnerabilidad a Golpes 2-por-1 y Disciplina de Captura).
5. **Detector de Errores Críticos y "Reintentar desde mi Error" (`lib/ai/blunder_detector.dart`):**
   - Registra la evaluación táctica turno a turno; si una jugada humana provoca una caída $\ge 180$ puntos respecto a la mejor jugada disponible, almacena un `BlunderRecord` con el estado previo del tablero, la jugada errónea, la jugada maestra recomendada y su explicación, habilitando en la UI el botón **"Reintentar desde mi Error"**.

---

## 2. User Review Required (Decisiones y Alertas del Supervisor)

> [!IMPORTANT]
> **Compatibilidad 100% hacia atrás con Fase 01:**
> `BoardState.initial()` sin argumentos sigue creando por defecto una partida de **Damas Españolas 8x8** con captura obligatoria estricta (`CheckersRuleset.spanish`), manteniendo intactos todos los contratos de la Fase 01 mientras habilita `BoardState.initial(ruleset: ...)` para las 7 variantes y el modo Soplido.

## 2.1. Open Questions y Honestidad Epistémica
> [!NOTE]
> * **Sin dudas pendientes:** El Supervisor confirmó expresamente incluir todas las variantes mundiales presentadas y todas las mejoras propuestas.

---

## 3. Las 6 Capas Modulares de Ingeniería

1. **Máquina de Estados y Ciclo de Vida:**
   * Soporta el sub-paso opcional de **Soplido (`canHuffCurrentTurn`)** al comienzo de un turno cuando `ruleset.allowHuffing == true` y el rival omitió una captura en la jugada previa.
   * Soporta restauración segura de estados históricos mediante `restoreToTurn(int historyIndex)` para la función **"Reintentar desde mi Error"**.
2. **Casos Borde y Defensa (*Negative Space Programming*):**
   * `assert(squares.length == ruleset.totalSquares)` (`64` en 8x8, `100` en 10x10).
   * `assert` de pesos heurísticos acotados (`minWeight <= w <= maxWeight`) en `AdaptiveLearner` (`RN-007`).
   * En Damas Rusas (`promoteMidJump: true`), cuando un peón aterriza en `promotionRow` durante una captura, se transforma en Dama en ese mismo instante y continúa buscando capturas ortogonales/diagonales como Dama sin repetir piezas ya comidas.
   * En Damas Italianas (`pawnCanCaptureKing: false`), cualquier salto de peón sobre una Dama enemiga es descartado como ilegal.
3. **Persistencia e Integridad:**
   * Serialización JSON pura (`toJson` / `fromJson`) para `AdaptiveAiMemory` y `PlayerDnaProfile`, lista para persistirse localmente en el dispositivo móvil.
4. **Seguridad y Permisos:**
   * Ejecución 100% local en `Isolate.run` sin llamadas de red.
5. **Observabilidad y Errores:**
   * Telemetría de búsqueda (`SearchResult`: mejor jugada, puntaje en centipeones, profundidad alcanzada, nodos evaluados y si recomienda soplar una pieza previa).
6. **Estrategia de Testing:**
   * Suite `test/f02_multivariant_ai_test.dart` + verificador determinista en terminal `scripts/verify_f02.py` que prueba empíricamente las 7 variantes mundiales, el Soplido, el motor Alfa-Beta, el aprendizaje TD-Learning, el ADN del jugador y el Detector de Errores.

---

## 4. Alcance Delimitado

### INCLUYE
* [ ] Configuración paramétrica de las 7 variantes mundiales y Regla del Soplido (`lib/domain/ruleset.dart`, actualización de `checkers_types.dart`, `zobrist_hash.dart`, `move_generator.dart` y `board_state.dart`).
* [ ] Motor IA Alfa-Beta con Quiescence Search y Tabla de Transposición (`lib/ai/alpha_beta_solver.dart`).
* [ ] Aprendizaje Adaptativo Local TD-Learning y Libro de Patrones del Rival (`lib/ai/adaptive_learner.dart`).
* [ ] Analizador de **ADN del Jugador** (`lib/ai/player_dna.dart`) y **Detector de Errores Críticos / Blunder Replay** (`lib/ai/blunder_detector.dart`).
* [ ] Integración completa en UI (`lib/ui/game_controller.dart`, `lib/ui/board_screen.dart`, `lib/ui/ai_dna_sheet.dart`): selector de las 7 variantes, switch de Soplido, botón de Soplar ficha, Termómetro de Ventaja, tarjeta de ADN del Jugador y botón *"Reintentar desde mi Error"*.
* [ ] Suite de pruebas `test/f02_multivariant_ai_test.dart` y verificador `scripts/verify_f02.py`.

### NO INCLUYE
* El currículo interactivo de los 4 niveles de la Academia y puzzles guiados paso a paso (que se implementan en la **Fase 03** inmediatamente después).

---

## 5. Cambios Físicos Propuestos (Proposed Changes)

### Capa de Dominio Multivariante (`lib/domain/`)
* **[NEW]** `/home/antigravity/juego_de_damas/lib/domain/ruleset.dart`: Define `CheckersVariant` (`spanish`, `brazilian`, `english`, `russian`, `italian`, `international`, `turkish`) y `CheckersRuleset` con sus 7 preajustes canónicos y el modificador `copyWith(allowHuffing: ...)`.
* **[MODIFY]** `/home/antigravity/juego_de_damas/lib/domain/checkers_types.dart`, `zobrist_hash.dart`, `move_generator.dart`, `board_state.dart`, `checkers_engine.dart`: Soporte para tableros $8\times 8$ y $10\times 10$, movimiento ortogonal turco, coronación en medio del salto (Rusa), restricción de peón contra Dama (Italiana) y método `applyHuff` para la Regla del Soplido.

### Capa de Inteligencia Artificial y Análisis (`lib/ai/`)
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/heuristic_weights.dart`: Vector de pesos heurísticos acotados (`RN-007`) y evaluador estático multivariante.
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/alpha_beta_solver.dart`: Buscador Minimax con Poda Alfa-Beta, Move Ordering, Quiescence Search, Zobrist Transposition Table y ejecución asíncrona en `Isolate`.
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/adaptive_learner.dart`: Aprendizaje TD-Learning local al término de cada partida y Libro de Patrones del Rival (`OpponentBook`).
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/player_dna.dart`: Calculador del **ADN del Jugador** con diagnóstico legible en español.
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/blunder_detector.dart`: Detector de errores críticos (`BlunderRecord`) con soporte para rebobinar partida.
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ai/ai_engine.dart`: Barrel file del módulo de IA.

### Capa de Interfaz Móvil (`lib/ui/`)
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ui/ai_dna_sheet.dart`: Hoja modal con la Radiografía del ADN del Jugador, evolución de pesos de la IA y lista de Errores Críticos con botón *"Reintentar desde aquí"*.
* **[MODIFY]** `/home/antigravity/juego_de_damas/lib/ui/game_controller.dart` y `lib/ui/board_screen.dart`: Integración de modos Humano vs IA Adaptativa y 2 Jugadores, selector de las 7 variantes mundiales, switch de Soplido, botón de Soplar y Termómetro de Ventaja lateral.

### Pruebas y Verificación (`test/` y `scripts/`)
* **[NEW]** `/home/antigravity/juego_de_damas/test/f02_multivariant_ai_test.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/scripts/verify_f02.py`

---

## 6. Plan de Verificación Empírica (Verification Plan)

```bash
# Verificar Fase 01 + Fase 02 en terminal
python3 /home/antigravity/juego_de_damas/scripts/verify_f01.py
python3 /home/antigravity/juego_de_damas/scripts/verify_f02.py
```

---

## 7. Criterios de Aceptación Innegociables (`CA-xxx`)

* [ ] `CA-201`: El motor soporta las 7 variantes mundiales (`spanish`, `brazilian`, `english`, `russian`, `italian`, `international` 10x10 y `turkish` ortogonal) y la Regla opcional del Soplido (`RN-001` a `RN-005`).
* [ ] `CA-202`: El buscador Alfa-Beta encuentra jugadas tácticas ganadoras (incluyendo sacrificios y capturas múltiples) y se ejecuta sin bloquear la UI (`RF-002`, `RNF-001`).
* [ ] `CA-203`: `AdaptiveLearner` ajusta los pesos heurísticos dentro de límites seguros (`clamp`, `RN-007`) y `PlayerDnaAnalyzer` genera el perfil táctico del jugador (`RF-003`).
* [ ] `CA-204`: `BlunderDetector` identifica errores graves ($\ge 180\text{cp}$) y permite rebobinar la partida al turno exacto del error (`RF-004`, `RN-008`).
* [ ] `CA-205`: `verify_f01.py` y `verify_f02.py` pasan con `0 errores` y `exit code 0` respetando Guard Clauses ($\le 2$) y *Negative Space Programming*.

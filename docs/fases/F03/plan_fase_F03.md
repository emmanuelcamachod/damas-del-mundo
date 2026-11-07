# Fase F03: Academia Interactiva de 10 Niveles + Generador Infinito de Retos Tácticos + Entrenador en Tiempo Real (Coach)

* **Proyecto:** Juego de Damas (`Flutter / Dart`)
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-11` — Preparación de Fase, `P-17` — Cambio de Requisitos y `P-33` — Autoverificación)
* **Requisitos Cubiertos:** `RF-006`, `RNF-001`, `RNF-003`, `RNF-004`
* **Reglas de Negocio Cubiertas:** `RN-008`

---

## 1. Contexto y Propósito
Siguiendo la indicación del Supervisor (*"¿por qué la academia solo tiene 4 niveles?"* $\rightarrow$ aprobación del currículo expandido de **10 Niveles + Generador Infinito de Retos**), esta **Fase 03** construye el sistema pedagógico y de entrenamiento táctico completo en `lib/academy/` e integra su interfaz interactiva en `lib/ui/`:
1. **Currículo Estructurado de 10 Niveles (`lib/academy/academy_curriculum.dart`):**
   - **Nivel 1 — Iniciación y Lectura Diagonal:** Movimiento de peón, captura simple, captura en cadena y coronación.
   - **Nivel 2 — Dominio del Reglamento y Variantes Mundiales:** La Dama Voladora, el Obstáculo Turco, cómo usar la Ley de Cantidad y Calidad a tu favor, el Soplido, coronación rusa en salto y captura ortogonal turca.
   - **Nivel 3 — Aperturas Sólidas y "La Fila Real":** Control del centro en apertura, defensa de la Fila Base (Fila Real), estructura en pirámide y castigo a aperturas débiles.
   - **Nivel 4 — Tácticas de Ataque I (Golpes Cortos):** *El Golpe 2-por-1 (Sacrificio Básico)*, *La Horquilla Diagonal (Doble Amenaza)*, *La Clavada* y *El Ataque a la Descubierta*.
   - **Nivel 5 — Tácticas de Ataque II (Trampas y Desviaciones):** *El Golpe de Rebote (Boomerang)*, *La Celada de Coronación Falsa*, *Sacrificio de Desviación* y *La Escalera (1-por-3)*.
   - **Nivel 6 — Golpes Clásicos de Torneo:** *El Golpe Polaco (Coup Polonais)*, *El Golpe de Talón*, *El Golpe Real* y *La Red de Captura Múltiple*.
   - **Nivel 7 — Estrategia Posicional Profunda:** *Dominio de las 4 Casillas Centrales*, *Control de la Gran Diagonal*, *Ataque a Peones Aislados*, *Conteo de Tiempos (Tempi)* y *Zugzwang*.
   - **Nivel 8 — El Arte del Bloqueo y "La Oposición":** Cálculo de *La Oposición (1v1 y 2v2)*, *El Candado de Flanco* y victoria por *Ahogado/Encerramiento*.
   - **Nivel 9 — Finales Técnicos de Maestro:** *2 Damas vs 1 Dama*, *El Triángulo de Petrov (3 Damas vs 1 Dama)* y *Defensa de Tablas en inferioridad*.
   - **Nivel 10 — Gran Maestro + Laboratorio de Combinaciones Profundas:** Combinaciones de cálculo de alto nivel conectadas con el Generador Infinito de Retos.
2. **Generador Infinito de Retos Tácticos Procedimentales (`lib/academy/infinite_puzzle_generator.dart`):**
   - Construye problemas tácticos nuevos de forma determinista o por semilla (`seed`), y convierte los errores críticos (`BlunderRecord`) de las partidas del propio usuario en ejercicios personalizados verificados con `AlphaBetaSolver`.
3. **Entrenador Táctico en Tiempo Real / Modo Coach (`lib/academy/tactical_coach.dart`):**
   - Analiza cualquier estado del tablero (`BoardState`) durante una partida o lección y devuelve una recomendación pedagógica explicada (`CoachAdvice`: jugada sugerida, nombre de la técnica táctica involucrada —ej. *"Golpe 2-por-1"*, *"Defensa de Fila Real"*, *"Dominio de la Gran Diagonal"*, *"Captura Máxima por Ley de Cantidad"*— y razón estratégica).
4. **Interfaz Móvil de la Academia y Botón Coach (`lib/ui/academy_sheet.dart`, `game_controller.dart`, `board_screen.dart`):**
   - El chip de la Academia en `board_screen.dart` pasa a estar **100% activo**, abriendo el selector interactivo de los **10 Niveles**, cargando las posiciones de práctica directamente sobre el tablero para que el jugador las resuelva, validando si la jugada realizada es la correcta y sumando un botón de **Entrenador (Coach)** en la barra superior.

---

## 2. User Review Required (Decisiones y Alertas del Supervisor)

> [!IMPORTANT]
> Todos los ejercicios de los **10 Niveles** utilizan posiciones reales y legales construidas sobre `BoardState.custom`, de modo que el usuario practica directamente en el tablero interactivo y recibe validación inmediata de si encontró la jugada maestra o si debe intentar de nuevo con pista pedagógica.

## 2.1. Open Questions y Honestidad Epistémica
> [!NOTE]
> * **Sin dudas pendientes:** El Supervisor aprobó expresamente la estructura de **10 Niveles + Generador Infinito de Retos**.

---

## 3. Las 6 Capas Modulares de Ingeniería

1. **Máquina de Estados y Ciclo de Vida:**
   * Modo Academia en `GameController`: `freePlay` vs `academyLessonActive`. Cuando hay una lección o reto infinito activo, cada jugada del usuario se contrasta contra la solución táctica esperada (`expectedMove`) o la mejor jugada de `AlphaBetaSolver`.
2. **Casos Borde y Defensa (*Negative Space Programming*):**
   * `assert(levels.length == 10, 'El currículo debe contener exactamente los 10 niveles aprobados')`.
   * `assert` en cada `TacticalLesson` garantizando que el tablero del ejercicio no sea terminal y que la jugada solución sea legal según `MoveGenerator`.
3. **Persistencia e Integridad:**
   * Registro en memoria de lecciones completadas (`completedLessonIds`) y contador de retos infinitos resueltos (`infinitePuzzlesSolved`).
4. **Seguridad y Permisos:**
   * 100% local en Dart puro sin dependencias externas.
5. **Observabilidad y Errores:**
   * Retroalimentación inmediata en el banner UI: si el estudiante mueve una pieza distinta a la combinación ganadora, muestra el estado `Error Humano` explicando la pista táctica sin avanzar el tablero, permitiéndole intentar de inmediato.
6. **Estrategia de Testing:**
   * Suite `test/f03_academy_test.dart` + script verificador `scripts/verify_f03.py` (junto con no-regresión en `verify_f01.py` y `verify_f02.py`).

---

## 4. Alcance Delimitado

### INCLUYE
* [ ] Modelos pedagógicos y catálogo de los **10 Niveles** (`lib/academy/academy_models.dart`, `lib/academy/academy_curriculum.dart`).
* [ ] **Generador Infinito de Retos Tácticos** (`lib/academy/infinite_puzzle_generator.dart`).
* [ ] **Entrenador Táctico en Tiempo Real (Coach)** (`lib/academy/tactical_coach.dart`, `lib/academy/academy_engine.dart`).
* [ ] Interfaz de Academia y Coach en `lib/ui/academy_sheet.dart`, `lib/ui/game_controller.dart` y `lib/ui/board_screen.dart`.
* [ ] Pruebas unitarias en `test/f03_academy_test.dart` y verificador `scripts/verify_f03.py`.

### NO INCLUYE
* Archivos de configuración de firma Android y guía de publicación en Google Play Store (correspondientes a la **Fase 04** de cierre).

---

## 5. Cambios Físicos Propuestos (Proposed Changes)

### Capa de Academia y Entrenador (`lib/academy/`)
* **[NEW]** `/home/antigravity/juego_de_damas/lib/academy/academy_models.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/lib/academy/academy_curriculum.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/lib/academy/infinite_puzzle_generator.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/lib/academy/tactical_coach.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/lib/academy/academy_engine.dart`

### Capa de Interfaz Móvil (`lib/ui/`)
* **[NEW]** `/home/antigravity/juego_de_damas/lib/ui/academy_sheet.dart`
* **[MODIFY]** `/home/antigravity/juego_de_damas/lib/ui/game_controller.dart` y `lib/ui/board_screen.dart`

### Pruebas y Verificación (`test/` y `scripts/`)
* **[NEW]** `/home/antigravity/juego_de_damas/test/f03_academy_test.dart`
* **[NEW]** `/home/antigravity/juego_de_damas/scripts/verify_f03.py`

---

## 6. Plan de Verificación Empírica (Verification Plan)

```bash
python3 /home/antigravity/juego_de_damas/scripts/verify_f01.py && \
python3 /home/antigravity/juego_de_damas/scripts/verify_f02.py && \
python3 /home/antigravity/juego_de_damas/scripts/verify_f03.py
```

---

## 7. Criterios de Aceptación Innegociables (`CA-xxx`)

* [ ] `CA-301`: `AcademyCurriculum` define exactamente los **10 niveles progresivos** (de Nivel 1 Iniciación a Nivel 10 Gran Maestro) con técnicas con nombre propio y tableros interactivos legales (`RF-006`, `RN-008`).
* [ ] `CA-302`: `InfinitePuzzleGenerator` genera retos tácticos dinámicos por semilla y a partir de errores (`BlunderRecord`) verificados por `AlphaBetaSolver`.
* [ ] `CA-303`: `TacticalCoach` analiza cualquier posición en tiempo real y explica en español qué técnica táctica aplica y cuál es la jugada recomendada.
* [ ] `CA-304`: `verify_f01.py`, `verify_f02.py` y `verify_f03.py` pasan con `0 errores` y `exit code 0` respetando Guard Clauses ($\le 2$) y *Negative Space Programming*.

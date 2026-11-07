# REGISTRO DE DECISIONES DE ARQUITECTURA (ADR)

* **Proyecto:** Juego de Damas
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-07`)

---

## DEC-001: Inicialización bajo GEM V4.0 (Track LEAN)
* **Fecha:** 2026-11-06
* **Estado:** APROBADA
* **Contexto:** Se requiere estructurar el desarrollo de un juego móvil de Damas con IA competitiva, aprendizaje local y academia pedagógica bajo principios de simplicidad, honestidad epistémica y separación de juez y parte.
* **Decisión:** Adoptar el marco GEM V4.0 en modalidad LEAN.
* **Consecuencias:** Se aplican Vertical Slices pragmáticas, compuertas preventivas de subagentes (`P-33` y `P-14`) y *Negative Space Programming*.

---

## DEC-002: Stack Flutter / Dart con Dominio Puro Desacoplado
* **Fecha:** 2026-11-06
* **Estado:** APROBADA
* **Contexto:** El Supervisor desea una aplicación móvil para Android (con miras a Google Play Store) desarrollada en código **Flutter / Dart** para compilarla posteriormente en su PC.
* **Decisión:** Estructurar el proyecto Flutter en módulos por Vertical Slices donde el motor de reglas, el motor de IA y el motor de lecciones tácticas estén escritos en **Dart puro (100% libre de dependencias de UI de Flutter)** y la IA pesada se ejecute mediante `Isolate`.
* **Consecuencias:**
  1. La interfaz móvil corre a 60/120 FPS sin bloqueos.
  2. El motor de reglas, la IA y los escenarios de aprendizaje son deterministas y 100% testeables de forma unitaria.

---

## DEC-003: Arquitectura de IA Híbrida (Alfa-Beta + TD-Learning & Perfilado de Rival On-Device)
* **Fecha:** 2026-11-06
* **Estado:** APROBADA
* **Contexto:** Se requiere una máquina que sea **muy competitiva desde la primera partida** pero que además **aprenda ella misma de sus rivales** jugando localmente en el celular sin requerir servidores ni GPUs.
* **Decisión:** Implementar un motor de dos capas:
  1. **Capa Táctica (Fuerza Bruta Inteligente):** Minimax con Poda Alfa-Beta, Iterative Deepening, Move Ordering, Quiescence Search y Tabla de Transposición con **Zobrist Hashing**.
  2. **Capa de Aprendizaje Adaptativo Local:** Actualización de Pesos por Diferencias Temporales (TD-Learning ligero) + Libro de Contramedidas del Rival (Opponent Pattern Book) persistido en JSON local.
* **Consecuencias:** La máquina juega a nivel experto desde el día 1 y adapta sus pesos y aperturas al estilo específico del jugador humano.

---

## DEC-004: Motor Pedagógico de Academia por Niveles y Entrenador Táctico (Coach)
* **Fecha:** 2026-11-06
* **Estado:** APROBADA
* **Contexto:** El Supervisor solicitó incorporar una modalidad de aprendizaje estructurada por niveles que enseñe a las personas cómo se juega y qué técnicas tácticas/estratégicas aplicar para ganar.
* **Decisión:** Diseñar un módulo de **Academia Táctica (`lib/academy/`)** basado en:
  1. **Currículo de 4 Niveles Progresivos (`AcademyLevel` & `TacticalLesson`):** Escenarios de tablero preconfigurados con secuencia de jugadas objetivo, explicación teórica previa, pistas escalonadas y explicación del error cuando el estudiante realiza una jugada subóptima.
  2. **Entrenador en Tiempo Real (`TacticalCoach`):** Analizador pedagógico que evalúa la posición actual y traduce la ventaja táctica del motor en lenguaje humano comprensible (ej. *"Conserva tu fila base"*, *"Fuerza captura obligatoria para hacer un 2-por-1"*, *"Domina la Gran Diagonal con tu Dama"*).
* **Consecuencias:** El juego no solo entretiene como rival competitivo, sino que forma verdaderos jugadores de Damas Españolas paso a paso.

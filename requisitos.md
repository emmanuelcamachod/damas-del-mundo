# CATÁLOGO DE REQUISITOS: Juego de Damas

* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-04` / `P-17`)
* **Estado:** APROBADO POR EL SUPERVISOR (2026-11-06)

---

## REQUISITOS FUNCIONALES (RF)

| ID | Nombre | Descripción | Criterio de Aceptación (BDD) | Estado |
| :---: | :--- | :--- | :--- | :---: |
| **RF-001** | Motor Multivariante ("Damas del Mundo") y Soplido | Motor paramétrico (`CheckersRuleset`) que soporta las 7 variantes mundiales (Española 8x8, Brasileña 8x8, Inglesa 8x8, Rusa 8x8, Italiana 8x8, Internacional 10x10 y Turca 8x8 ortogonal) y el interruptor opcional de la Regla del Soplido. | **Dado** cualquier `CheckersRuleset` seleccionado **Cuando** se solicitan las jugadas legales o se aplica el Soplido **Entonces** el motor valida dimensiones (8x8 o 10x10), alcance de Dama, dirección de captura, leyes de cantidad/calidad y retiro por soplido sin errores. | APROBADO |
| **RF-002** | Búsqueda Táctica Alfa-Beta Multivariante | Motor de decisión competitivo basado en Minimax con Poda Alfa-Beta, profundización iterativa, Quiescence Search y tabla de transposición Zobrist compatible con todas las variantes y con el Soplido. | **Dado** el turno de la máquina **Cuando** el motor evalúa la posición en un `Isolate` **Entonces** retorna una jugada maestra (y decide si ejecutar un Soplido previo cuando aplique) dentro del presupuesto de tiempo. | APROBADO |
| **RF-003** | Aprendizaje Adaptativo Local + ADN del Jugador | Sistema de aprendizaje en dispositivo (TD-Learning + Libro de Patrones del Rival) acompañado de un analizador del **ADN del Jugador** (agresividad, defensa de fila base, flanco preferido, vulnerabilidad táctica). | **Dado** el término de una partida contra el humano **Cuando** se ejecuta el aprendizaje **Entonces** la IA ajusta sus pesos heurísticos, actualiza el libro de aperturas y recalcula la tarjeta de ADN del Jugador. | APROBADO |
| **RF-004** | Detector de Errores Críticos (Blunder Replay) | Analizador de caídas de evaluación que detecta el momento crítico donde el jugador humano cometió un error grave, explica la jugada óptima omitida y permite rebobinar la partida a ese turno exacto. | **Dado** que el usuario comete un error que cambia drásticamente la evaluación **Cuando** consulta el análisis o termina la partida **Entonces** puede pulsar *"Reintentar desde mi Error"* y restaurar el tablero en ese turno con la pista explicada. | APROBADO |
| **RF-005** | Interfaz Móvil Multivariante y Termómetro de Ventaja | Pantalla en Flutter adaptable a tableros 8x8 y 10x10, selector de las 7 variantes mundiales, interruptor de Soplido, barra de ventaja táctica, panel de ADN/IA y botón de Soplar pieza infractora. | **Dado** el turno del jugador **Cuando** interactúa con el tablero, el selector de variante o el botón de Soplido **Entonces** la UI responde respetando los 5 estados visuales y accesibilidad WCAG AA. | APROBADO |
| **RF-006** | Academia Interactiva de 10 Niveles + Generador Infinito + Coach | Modalidad de aprendizaje estructurada en **10 niveles progresivos** (Iniciación, Reglamento/Variantes, Aperturas/Fila Real, Tácticas I, Tácticas II, Golpes de Torneo, Estrategia Posicional, Bloqueo/Oposición, Finales de Maestro y Gran Maestro) más un **Generador Infinito de Retos Tácticos** y **Entrenador (Coach)** en tiempo real. | **Dado** que el jugador ingresa a cualquiera de los 10 niveles, genera un reto infinito o pide pista al Coach **Cuando** interactúa con la posición en el tablero **Entonces** el sistema explica la técnica con nombre propio, valida la jugada ganadora y registra su maestría. | APROBADO |

---

## REQUISITOS NO FUNCIONALES (RNF)

| ID | Categoría | Requisito / Métrica Objetivo | Estado |
| :---: | :--- | :--- | :---: |
| **RNF-001** | Rendimiento Móvil | 60 FPS constantes en UI; cálculo de IA ejecutado en `Isolate` separado con tiempo de respuesta configurable (ej. 300ms–1200ms por jugada). | OBLIGATORIO |
| **RNF-002** | Offline-First & Privacidad | 100% funcional sin conexión a internet; cero secretos en código fuente y almacenamiento estrictamente local en el dispositivo Android. | OBLIGATORIO |
| **RNF-003** | Calidad de Código y Negative Space | Guard Clauses (anidación máxima de 2 niveles), SLAP y aserción explícita de invariantes de dominio (`assert`) sin ocultar errores con `?.` o `??` pasivos. | OBLIGATORIO |
| **RNF-004** | UI/UX Móvil (`05_CALIDAD/ui_ux.md`) | Gestión explícita de los 5 estados visuales (`Loading`, `Empty`, `Error Humano`, `Success`, `Disabled`), áreas táctiles $\ge 44/48\text{dp}$ y contraste WCAG AA (≥4.5:1). | OBLIGATORIO |

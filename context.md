# CONTEXTO DEL PROYECTO: Juego de Damas ("Damas del Mundo + IA Némesis + Academia 10 Niveles")

* **Fecha de Creación:** 2026-11-06
* **Última Actualización (`P-17`):** 2026-11-06
* **Tipo de Proyecto:** greenfield
* **Modalidad Metodológica:** Track LEAN
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-01` / `P-02` / `P-17`)

---

## 1. PROPÓSITO Y VISIÓN
Construir la aplicación móvil definitiva de Damas en **Flutter / Dart** (orientada a **Android / Google Play Store**, 100% offline-first), integrando tres pilares diferenciadores en el mercado global:
1. **Motor Multivariante "Damas del Mundo" + Regla Tradicional del "Soplido":**
   * Soporte nativo y paramétrico (`CheckersRuleset`) para las **7 grandes variantes mundiales**: Española (8x8), Brasileña (8x8), Inglesa/Americana (8x8), Rusa/Shashki (8x8), Italiana (8x8), Internacional/FMJD (10x10) y Turca Ortogonal (8x8).
   * Interruptor opcional de **"La Regla del Soplido"** (`allowHuffing`).
2. **Motor de Inteligencia Artificial Híbrido ("Némesis Local") + ADN del Jugador + Detector de Errores:**
   * **Motor Táctico Maestro:** Minimax con Poda Alfa-Beta, Move Ordering, Iterative Deepening, Quiescence Search y tablas de transposición Zobrist en `Isolate`.
   * **Aprendizaje Adaptativo Local (TD-Learning & Opponent Pattern Book):** Ajusta sus pesos heurísticos tras cada partida y memoriza las aperturas del jugador humano.
   * **Radiografía "ADN del Jugador" y Detector de Errores ("Reintentar desde mi Error").**
3. **Academia Interactiva de 10 Niveles (Novato a Gran Maestro) + Generador Infinito de Retos + Entrenador (Coach):**
   * Currículo estructurado en **10 Niveles Progresivos**:
     - **Nivel 1:** Iniciación y Lectura Diagonal.
     - **Nivel 2:** Dominio del Reglamento y Variantes Mundiales.
     - **Nivel 3:** Aperturas Sólidas y "La Fila Real".
     - **Nivel 4:** Tácticas de Ataque I (*Golpe 2-por-1*, *Horquilla Diagonal*, *Clavada*, *Ataque a la Descubierta*).
     - **Nivel 5:** Tácticas de Ataque II (*Golpe de Rebote*, *Celada de Coronación Falsa*, *Sacrificio de Desviación*, *La Escalera 1-por-3*).
     - **Nivel 6:** Golpes Clásicos de Torneo (*Golpe Polaco*, *Golpe de Talón*, *Golpe Real*, *Red de Captura Múltiple*).
     - **Nivel 7:** Estrategia Posicional Profunda (*4 Casillas Centrales*, *Gran Diagonal*, *Peones Aislados*, *Tempi* y *Zugzwang*).
     - **Nivel 8:** El Arte del Bloqueo y "La Oposición" (*Oposición 1v1 y 2v2*, *Candado de Flanco*, *Ahogado*).
     - **Nivel 9:** Finales Técnicos de Maestro (*2 Damas vs 1 Dama*, *Triángulo de Petrov 3v1*, *Defensa de Tablas*).
     - **Nivel 10:** Gran Maestro + **Generador Infinito de Retos Tácticos Procedimentales** (crea retos nuevos en vivo usando el motor Alfa-Beta y los errores reales del jugador).
   * **Entrenador en Partida (Modo Coach):** Botón que explica la jugada óptima y el principio táctico activo en cualquier turno.

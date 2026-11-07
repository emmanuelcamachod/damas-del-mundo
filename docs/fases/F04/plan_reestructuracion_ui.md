# PLAN DE REESTRUCTURACIÓN UI/UX Y ANIMACIONES (GEM V4.0 + SKILL FRONTEND-DESIGN)

* **Proyecto:** Damas del Mundo: Némesis IA (`juego_de_damas`)
* **Hito:** Reestructuración de Experiencia Visual, Animaciones Cinematográficas de Mate/Coronación y Diseño de Élite (Anti-"AI Slop").
* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (`P-09`, `P-33`, `P-14` + skills `frontend-design` y `token-sentinel-compress`).
* **Fecha:** 2026-11-06

---

## 1. OBJETIVO DE LA REESTRUCTURACIÓN

Elevar la interfaz de usuario de "funcional" a **"grado de producción premium con deleite visual"**:
1. **Animación y Celebración de Victoria ("Mate de la Dama" / Jaque Mate de Damas):**
   - Detección precisa en `GameController` cuando una partida concluye con victoria (`GameStatus.whiteWins` / `GameStatus.blackWins`).
   - Modal/Overlay cinematográfico interactivo con partículas animadas, trofeo de rango y corona dorada brillante, efectos de sonido/vibración háptica simulada y opciones inmediatas:
     - *"Revancha Inmediata"*
     - *"Analizar mis Errores con el Coach"*
     - *"Ver Radiografía de mi ADN Táctico"*
2. **Animaciones Visuales en el Tablero (`lib/ui/board_screen.dart`):**
   - **Coronación a Dama:** Animación de escala y destello dorado (`TweenAnimationBuilder<double>`) en la casilla cuando un peón corona a Dama (`promotesToKing`).
   - **Fichas Premium:** Renderizado de fichas con biselado 3D, sombras de elevación, textura y corona real tallada (sustituyendo el círculo plano simple).
   - **Casillas Táctiles:** Resaltado fluido con animaciones de pulso suave en casillas de captura obligatoria y casillas sugeridas por el Entrenador Táctico (Cian brillante).
3. **Actualización del Simulador Web Interactivo (`simulador_damas_gem_v4.html`):**
   - Efecto de celebración con confetti / partículas en Canvas cuando hay victoria ("Mate").
   - Animación de rebote y corona en las Damas.
   - Sonidos y retroalimentación táctil visual premium.

---

## 2. CRITERIOS DE ACEPTACIÓN (`CA-UI-01` .. `CA-UI-04`)

* **`CA-UI-01` (Celebración de Victoria / Mate):** Al alcanzarse un estado terminal de victoria, se despliega automáticamente un diálogo o panel de celebración animado con resumen de la partida (piezas capturadas, jugadas realizadas y cambio en pesos TD-Learning).
* **`CA-UI-02` (Animación de Coronación y Fichas 3D):** Las fichas coronadas se destacan con animación de pulso y corona dorada con elevación.
* **`CA-UI-03` (Cumplimiento de `frontend-design`):** Respeta los 5 estados visuales (Loading, Empty, Error, Success, Disabled), contraste WCAG AA y ergonomía táctil ($\ge 48\text{dp}$).
* **`CA-UI-04` (RNF-003 Calidad GEM V4.0):** Anidamiento máximo de control $\le 2$ en todos los archivos `.dart` modificados y suites de verificación en verde (`EXIT CODE 0`).

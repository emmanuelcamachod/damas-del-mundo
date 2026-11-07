# ROADMAP Y FASES: Juego de Damas

* **Metodología:** GEM PROYECTOS SOFTWARE V4.0 (Track LEAN — `P-09` / `P-16`)

---

## MATRIZ DE FASES (VERTICAL SLICES)

| Fase | Nombre | Objetivo Central | Entregables Clave | Estado | Dictamen Fiscal |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **F00** | Descubrimiento y Arquitectura | Definir contexto, reglas multivariante, requisitos BDD (IA Adaptativa, ADN, Blunder Replay y Academia) y roadmap. | `context.md`, `requisitos.md`, `reglas_negocio.md`, `decisiones.md`, `roadmap.md` | **COMPLETADA** | Aprobado Supervisor |
| **F01** | Rebanada Vertical 1: Motor Base 8x8 y Tablero Jugable | Implementar el núcleo inicial de Damas Españolas 8x8, tablero móvil con los 5 estados visuales y suite base. | `lib/domain/checkers_engine.dart`, `lib/ui/board_screen.dart`, `test/checkers_engine_test.dart`, `docs/fases/F01/auditoria_fiscal_F01.md` | **COMPLETADA** | **`APROBADA (P-14)`** |
| **F02** | Rebanada Vertical 2: Expansión Multivariante Mundial + Soplido + Motor IA Híbrido + ADN y Detector de Errores | Expandir el dominio a las **7 variantes mundiales (8x8 y 10x10) + Regla del Soplido**, e implementar el **Motor IA Alfa-Beta + Aprendizaje Adaptativo TD-Learning + Perfil ADN del Jugador + Detector de Errores ("Reintentar desde mi Error")**. | `lib/domain/ruleset.dart`, `lib/ai/alpha_beta_solver.dart`, `lib/ai/adaptive_learner.dart`, `lib/ai/player_dna.dart`, `lib/ai/blunder_detector.dart`, `lib/ui/ai_dna_sheet.dart`, `test/f02_multivariant_ai_test.dart`, `docs/fases/F02/auditoria_fiscal_F02.md` | **COMPLETADA** | **`APROBADA (P-14)`** |
| **F03** | Rebanada Vertical 3: Academia Interactiva de 10 Niveles + Generador Infinito de Retos + Coach Táctico | Implementar los **10 niveles progresivos** (Novato a Gran Maestro) con técnicas con nombre propio (*Golpe 2-por-1*, *Horquilla*, *Escalera*, *Golpe Polaco*, *Golpe Real*, *Zugzwang*, *La Oposición*, *Triángulo de Petrov*), **Generador Infinito de Retos Tácticos** (por semilla y desde errores reales) y **Entrenador Táctico en Tiempo Real**. | `lib/academy/academy_curriculum.dart`, `lib/academy/infinite_puzzle_generator.dart`, `lib/academy/tactical_coach.dart`, `lib/academy/academy_engine.dart`, `lib/ui/academy_sheet.dart`, `test/f03_academy_test.dart`, `docs/fases/F03/auditoria_fiscal_F03.md` | **COMPLETADA** | **`APROBADA (P-14)`** |
| **F04** | Rebanada Vertical 4: Pulido Android / Play Store y Cierre | Configuración de manifiesto Android, persistencia JSON en disco, íconos/temas, guía paso a paso para compilar `.apk`/`.aab` y publicar en Google Play Store, y auditoría integral de cierre (`P-14` / `P-16`). | `android/`, `lib/storage/local_storage_service.dart`, `GUIA_PLAY_STORE.md`, auditoría fiscal completa | **SIGUIENTE FASE** | Pendiente |

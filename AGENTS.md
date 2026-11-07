# GOBERNANZA DEL PROYECTO — GEM V4.0

Este proyecto se concibe, diseña, planifica, ejecuta y audita bajo el marco **GEM PROYECTOS SOFTWARE V4.0** (100% retrocompatible con GEM V1, V2 y V3).
* **Modalidad Activa:** Track LEAN (Proporcionalidad metodológica activa).

## 1. MARCO METODOLÓGICO VINCULANTE
* **Metodología Canónica:** Skill Global `gem-v4` (o `gem-v3` / `/home/antigravity/mtorv3/documentos`)
* **Modelo de Operación:** Arquitectura Bipolar (2 Roles):
  * **SUPERVISOR:** Autoridad humana final (aprueba alcance, reglas, arquitectura y fases).
  * **ANTIGRAVITY:** Sistema Autónomo Multi-Agente (Arquitecto + Fiscal Técnico + Ejecutor Físico).

## 2. REGLAS INNEGOCIABLES DE INGENIERÍA
1. **No Code First & Pre-Auditoría de Planes (P-11 / P-33 - Compuerta Preventiva):**
   - Prohibido escribir código sin plan aprobado por el Supervisor.
   - Al formular el borrador de un Plan de Implementación (`implementation_plan.md`):
     * PROHIBIDO solicitar la firma del Supervisor sin convocar antes al Fiscal de Planes.
     * EN EL MISMO TURNO Y DE FORMA AUTOMÁTICA, Antigravity DEBE invocar:
       `invoke_subagent(Role: 'Fiscal de Planes y Arquitectura', TypeName: 'research', Prompt: 'Auditar borrador contra context.md, simplicidad y P-33...')`
     * Solo tras dictamen favorable de plan viable se presenta al Supervisor.
2. **Vertical Slices Pragmáticas:**
   - Organizar el código por features cohesionadas con co-locación directa (rutas, servicio, esquema y tests juntos).
   - Prohibido crear 4 subcapas abstractas (`domain/`, `application/`, etc.) para operaciones o CRUDs simples.
3. **Claridad y Simplicidad de Código (KISS & Boring Code):**
   - Patrón Guard Clauses: Salidas tempranas (`early returns`) obligatorias; anidación máxima de 2 niveles en funciones.
   - Nomenclatura semántica: Verbos de acción para funciones, sustantivos para entidades; cero abreviaturas crípticas (`usr`, `ctx_hndl`).
   - Principio SLAP: Funciones con un solo nivel de abstracción; no mezclar SQL o regex con orquestación de alto nivel.
4. **Estándares UI/UX (si el proyecto incluye interfaz de usuario):**
   - Enfoque agnóstico a librerías y componentes desacoplados.
   - Cumplir obligatoriamente los 5 estados visuales: Loading (skeletons), Empty State (orientado a acción), Error Humano (explicativo + reintento), Success (feedback no invasivo) y Disabled.
   - Accesibilidad WCAG AA: Contraste legible (≥4.5:1), foco de teclado visible y etiquetas accesibles en todos los controles.
5. **Auditoría Imparcial Mandatoria (Anti-Juez y Parte - Compuerta Obligatoria):**
   - Al finalizar el código y pruebas de cualquier fase, Antigravity DEBE invocar obligatoriamente a `invoke_subagent` (Fiscal Técnico, `P-14`/`P-33`) para auditar el `git diff` y las pruebas físicas en terminal. Sin llamada física a subagente, el dictamen es nulo.
6. **Mandato de Honestidad Epistémica y Duda Permitida (Regla del "No lo sé"):**
   - Cuando la evidencia sea débil, ambigua o inexistente sobre cualquier aspecto del proyecto, Antigravity y sus subagentes DEBEN decir explícitamente "No lo sé / Evidencia insuficiente sobre [caso]" y preguntar directamente al usuario final antes de continuar.
   - Prohibido formular respuestas completas que suenen convincentes si no se basan en evidencia verificable en el repositorio o confirmada por el usuario. La duda está permitida y promovida en lugar de fingir certidumbre absoluta.
7. **Programación de Espacio Negativo e Invariantes Explícitas (Negative Space Programming):**
   - Cuando en un punto del flujo el modelo mental y las reglas de dominio exigen que un valor o condición exista (por ejemplo, `foo.bar` debe ser un número aunque la firma admita `bar?: number`), queda PROHIBIDO enmascarar silenciosamente el caso con coalescencia nula complaciente (`?? fallback`), encadenamiento opcional (`?.`) o retornos vacíos pasivos.
   - Todo agente y subagente DEBE programar las invariantes de forma explícita mediante aserciones fuertes (`assert(foo.bar !== undefined, "foo.bar must exist")` / `invariant(...)`).
   - Principio: *Programar el espacio negativo para garantizar el comportamiento*. Si el programa falla, expone de inmediato si la concepción del dominio era errónea o si existe un bug que demanda solución inmediata.

## 3. FUENTES DE VERDAD LOCALES
* `context.md` → Visión, arquitectura y problema de negocio.
* `estado_actual.md` → Situación técnica y hito presente.
* `roadmap.md` → Desglose de fases y ruta crítica.
* `requisitos.md` → Catálogo de requisitos (`RF-xxx`, `RNF-xxx`).
* `reglas_negocio.md` → Políticas y fórmulas del negocio (`RN-xxx`).
* `decisiones.md` → Registro de decisiones arquitectónicas (`DEC-xxx`).
* `GEM_ESTADO.json` → Estado de compuertas y métricas sincronizado.

## 4. COMANDOS DE VERIFICACIÓN
* Instalar dependencias: comando del stack elegido
* Ejecutar tests: suite de pruebas local
* Typecheck & Lint: linter configurado (`biome check` / `ruff check` / `golangci-lint run`)

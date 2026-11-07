# Damas del Mundo 🎯

Videojuego de Damas Internacional con IA adaptativa multivariante (reglas internacionales, españolas, inglesas y rusas), academia táctica con generador infinito de puzzles y arquitectura limpia en Flutter / Dart.

## Características

- **Motor de Reglas Multivariante**: Soporte para reglas internacionales (10x10), españolas, estándar americano (8x8) y variantes rusas.
- **IA Adaptativa (Player DNA)**: Sistema de IA con búsqueda Minimax / Alpha-Beta PVS, hashes Zobrist y transposición, con perfilado de debilidades del oponente.
- **Academia Táctica**: Generador procedural infinito de posiciones tácticas y entrenador interactivo.
- **Persistencia y Multiplataforma**: Almacenamiento local optimizado para Android, iOS y Web.
- **Simulador Interactivo**: Incluye simulador visual standalone en HTML5 / JavaScript (`juego_de_damas_simulador.html`).

## Estructura del Proyecto

```
damas-del-mundo/
├── lib/
│   ├── academy/          # Motor de entrenamiento táctico y puzzles
│   ├── ai/               # Motor de IA Alpha-Beta y perfiles cognitivos
│   ├── domain/           # Motor de reglas de damas y tipos
│   ├── storage/          # Persistencia local
│   └── ui/               # Vistas, tableros y controladores
├── test/                 # Batería de pruebas unitarias y de integración
├── scripts/              # Scripts de verificación y auditoría
└── docs/                 # Documentación de arquitectura y fases
```

## Ejecución de Pruebas

```bash
flutter test
```

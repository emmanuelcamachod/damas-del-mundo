// Catálogo de Cosméticos y Tableros Desbloqueables con Monedas Virtuales (GEM V4.0).
// Cumple Negative Space Programming y anidamiento <= 2.

import '../ui/game_controller.dart';

class CosmeticThemeItem {
  final BoardVisualTheme theme;
  final String name;
  final int coinPrice;
  final String description;
  final String iconEmoji;

  const CosmeticThemeItem({
    required this.theme,
    required this.name,
    required this.coinPrice,
    required this.description,
    required this.iconEmoji,
  }) : assert(coinPrice >= 0, 'El precio en monedas no puede ser negativo');

  bool get isFree => coinPrice == 0;

  static const List<CosmeticThemeItem> catalog = [
    CosmeticThemeItem(
      theme: BoardVisualTheme.classicWood,
      name: 'Nogal & Arce Imperial',
      coinPrice: 0,
      description: 'Ebanistería clásica de madera noble con vetas naturales.',
      iconEmoji: '🪵',
    ),
    CosmeticThemeItem(
      theme: BoardVisualTheme.tuscanLeather,
      name: 'Cuero Toscano & Oro',
      coinPrice: 2500,
      description: 'Badana repujada artesanal con pespunte perimetral de oro.',
      iconEmoji: '📜',
    ),
    CosmeticThemeItem(
      theme: BoardVisualTheme.luxuryMarble,
      name: 'Mármol Carrara & Ónix',
      coinPrice: 10000,
      description: 'Piedra pulida de alta competición con reflejos celestes.',
      iconEmoji: '🏛️',
    ),
    CosmeticThemeItem(
      theme: BoardVisualTheme.cyberNeon,
      name: 'Obsidiana Cíber 2077',
      coinPrice: 25000,
      description: 'Biselado de neón cian y matriz holográfica de vanguardia.',
      iconEmoji: '⚡',
    ),
    CosmeticThemeItem(
      theme: BoardVisualTheme.royalJade,
      name: 'Esmeralda & Jade Real',
      coinPrice: 50000,
      description: 'Gema imperial tallada con acentos de corona dorada suprema.',
      iconEmoji: '🐉',
    ),
  ];
}

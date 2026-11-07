// Catálogo de Paquetes de Monedas y Productos In-App (GEM V4.0).
// Cumple Negative Space Programming y anidamiento <= 2.

class CoinPackage {
  final String id;
  final String name;
  final int coinsAmount;
  final int bonusCoins;
  final double priceUsd;
  final String formattedPrice;
  final bool isPopular;
  final String iconEmoji;

  const CoinPackage({
    required this.id,
    required this.name,
    required this.coinsAmount,
    this.bonusCoins = 0,
    required this.priceUsd,
    required this.formattedPrice,
    this.isPopular = false,
    required this.iconEmoji,
  })  : assert(coinsAmount > 0, 'La cantidad de monedas debe ser positiva'),
        assert(priceUsd > 0, 'El precio debe ser mayor a 0');

  int get totalCoins => coinsAmount + bonusCoins;

  static const List<CoinPackage> catalog = [
    CoinPackage(
      id: 'pack_bronze_1200',
      name: 'Bolsa de Principiante',
      coinsAmount: 1200,
      bonusCoins: 0,
      priceUsd: 0.99,
      formattedPrice: '\$0.99 USD',
      iconEmoji: '🪙',
    ),
    CoinPackage(
      id: 'pack_silver_5000',
      name: 'Bolsa de Maestro',
      coinsAmount: 5000,
      bonusCoins: 750, // +15% extra
      priceUsd: 2.99,
      formattedPrice: '\$2.99 USD',
      isPopular: true,
      iconEmoji: '💰',
    ),
    CoinPackage(
      id: 'pack_gold_20000',
      name: 'Cofre de Campeón',
      coinsAmount: 20000,
      bonusCoins: 6000, // +30% extra
      priceUsd: 8.99,
      formattedPrice: '\$8.99 USD',
      iconEmoji: '🏆',
    ),
    CoinPackage(
      id: 'pack_diamond_100000',
      name: 'Tesoro Gran Maestro',
      coinsAmount: 100000,
      bonusCoins: 50000, // +50% extra
      priceUsd: 29.99,
      formattedPrice: '\$29.99 USD',
      iconEmoji: '👑',
    ),
  ];
}

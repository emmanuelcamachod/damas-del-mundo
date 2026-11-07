// Diálogo modal de Tienda de Monedas, Desbloqueo de Tableros y Recompensa Diaria (GEM V4.0).
// Cumple con WCAG AA, áreas táctiles >= 48dp y anidamiento <= 2.

import 'package:flutter/material.dart';
import '../economy/economy.dart';
import 'game_controller.dart';

class CoinShopDialog extends StatefulWidget {
  final GameController controller;

  const CoinShopDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showDialog<void>(
      context: context,
      builder: (_) => CoinShopDialog(controller: controller),
    );
  }

  @override
  State<CoinShopDialog> createState() => _CoinShopDialogState();
}

class _CoinShopDialogState extends State<CoinShopDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildDailyRewardBanner(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPacksTab(),
                      _buildThemesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                '${widget.controller.playerCoins} Monedas',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardBanner() {
    final canClaim = widget.controller.canClaimDailyReward;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: canClaim ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canClaim ? const Color(0xFF10B981) : const Color(0xFF334155),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recompensa Diaria',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    canClaim ? '+100 Monedas disponibles hoy' : 'Próxima recompensa mañana',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canClaim ? Colors.amber : const Color(0xFF475569),
              foregroundColor: Colors.black,
              minimumSize: const Size(80, 48),
            ),
            onPressed: canClaim ? widget.controller.claimDailyReward : null,
            child: const Text('Reclamar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white60,
      tabs: const [
        Tab(text: 'Comprar Monedas'),
        Tab(text: 'Desbloquear Tableros'),
      ],
    );
  }

  Widget _buildPacksTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: CoinPackage.catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pack = CoinPackage.catalog[index];
        return _buildPackItemCard(pack);
      },
    );
  }

  Widget _buildPackItemCard(CoinPackage pack) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pack.isPopular ? Colors.amber : const Color(0xFF334155),
          width: pack.isPopular ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(pack.iconEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pack.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (pack.isPopular) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('POPULAR', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${pack.totalCoins} Monedas ${pack.bonusCoins > 0 ? "(+${pack.bonusCoins} gratis)" : ""}',
                  style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(90, 48),
            ),
            onPressed: () => widget.controller.buyCoinPackage(pack),
            child: Text(pack.formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: CosmeticThemeItem.catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = CosmeticThemeItem.catalog[index];
        return _buildThemeItemCard(item);
      },
    );
  }

  Widget _buildThemeItemCard(CosmeticThemeItem item) {
    final isUnlocked = widget.controller.isThemeUnlocked(item.theme);
    final isEquipped = widget.controller.boardVisualTheme == item.theme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped ? const Color(0xFF38BDF8) : const Color(0xFF334155),
          width: isEquipped ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(item.iconEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  item.isFree ? 'Gratis de fábrica' : '${item.coinPrice} Monedas',
                  style: TextStyle(
                    color: item.isFree ? const Color(0xFF34D399) : Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildThemeActionButton(item, isUnlocked, isEquipped),
        ],
      ),
    );
  }

  Widget _buildThemeActionButton(CosmeticThemeItem item, bool isUnlocked, bool isEquipped) {
    if (isEquipped) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF38BDF8)),
          minimumSize: const Size(90, 48),
        ),
        onPressed: null,
        child: const Text('Equipado', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
      );
    }
    if (isUnlocked) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          minimumSize: const Size(90, 48),
        ),
        onPressed: () => widget.controller.setBoardVisualTheme(item.theme),
        child: const Text('Equipar', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        minimumSize: const Size(90, 48),
      ),
      onPressed: () => widget.controller.unlockThemeWithCoins(item),
      child: const Text('Comprar', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

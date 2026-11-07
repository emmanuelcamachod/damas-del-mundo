// Pantalla de Lobby y Menú Principal (GEM V4.0).
// Tarjetas de lujo: Jugar vs IA, Pasa y Juega, Salas Online con Monedas, Academia y Tienda.

import 'package:flutter/material.dart';
import '../ai/ai_engine.dart';
import '../auth/auth.dart';
import '../economy/economy.dart';
import '../multiplayer/multiplayer.dart';
import 'auth_screen.dart';
import 'board_screen.dart';
import 'coin_shop_dialog.dart';

class LobbyScreen extends StatefulWidget {
  final UserSession session;
  final AuthService authService;

  const LobbyScreen({
    super.key,
    required this.session,
    required this.authService,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late int _coins;
  late int _elo;
  bool _dailyRewardClaimed = false;
  AiDifficulty _selectedDifficulty = AiDifficulty.hard;

  @override
  void initState() {
    super.initState();
    _coins = widget.session.coins;
    _elo = widget.session.eloRating;
  }

  void _claimDailyReward() {
    if (_dailyRewardClaimed) return;
    setState(() {
      _coins += 100;
      _dailyRewardClaimed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF059669),
        content: Text('🎁 ¡Recompensa reclamada! +100 Monedas añadidas a tu saldo.'),
      ),
    );
  }

  void _openShop() {
    showDialog(
      context: context,
      builder: (_) => CoinShopDialog(
        currentCoins: _coins,
        canClaimDailyReward: !_dailyRewardClaimed,
        unlockedThemes: const [BoardVisualTheme.classicWood],
        onClaimDailyReward: _claimDailyReward,
        onBuyCoins: (pack) {
          setState(() => _coins += pack.coinAmount);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFF59E0B),
              content: Text('🪙 ¡Compra exitosa! +${pack.coinAmount} Monedas (${pack.priceUsd}) acreditadas.'),
            ),
          );
        },
        onUnlockTheme: (theme, price) {
          if (_coins < price) return;
          setState(() => _coins -= price);
        },
      ),
    );
  }

  void _startVsAi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BoardScreen()),
    );
  }

  void _startPassAndPlay() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BoardScreen()),
    );
  }

  void _startAcademy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BoardScreen()),
    );
  }

  void _showOnlineBetDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🌐 Salas de Apuesta Online',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('Saldo: $_coins 🪙', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              for (final tier in MatchmakingTier.allTiers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Text(tier.iconEmoji, style: const TextStyle(fontSize: 24)),
                    title: Text(tier.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Apuesta: ${tier.entryFee} 🪙', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (_coins < tier.entryFee) {
                          _openShop();
                          return;
                        }
                        setState(() => _coins -= tier.entryFee);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BoardScreen()),
                        );
                      },
                      child: Text('Gana ${tier.prizePool} 🪙', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await widget.authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthScreen(authService: widget.authService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: _buildLobbyAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUserProfileBanner(),
                const SizedBox(height: 12),
                _buildDailyRewardCard(),
                const SizedBox(height: 16),
                const Text(
                  'MODOS DE JUEGO',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  icon: '🤖',
                  title: 'Jugar vs IA Némesis',
                  subtitle: 'Motor Alfa-Beta P4 • ${_difficultyName(_selectedDifficulty)}',
                  accentColor: const Color(0xFF38BDF8),
                  onTap: _startVsAi,
                  trailing: _buildDifficultyChip(),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  icon: '🌐',
                  title: 'Partida Online con Apuesta',
                  subtitle: 'Salas de 50 a 5.000 🪙 • Servidor Supabase',
                  accentColor: const Color(0xFF10B981),
                  badge: 'ONLINE',
                  onTap: _showOnlineBetDialog,
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  icon: '👥',
                  title: 'Pasa y Juega (2 Jugadores)',
                  subtitle: 'Mismo celular cara a cara • 100% Offline',
                  accentColor: const Color(0xFFA855F7),
                  onTap: _startPassAndPlay,
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  icon: '🎓',
                  title: 'Academia de Damas & Retos',
                  subtitle: '10 Niveles tácticos + Generador infinito',
                  accentColor: const Color(0xFFF59E0B),
                  onTap: _startAcademy,
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  icon: '🪙',
                  title: 'Tienda de Tableros & Billetera',
                  subtitle: 'Desbloquea Mármol, Cuero, Cíber y Jade • Sin Anuncios',
                  accentColor: const Color(0xFFEAB308),
                  onTap: _openShop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildLobbyAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      title: const Row(
        children: [
          Text('👑 ', style: TextStyle(fontSize: 18)),
          Text('DAMAS DE ÉLITE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
      actions: [
        _buildCoinChip(),
        IconButton(
          tooltip: 'Cerrar Sesión',
          icon: const Icon(Icons.logout, size: 20, color: Color(0xFF94A3B8)),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildCoinChip() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        onPressed: _openShop,
        avatar: const Text('🪙', style: TextStyle(fontSize: 14)),
        label: Text(
          '$_coins +',
          style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildUserProfileBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1E293B),
            child: Text(
              widget.session.isGuest ? '👤' : '🏆',
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x3338BDF8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ELO $_elo', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.session.isGuest ? 'Modo Invitado' : 'Cuenta Verificada',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1A059669),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66059669)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text('🎁 ', style: TextStyle(fontSize: 20)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recompensa Diaria', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('+100 Monedas gratis cada 24h', style: TextStyle(color: Color(0xFF34D399), fontSize: 10)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dailyRewardClaimed ? const Color(0xFF334155) : const Color(0xFFF59E0B),
              foregroundColor: _dailyRewardClaimed ? const Color(0xFF94A3B8) : const Color(0xFF090D16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(80, 36),
            ),
            onPressed: _dailyRewardClaimed ? null : _claimDailyReward,
            child: Text(
              _dailyRewardClaimed ? 'Reclamado' : 'Reclamar',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    String? badge,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.arrow_forward_ios, size: 14, color: accentColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip() {
    return PopupMenuButton<AiDifficulty>(
      initialValue: _selectedDifficulty,
      tooltip: 'Cambiar Dificultad IA',
      onSelected: (d) => setState(() => _selectedDifficulty = d),
      itemBuilder: (_) => [
        for (final diff in AiDifficulty.values)
          PopupMenuItem(
            value: diff,
            child: Text(diff.displayName),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF38BDF8)),
        ),
        child: Text(
          _selectedDifficulty.displayName.split(' ').first,
          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _difficultyName(AiDifficulty d) {
    switch (d) {
      case AiDifficulty.easy:
        return 'Nivel Fácil (P1)';
      case AiDifficulty.medium:
        return 'Nivel Medio (P2)';
      case AiDifficulty.hard:
        return 'Nivel Difícil (P4)';
      case AiDifficulty.master:
        return 'Extra Difícil (P5/P6 + ADN)';
    }
  }
}

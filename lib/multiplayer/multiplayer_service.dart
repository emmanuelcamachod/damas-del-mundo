// Contrato abstracto desacoplado para servicios multijugador online (GEM V4.0).
// Permite intercambiar Supabase (BaaS) por un Servidor VPS propio con cero impacto en la UI.

import '../domain/checkers_types.dart';
import 'multiplayer_models.dart';

abstract class MultiplayerService {
  /// Obtiene o inicializa el perfil y saldo del jugador actual.
  Future<OnlinePlayerProfile> getOrCreatePlayerProfile();

  /// Busca una partida en espera o crea una nueva reteniendo la apuesta en Escrow.
  Future<OnlineMatchRoom> joinOrCreateMatch({
    required MatchmakingTier tier,
    required String rulesetId,
  });

  /// Flujo en tiempo real de movimientos enviados por el rival.
  Stream<CheckersMove> get onOpponentMove;

  /// Flujo en tiempo real del estado de la sala (conexión, rival encontrado, victoria).
  Stream<OnlineMatchRoom> get onRoomStateUpdated;

  /// Transmite un movimiento legal validado al rival a través del canal en tiempo real.
  Future<void> sendMove(String matchId, CheckersMove move);

  /// Abandona o concede la partida activa (da la victoria al rival por abandono).
  Future<void> resignMatch(String matchId);

  /// Cancela la búsqueda y reembolsa las monedas si aún no había rival.
  Future<void> cancelMatchmaking(String matchId);

  /// Cierra la conexión de tiempo real.
  void dispose();
}

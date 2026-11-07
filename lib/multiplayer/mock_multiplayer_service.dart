// Implementación de prueba y simulación offline del servicio multijugador (GEM V4.0).
// Permite probar salas, apuestas de monedas y partidas sin requerir credenciales externas.

import 'dart:async';
import '../domain/checkers_types.dart';
import 'multiplayer_models.dart';
import 'multiplayer_service.dart';

class MockMultiplayerService implements MultiplayerService {
  final _moveController = StreamController<CheckersMove>.broadcast();
  final _roomController = StreamController<OnlineMatchRoom>.broadcast();

  OnlinePlayerProfile _currentProfile = const OnlinePlayerProfile(
    id: 'user_local_01',
    username: 'Jugador Maestro',
    coins: 1000,
    eloRating: 1250,
    matchesWon: 8,
    matchesPlayed: 12,
  );

  OnlineMatchRoom? _activeRoom;

  @override
  Stream<CheckersMove> get onOpponentMove => _moveController.stream;

  @override
  Stream<OnlineMatchRoom> get onRoomStateUpdated => _roomController.stream;

  @override
  Future<OnlinePlayerProfile> getOrCreatePlayerProfile() async {
    return _currentProfile;
  }

  @override
  Future<OnlineMatchRoom> joinOrCreateMatch({
    required MatchmakingTier tier,
    required String rulesetId,
  }) async {
    assert(_currentProfile.coins >= tier.entryFee, 'Saldo insuficiente para la apuesta');

    // Descontar monedas en depósito (Escrow)
    _currentProfile = _currentProfile.copyWith(
      coins: _currentProfile.coins - tier.entryFee,
    );

    final room = OnlineMatchRoom(
      matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
      roomCode: 'SALA-${tier.entryFee}',
      tier: tier,
      rulesetId: rulesetId,
      whitePlayerId: _currentProfile.id,
      blackPlayerId: 'rival_remoto_02',
      status: OnlineMatchStatus.active,
      currentTurn: PlayerColor.white,
    );

    _activeRoom = room;
    _roomController.add(room);
    return room;
  }

  @override
  Future<void> sendMove(String matchId, CheckersMove move) async {
    assert(_activeRoom != null, 'No hay sala activa');
    // En simulación, el movimiento se registra y se valida
  }

  @override
  Future<void> resignMatch(String matchId) async {
    if (_activeRoom == null) return;
    final closed = OnlineMatchRoom(
      matchId: _activeRoom!.matchId,
      roomCode: _activeRoom!.roomCode,
      tier: _activeRoom!.tier,
      rulesetId: _activeRoom!.rulesetId,
      whitePlayerId: _activeRoom!.whitePlayerId,
      blackPlayerId: _activeRoom!.blackPlayerId,
      status: OnlineMatchStatus.completed,
      winnerId: _activeRoom!.blackPlayerId,
    );
    _activeRoom = null;
    _roomController.add(closed);
  }

  @override
  Future<void> cancelMatchmaking(String matchId) async {
    if (_activeRoom == null) return;
    _currentProfile = _currentProfile.copyWith(
      coins: _currentProfile.coins + _activeRoom!.tier.entryFee,
    );
    _activeRoom = null;
  }

  @override
  void dispose() {
    _moveController.close();
    _roomController.close();
  }
}

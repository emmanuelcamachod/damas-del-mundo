// Modelos de datos para el ecosistema Multijugador Online y Billetera de Monedas (GEM V4.0).
// Cumple con Negative Space Programming y anidamiento <= 2.

import '../domain/checkers_types.dart';

enum OnlineMatchStatus {
  waiting,
  active,
  completed,
  cancelled;

  static OnlineMatchStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'active':
        return OnlineMatchStatus.active;
      case 'completed':
        return OnlineMatchStatus.completed;
      case 'cancelled':
        return OnlineMatchStatus.cancelled;
      default:
        return OnlineMatchStatus.waiting;
    }
  }
}

class MatchmakingTier {
  final String id;
  final String name;
  final int entryFee;
  final int prizePool;
  final String iconEmoji;

  const MatchmakingTier({
    required this.id,
    required this.name,
    required this.entryFee,
    required this.prizePool,
    required this.iconEmoji,
  })  : assert(entryFee >= 0, 'La entrada no puede ser negativa'),
        assert(prizePool >= entryFee, 'El premio debe ser al menos igual a la entrada');

  static const List<MatchmakingTier> allTiers = [
    MatchmakingTier(
      id: 'wood_50',
      name: 'Mesa Nogal (Bronce)',
      entryFee: 50,
      prizePool: 90,
      iconEmoji: '🪵',
    ),
    MatchmakingTier(
      id: 'leather_250',
      name: 'Mesa Cuero (Plata)',
      entryFee: 250,
      prizePool: 450,
      iconEmoji: '📜',
    ),
    MatchmakingTier(
      id: 'marble_1000',
      name: 'Mesa Mármol (Oro)',
      entryFee: 1000,
      prizePool: 1800,
      iconEmoji: '🏛️',
    ),
    MatchmakingTier(
      id: 'jade_5000',
      name: 'Mesa Jade (Diamante)',
      entryFee: 5000,
      prizePool: 9000,
      iconEmoji: '🐉',
    ),
  ];
}

class OnlinePlayerProfile {
  final String id;
  final String username;
  final int coins;
  final int eloRating;
  final int matchesWon;
  final int matchesPlayed;

  const OnlinePlayerProfile({
    required this.id,
    required this.username,
    required this.coins,
    required this.eloRating,
    this.matchesWon = 0,
    this.matchesPlayed = 0,
  })  : assert(coins >= 0, 'El saldo de monedas no puede ser negativo'),
        assert(eloRating >= 100, 'El ELO no puede ser menor a 100');

  double get winRate {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon / matchesPlayed) * 100;
  }

  OnlinePlayerProfile copyWith({
    int? coins,
    int? eloRating,
    int? matchesWon,
    int? matchesPlayed,
  }) {
    return OnlinePlayerProfile(
      id: id,
      username: username,
      coins: coins ?? this.coins,
      eloRating: eloRating ?? this.eloRating,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    );
  }
}

class OnlineMatchRoom {
  final String matchId;
  final String roomCode;
  final MatchmakingTier tier;
  final String rulesetId;
  final String whitePlayerId;
  final String? blackPlayerId;
  final OnlineMatchStatus status;
  final PlayerColor currentTurn;
  final String? winnerId;

  const OnlineMatchRoom({
    required this.matchId,
    required this.roomCode,
    required this.tier,
    required this.rulesetId,
    required this.whitePlayerId,
    this.blackPlayerId,
    this.status = OnlineMatchStatus.waiting,
    this.currentTurn = PlayerColor.white,
    this.winnerId,
  });

  bool isUserWhite(String userId) => whitePlayerId == userId;
  bool isUserTurn(String userId) {
    if (currentTurn == PlayerColor.white) return whitePlayerId == userId;
    return blackPlayerId == userId;
  }
}

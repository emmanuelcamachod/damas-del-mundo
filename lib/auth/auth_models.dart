// Modelos inmutables para el sistema de autenticación y sesiones de usuario.
// Soporta autenticación con Correo, Google OAuth y Modo Invitado (Guest).

enum AuthProvider {
  email,
  google,
  guest,
}

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class UserSession {
  final String userId;
  final String email;
  final String displayName;
  final String avatarUrl;
  final AuthProvider provider;
  final int coins;
  final int eloRating;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.provider,
    required this.coins,
    required this.eloRating,
    required this.token,
  })  : assert(userId.length > 0, 'El ID de usuario no puede estar vacío'),
        assert(coins >= 0, 'El saldo de monedas no puede ser negativo'),
        assert(eloRating >= 100, 'El ELO no puede ser menor a 100');

  bool get isGuest => provider == AuthProvider.guest;

  UserSession copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    AuthProvider? provider,
    int? coins,
    int? eloRating,
    String? token,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      coins: coins ?? this.coins,
      eloRating: eloRating ?? this.eloRating,
      token: token ?? this.token,
    );
  }
}

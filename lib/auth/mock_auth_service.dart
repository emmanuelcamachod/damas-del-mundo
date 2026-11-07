// Implementación mock y local de autenticación para pruebas sin latencia de red.
// Soporta inicio de sesión instantáneo de prueba, Google simulado y modo invitado.

import 'dart:async';
import 'auth_models.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  final _sessionController = StreamController<UserSession?>.broadcast();
  UserSession? _currentSession;

  MockAuthService({UserSession? initialSession}) : _currentSession = initialSession;

  @override
  UserSession? get currentSession => _currentSession;

  @override
  Stream<UserSession?> get onAuthStateChanged => _sessionController.stream;

  @override
  Future<UserSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    assert(email.contains('@'), 'Correo electrónico no válido');
    assert(password.length >= 6, 'La contraseña debe tener al menos 6 caracteres');

    final name = email.split('@').first;
    _currentSession = UserSession(
      userId: 'mock_usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name.isNotEmpty ? name : 'Maestro de Damas',
      avatarUrl: '',
      provider: AuthProvider.email,
      coins: 1000,
      eloRating: 1200,
      token: 'mock_jwt_email_token',
    );
    _sessionController.add(_currentSession);
    return _currentSession!;
  }

  @override
  Future<UserSession> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    assert(email.contains('@'), 'Correo electrónico no válido');
    assert(password.length >= 6, 'La contraseña debe tener al menos 6 caracteres');
    assert(username.isNotEmpty, 'El nombre de usuario no puede estar vacío');

    _currentSession = UserSession(
      userId: 'mock_usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: username,
      avatarUrl: '',
      provider: AuthProvider.email,
      coins: 1000,
      eloRating: 1200,
      token: 'mock_jwt_signup_token',
    );
    _sessionController.add(_currentSession);
    return _currentSession!;
  }

  @override
  Future<UserSession> signInWithGoogle() async {
    _currentSession = UserSession(
      userId: 'google_usr_${DateTime.now().millisecondsSinceEpoch}',
      email: 'jugador.damas@gmail.com',
      displayName: 'Jugador Google',
      avatarUrl: 'https://lh3.googleusercontent.com/a/default-user',
      provider: AuthProvider.google,
      coins: 1000,
      eloRating: 1200,
      token: 'mock_google_oauth_token',
    );
    _sessionController.add(_currentSession);
    return _currentSession!;
  }

  @override
  Future<UserSession> signInAsGuest() async {
    final guestId = (1000 + DateTime.now().millisecond).toString();
    _currentSession = UserSession(
      userId: 'guest_$guestId',
      email: 'invitado_$guestId@damas.local',
      displayName: 'Invitado #$guestId',
      avatarUrl: '',
      provider: AuthProvider.guest,
      coins: 1000,
      eloRating: 1200,
      token: 'guest_session_token',
    );
    _sessionController.add(_currentSession);
    return _currentSession!;
  }

  @override
  Future<void> signOut() async {
    _currentSession = null;
    _sessionController.add(null);
  }
}

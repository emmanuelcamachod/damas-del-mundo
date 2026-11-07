// Interfaz desacoplada del servicio de autenticación (GEM V4.0).
// Permite alternar entre Supabase Auth, Firebase o Mock sin afectar la UI.

import 'auth_models.dart';

abstract class AuthService {
  UserSession? get currentSession;
  Stream<UserSession?> get onAuthStateChanged;

  Future<UserSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserSession> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  Future<UserSession> signInWithGoogle();

  Future<UserSession> signInAsGuest();

  Future<void> signOut();
}

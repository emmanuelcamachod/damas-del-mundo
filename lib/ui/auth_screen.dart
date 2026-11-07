// Pantalla de Autenticación y Registro (Email, Google y Modo Invitado).
// Diseñada bajo la metodología GEM V4.0 (Touch >= 48dp, WCAG AA, 5 Estados Visuales).

import 'package:flutter/material.dart';
import '../auth/auth.dart';
import 'lobby_screen.dart';

class AuthScreen extends StatefulWidget {
  final AuthService authService;

  const AuthScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _navigateToLobby(UserSession session) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          session: session,
          authService: widget.authService,
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Ingresa un correo electrónico válido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_isSignUp && username.isEmpty) {
      setState(() => _errorMessage = 'Por favor escribe tu nombre de jugador.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = _isSignUp
          ? await widget.authService.signUpWithEmail(email: email, password: password, username: username)
          : await widget.authService.signInWithEmail(email: email, password: password);
      _navigateToLobby(session);
    } catch (err) {
      setState(() => _errorMessage = 'No se pudo conectar: $err');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final session = await widget.authService.signInWithGoogle();
      _navigateToLobby(session);
    } catch (err) {
      setState(() => _errorMessage = 'Error al conectar con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final session = await widget.authService.signInAsGuest();
      _navigateToLobby(session);
    } catch (err) {
      setState(() => _errorMessage = 'Error al entrar como invitado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderLogo(),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) _buildErrorBanner(),
                  _buildAuthFormCard(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(),
                  const SizedBox(height: 12),
                  _buildGuestButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33F59E0B), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Text('👑', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DAMAS DE ÉLITE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Motor Némesis P4 • Multijugador Online con Monedas',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x33EF4444),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAuthFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Crear Cuenta Nueva' : 'Iniciar Sesión',
            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isSignUp) ...[
            _buildTextField(
              controller: _usernameController,
              label: 'Nombre de Jugador',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Correo Electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña (mín. 6 caracteres)',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 8),
          _buildToggleModeButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0B0F19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderBorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderBorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderBorderSide(color: Color(0xFFF59E0B)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: const Color(0xFF090D16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text(_isSignUp ? 'REGISTRARSE Y JUGAR' : 'ENTRAR AL JUEGO', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildToggleModeButton() {
    return TextButton(
      onPressed: () => setState(() => _isSignUp = !_isSignUp),
      child: Text(
        _isSignUp ? '¿Ya tienes cuenta? Inicia sesión aquí' : '¿No tienes cuenta? Regístrate gratis',
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _submitGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF111827),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔴 ', style: TextStyle(fontSize: 14)),
            Text('Continuar con Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: _isLoading ? null : _submitGuest,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          'Jugar como Invitado (Sin registro • 1.000 🪙 de bono)',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}

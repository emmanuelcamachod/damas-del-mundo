// Configuración de producción para Supabase del proyecto 'damas-online'
// Las credenciales sensibles deben inyectarse mediante variables de entorno (--dart-define)

import 'supabase_multiplayer_service.dart';

class DamasSupabaseConfig {
  static const String projectUrl = 'https://zwvkzsdlgcdcuwaphbpj.supabase.co';
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.anon_placeholder',
  );

  static const SupabaseMultiplayerConfig config = SupabaseMultiplayerConfig(
    supabaseUrl: projectUrl,
    anonKey: anonKey,
  );
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> login(
    String email,
    String password,
  ) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Obtiene el nombre completo del usuario logueado desde la tabla `profiles`.
  /// Retorna null si no hay sesión activa o si el perfil no tiene nombre.
  Future<String?> obtenerNombreUsuario() async {
    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        return null;
      }

      final response = await _client
          .from('profiles')
          .select('full_name')
          .eq('user_id', userId)
          .maybeSingle();

      final nombre = response?['full_name']?.toString().trim();

      if (nombre == null || nombre.isEmpty) {
        return null;
      }

      return nombre;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}


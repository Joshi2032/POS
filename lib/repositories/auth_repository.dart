import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  Future<void> login(
    String email,
    String password,
  ) async {
    await Supabase.instance.client.auth
        .signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Obtiene el nombre completo del usuario logueado desde la tabla `profiles`.
  /// Retorna null si no hay sesión activa o si el perfil no tiene nombre.
  Future<String?> obtenerNombreUsuario() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('user_id', userId)
          .maybeSingle();

      final nombre = response?['full_name']?.toString().trim();
      return (nombre != null && nombre.isNotEmpty) ? nombre : null;
    } catch (e) {
      return null;
    }
  }
}
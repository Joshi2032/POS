import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {

  Future<void> login(
    String email,
    String password,
  ) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> registrarUsuario(
    String email,
    String password,
  ) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}
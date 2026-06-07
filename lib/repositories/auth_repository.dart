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
}
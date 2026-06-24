import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository) {
    _cargarNombreUsuario();
  }

  bool isLoading = false;
  String? error;

  /// Nombre completo del usuario logueado, leído de `profiles.full_name`.
  String? nombreUsuario;

  /// UUID del usuario logueado (auth.users.id). Se usa como waiter_id al
  /// crear órdenes, para que Supabase guarde la referencia y el nombre se
  /// pueda recuperar después vía join con profiles.
  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.login(email, password);
      await _cargarNombreUsuario();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarNombreUsuario() async {
    nombreUsuario = await _repository.obtenerNombreUsuario();
    notifyListeners();
  }
}
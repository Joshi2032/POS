import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository) {
    // Intentar cargar el nombre del usuario si ya hay sesión activa
    // (útil cuando la app se reinicia y la sesión persiste).
    _cargarNombreUsuario();
  }

  bool isLoading = false;
  String? error;

  /// Nombre completo del usuario logueado, leído de `profiles.full_name`.
  /// Es null si no hay sesión o si el perfil no tiene nombre configurado.
  String? nombreUsuario;

  Future<bool> login(
    String email,
    String password,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.login(email, password);
      // Cargar el nombre después del login exitoso.
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
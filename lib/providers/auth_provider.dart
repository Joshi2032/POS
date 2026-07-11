import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/empleado_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final EmpleadoRepository _empleadoRepository;

  AuthProvider(this._repository, this._empleadoRepository) {
    _cargarNombreUsuario();
    _cargarPosicionUsuario();
  }

  bool isLoading = false;
  String? error;

  /// Nombre completo del usuario logueado, leído de `profiles.full_name`.
  String? nombreUsuario;

  /// Puesto del empleado logueado (Admin/Gerente/Mesero/Cajero/...), leído
  /// de `employees.position`. Null mientras carga o si el usuario logueado
  /// no tiene una fila de empleado asociada.
  String? posicionUsuario;

  /// UUID del usuario logueado (auth.users.id). Se usa como waiter_id al
  /// crear órdenes, para que Supabase guarde la referencia y el nombre se
  /// pueda recuperar después vía join con profiles.
  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  /// Antes el sidebar mostraba TODOS los ítems (incluido Empleados/Nóminas/
  /// Ajustes/Reportes) a cualquier usuario autenticado, sin importar su
  /// puesto. Se usa para ocultar el "Panel de Control" completo a quien no
  /// sea Admin/Gerente.
  bool get esAdminOGerente {
    final posicion = posicionUsuario?.trim().toLowerCase() ?? '';
    return posicion == 'admin' || posicion == 'gerente';
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.login(email, password);
      await _cargarNombreUsuario();
      await _cargarPosicionUsuario();
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

  Future<void> _cargarPosicionUsuario() async {
    final authUserId = userId;
    if (authUserId == null || authUserId.isEmpty) {
      posicionUsuario = null;
      notifyListeners();
      return;
    }

    try {
      final empleado =
          await _empleadoRepository.getByAuthUserId(authUserId);
      posicionUsuario = empleado?.position;
    } catch (_) {
      posicionUsuario = null;
    }

    notifyListeners();
  }

Future<void> logout() async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    await _repository.logout();
    nombreUsuario = null;
    posicionUsuario = null;
  } catch (e) {
    error = e.toString();
    rethrow;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

}
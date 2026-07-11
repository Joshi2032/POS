import 'package:flutter/material.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Una operación que ya estaba en curso (poll periódico, evento de
  // Realtime) puede resolver después de que el provider se desechó al
  // salir de la pantalla; sin este guard, notifyListeners() sobre un
  // ChangeNotifier ya dispuesto lanza una excepción.
  void _notifyIfMounted() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Envolvemos cualquier petición a base de datos con esto
  Future<void> ejecutarOperacion(Future<void> Function() operacion) async {
    _isLoading = true;
    _errorMessage = null;
    // Usamos Future.microtask para evitar errores de redibujado en Flutter
    Future.microtask(_notifyIfMounted);

    try {
      await operacion();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error en Provider: $e");
    } finally {
      _isLoading = false;
      Future.microtask(_notifyIfMounted);
    }
  }
}
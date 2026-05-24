import 'package:flutter/material.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Envolvemos cualquier petición a base de datos con esto
  Future<void> ejecutarOperacion(Future<void> Function() operacion) async {
    _isLoading = true;
    _errorMessage = null;
    // Usamos Future.microtask para evitar errores de redibujado en Flutter
    Future.microtask(() => notifyListeners());

    try {
      await operacion();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error en Provider: $e");
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }
}
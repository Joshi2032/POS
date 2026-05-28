import 'package:flutter/material.dart';
import '../models/movimiento_caja.dart';
import '../repositories/movimiento_caja_repository.dart';

class MovimientoCajaProvider extends ChangeNotifier {
  final MovimientoCajaRepository _repository;

  MovimientoCajaProvider(this._repository) {
    cargarMovimientos(); // Carga inicial automorfa
  }

  List<MovimientoCaja> _movimientos = [];
  bool _isLoading = false;

  // --- NUEVO ESTADO DE ERROR CENTRALIZADO ---
  String? _errorMessage;

  // --- GETTERS COMPATIBLES AL 100% CON TU DISEÑO ORIGINAL ---
  List<MovimientoCaja> get movimientos => _movimientos;
  bool get isLoading => _isLoading;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Resumen de totales reactivos para tus tarjetas visuales KPI
  double get totalIngresos => _movimientos
      .where((m) => m.tipo == 'Ingreso')
      .fold(0.0, (sum, m) => sum + m.monto);

  double get totalEgresos => _movimientos
      .where((m) => m.tipo == 'Egreso')
      .fold(0.0, (sum, m) => sum + m.monto);

  double get saldoNeto => totalIngresos - totalEgresos;

  // --- LÓGICA DE DATOS CAPTURADA ---
  Future<void> cargarMovimientos() async {
    _setLoading(true);
    _clearError();
    try {
      _movimientos = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando movimientos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarMovimientosPorFecha(String fecha) async {
    _setLoading(true);
    _clearError();
    try {
      _movimientos = await _repository.getMovimientosPorFecha(fecha);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando movimientos por fecha: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- ACCIONES C.R.U.D CON SOPORTE COMPATIBLE ---
  Future<bool> agregarMovimiento(MovimientoCaja movimiento) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(movimiento);
      await cargarMovimientos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error agregando movimiento: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarMovimiento(dynamic id, MovimientoCaja movimiento) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, movimiento);
      await cargarMovimientos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error actualizando movimiento: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarMovimiento(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarMovimientos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error eliminando movimiento: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS AUXILIARES ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
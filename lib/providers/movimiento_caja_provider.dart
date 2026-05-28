import 'package:flutter/material.dart';
import '../models/movimiento_caja.dart';
import '../repositories/movimiento_caja_repository.dart';

class MovimientoCajaProvider extends ChangeNotifier {
  final MovimientoCajaRepository _repository;

  MovimientoCajaProvider(this._repository) {
    cargarMovimientos();
  }

  List<MovimientoCaja> _movimientos = [];
  bool _isLoading = false;

  List<MovimientoCaja> get movimientos => _movimientos;
  bool get isLoading => _isLoading;

  // Resumen de totales
  double get totalIngresos => _movimientos
      .where((m) => m.tipo == 'Ingreso')
      .fold(0, (sum, m) => sum + m.monto);

  double get totalEgresos => _movimientos
      .where((m) => m.tipo == 'Egreso')
      .fold(0, (sum, m) => sum + m.monto);

  double get saldoNeto => totalIngresos - totalEgresos;

  Future<void> cargarMovimientos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _movimientos = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando movimientos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> agregarMovimiento(MovimientoCaja movimiento) async {
    try {
      await _repository.create(movimiento);
      await cargarMovimientos();
    } catch (e) {
      debugPrint('Error agregando movimiento: $e');
    }
  }

  Future<void> actualizarMovimiento(
      String id, MovimientoCaja movimiento) async {
    try {
      await _repository.update(id, movimiento);
      await cargarMovimientos();
    } catch (e) {
      debugPrint('Error actualizando movimiento: $e');
    }
  }

  Future<void> eliminarMovimiento(String id) async {
    try {
      await _repository.delete(id);
      await cargarMovimientos();
    } catch (e) {
      debugPrint('Error eliminando movimiento: $e');
    }
  }

  Future<void> cargarMovimientosPorFecha(String fecha) async {
    _isLoading = true;
    notifyListeners();
    try {
      _movimientos = await _repository.getMovimientosPorFecha(fecha);
    } catch (e) {
      debugPrint('Error cargando movimientos por fecha: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

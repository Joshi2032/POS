import 'package:flutter/material.dart';
import '../models/corte_caja.dart';
import '../repositories/corte_caja_repository.dart';

class HistorialCortesProvider extends ChangeNotifier {
  final CorteCajaRepository _repository;

  HistorialCortesProvider(this._repository) {
    cargarCortes();
  }

  List<CorteCaja> _cortes = [];
  bool _isLoading = false;

  final List<String> metodos = ['Todos', 'Efectivo', 'Tarjeta', 'Mixto'];

  String _filterDate = '';
  String _filterMethod = 'Todos';

  String get filterDate => _filterDate;
  String get filterMethod => _filterMethod;
  bool get isLoading => _isLoading;
  List<CorteCaja> get cortes => _cortes;

  List<CorteCaja> get cortesFiltrados {
    return _cortes.where((c) {
      final matchDate = _filterDate.isEmpty || c.fecha == _filterDate;
      final matchMethod = _filterMethod == 'Todos' || c.metodo == _filterMethod;
      return matchDate && matchMethod;
    }).toList();
  }

  double get totalEfectivo => cortesFiltrados
      .where((c) => c.metodo == 'Efectivo')
      .fold(0.0, (sum, c) => sum + c.monto);

  double get totalTarjeta => cortesFiltrados
      .where((c) => c.metodo == 'Tarjeta')
      .fold(0.0, (sum, c) => sum + c.monto);

  double get totalMixto => cortesFiltrados
      .where((c) => c.metodo == 'Mixto')
      .fold(0.0, (sum, c) => sum + c.monto);

  double get totalFiltrado =>
      cortesFiltrados.fold(0.0, (sum, c) => sum + c.monto);

  Future<void> cargarCortes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cortes = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando cortes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterDate(String date) {
    _filterDate = date;
    notifyListeners();
  }

  void setFilterMethod(String method) {
    _filterMethod = method;
    notifyListeners();
  }

  Future<void> agregarCorte(CorteCaja corte) async {
    try {
      await _repository.create(corte);
      await cargarCortes();
    } catch (e) {
      debugPrint('Error agregando corte: $e');
    }
  }

  Future<void> actualizarCorte(String id, CorteCaja corte) async {
    try {
      await _repository.update(id, corte);
      await cargarCortes();
    } catch (e) {
      debugPrint('Error actualizando corte: $e');
    }
  }

  Future<void> eliminarCorte(String id) async {
    try {
      await _repository.delete(id);
      await cargarCortes();
    } catch (e) {
      debugPrint('Error eliminando corte: $e');
    }
  }
}

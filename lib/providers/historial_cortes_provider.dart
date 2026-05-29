import 'package:flutter/material.dart';
import '../models/corte_caja.dart';
import '../repositories/corte_caja_repository.dart';

class HistorialCortesProvider extends ChangeNotifier {
  final CorteCajaRepository _repository;

  HistorialCortesProvider(this._repository) {
    cargarCortes(); // Carga inicial
  }

  List<CorteCaja> _cortes = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _filterDate = '';

  String get filterDate => _filterDate;
  bool get isLoading => _isLoading;
  List<CorteCaja> get cortes => _cortes;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Filtramos únicamente por fecha, ya que un corte resume todo el turno
  List<CorteCaja> get cortesFiltrados {
    return _cortes.where((c) {
      if (_filterDate.isEmpty) return true;
      final dateStr = c.cutAt?.split('T').first ?? '';
      return dateStr.contains(_filterDate);
    }).toList();
  }

  // Métricas reactivas leyendo directamente las columnas de la BD
  double get totalEfectivo => cortesFiltrados.fold(0.0, (sum, c) => sum + c.cashSales);
  double get totalTarjeta => cortesFiltrados.fold(0.0, (sum, c) => sum + c.cardSales);
  double get totalTransferencia => cortesFiltrados.fold(0.0, (sum, c) => sum + c.transferSales);
  
  double get totalFiltrado =>
      cortesFiltrados.fold(0.0, (sum, c) => sum + (c.cashSales + c.cardSales + c.transferSales));

  Future<void> cargarCortes() async {
    _setLoading(true);
    _clearError();
    try {
      _cortes = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando cortes: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setFilterDate(String date) {
    _filterDate = date;
    notifyListeners();
  }

  Future<bool> agregarCorte(CorteCaja corte) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(corte);
      await cargarCortes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error agregando corte: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarCorte(dynamic id, CorteCaja corte) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, corte);
      await cargarCortes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error actualizando corte: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarCorte(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarCortes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error eliminando corte: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
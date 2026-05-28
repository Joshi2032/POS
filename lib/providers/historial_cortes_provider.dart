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

  // --- NUEVO ESTADO DE ERROR DE RED CENTRALIZADO ---
  String? _errorMessage;

  final List<String> metodos = ['Todos', 'Efectivo', 'Tarjeta', 'Mixto'];

  String _filterDate = '';
  String _filterMethod = 'Todos';

  // --- GETTERS COMPATIBLES AL 100% CON TU DISEÑO ORIGINAL ---
  String get filterDate => _filterDate;
  String get filterMethod => _filterMethod;
  bool get isLoading => _isLoading;
  List<CorteCaja> get cortes => _cortes;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<CorteCaja> get cortesFiltrados {
    return _cortes.where((c) {
      final matchDate = _filterDate.isEmpty || c.fecha == _filterDate;
      final matchMethod = _filterMethod == 'Todos' || c.metodo == _filterMethod;
      return matchDate && matchMethod;
    }).toList();
  }

  // Métricas reactivas para tus componentes gráficos de arqueo
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

  // --- LÓGICA DE DATOS CAPTURADA ---
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

  // --- SETTERS DE INTERFAZ ORIGINAL ---
  void setFilterDate(String date) {
    _filterDate = date;
    notifyListeners();
  }

  void setFilterMethod(String method) {
    _filterMethod = method;
    notifyListeners();
  }

  // --- ACCIONES C.R.U.D CON RETORNO DE CONTROL COMPATIBLE ---
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

  // Acepta dynamic en el identificador para neutralizar discrepancias con los widgets
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

  // --- MÉTODOS AUXILIARES ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
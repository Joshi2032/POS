import 'package:flutter/material.dart';
import '../models/nomina_pago.dart';
import '../repositories/nomina_pago_repository.dart';

class NominasProvider extends ChangeNotifier {
  final NominaPagoRepository _repository;

  NominasProvider(this._repository) {
    cargarNominas();
  }

  List<NominaPago> _nominas = [];
  bool _isLoading = false;

  final int pageSize = 10;
  final List<String> tipos = ['Todos', 'Salario', 'Adelanto', 'Bono', 'Deducción'];

  String _search = '';
  String _selectedType = 'Todos';
  int _currentPage = 1;

  String get search => _search;
  String get selectedType => _selectedType;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;

  List<NominaPago> get nominasFiltradas {
    return _nominas.where((n) {
      final matchSearch = _search.isEmpty ||
          [n.empleado, n.tipo, n.metodo]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(_search.toLowerCase()));
      final matchType = _selectedType == 'Todos' || n.tipo == _selectedType;
      return matchSearch && matchType;
    }).toList();
  }

  int get totalPages => (nominasFiltradas.length / pageSize).ceil().clamp(1, 999999);

  List<NominaPago> get paginatedNominas {
    final start = (_currentPage - 1) * pageSize;
    return nominasFiltradas.skip(start).take(pageSize).toList();
  }

  double get totalMensual {
    return _nominas.fold(0.0, (sum, item) => sum + item.monto);
  }

  Future<void> cargarNominas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominas = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando nóminas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String val) {
    _search = val;
    _currentPage = 1;
    notifyListeners();
  }

  void setType(String type) {
    _selectedType = type;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  Future<void> agregarNomina(NominaPago nomina) async {
    try {
      await _repository.create(nomina);
      await cargarNominas();
    } catch (e) {
      debugPrint('Error agregando nómina: $e');
    }
  }

  Future<void> actualizarNomina(String id, NominaPago nomina) async {
    try {
      await _repository.update(id, nomina);
      await cargarNominas();
    } catch (e) {
      debugPrint('Error actualizando nómina: $e');
    }
  }

  Future<void> eliminarNomina(String id) async {
    try {
      await _repository.delete(id);
      await cargarNominas();
    } catch (e) {
      debugPrint('Error eliminando nómina: $e');
    }
  }

  Future<void> cargarNominasPorPeriodo(String periodo) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominas = await _repository.getNominasPorPeriodo(periodo);
    } catch (e) {
      debugPrint('Error cargando nóminas por período: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

  
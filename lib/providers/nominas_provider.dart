import 'package:flutter/material.dart';
import '../models/nomina_pago.dart';
import '../repositories/nomina_pago_repository.dart';

class NominasProvider extends ChangeNotifier {
  final NominaPagoRepository _repository;

  NominasProvider(this._repository) {
    cargarNominas(); // Carga inicial al levantar el módulo
  }

  List<NominaPago> _nominas = [];
  
  // --- ESTADOS CENTRALIZADOS DE FLUJO Y ERRORES ---
  bool _isLoading = false;
  String? _errorMessage;

  final int pageSize = 10;
  final List<String> tipos = ['Todos', 'Salario', 'Adelanto', 'Bono', 'Deducción'];

  String _search = '';
  String _selectedType = 'Todos';
  int _currentPage = 1;

  // --- GETTERS COMPATIBLES AL 100% CON TU INTERFAZ ORIGINAL ---
  String get search => _search;
  String get selectedType => _selectedType;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

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
  
  List<NominaPago> filtrar(String busqueda) {
    return _nominas.where((n) => 
      n.empleadoNombre.toLowerCase().contains(busqueda.toLowerCase())
    ).toList();
  }

  // --- LÓGICA DE DATOS SEGURA ---
  Future<void> cargarNominas() async {
    _setLoading(true);
    _clearError();
    try {
      _nominas = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando nóminas: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- SETTERS Y CONTROLES DE INTERFAZ ---
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

  void changePage(int newPage) {
    _currentPage = newPage.clamp(1, totalPages);
    notifyListeners();
  }

  // --- ACCIONES C.R.U.D CON RETORNO DE CONTROL COMPATIBLE ---
  Future<bool> agregarNomina(NominaPago nomina) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(nomina);
      await cargarNominas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error agregando nómina: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Soporta id dynamic en caso de que la UI envíe llaves numéricas o strings de forma indistinta
  Future<bool> actualizarNomina(dynamic id, NominaPago nomina) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, nomina);
      await cargarNominas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error actualizando nómina: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarNomina(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarNominas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error eliminando nómina: $e');
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
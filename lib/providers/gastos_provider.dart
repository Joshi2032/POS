import 'package:flutter/material.dart';
import '../models/gasto.dart';
import '../repositories/gasto_repository.dart';

class GastosProvider extends ChangeNotifier {
  final GastoRepository _repository;

  GastosProvider(this._repository) {
    cargarGastos(); // Carga inicial
  }

  List<Gasto> _gastos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todas';

  // --- ESTADOS DE CONTROL DE FLUJO Y ERRORES ---
  bool _isLoading = false;
  String? _errorMessage;

  // --- VARIABLES DE PAGINACIÓN REQUERIDAS POR LA UI ---
  int _currentPage = 1;
  final int _itemsPerPage = 10; 

  final List<String> categorias = [
    'Todas',
    'Parrilla',
    'Entradas',
    'Bebidas',
    'Postres'
  ];

  // --- GETTERS COMPATIBLES CON TU VISTA (gastos_page.dart) ---
  List<Gasto> get gastos => _gastos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get currentPage => _currentPage;
  ValueChanged<String> get onSearch => (value) {
  setSearchTerm(value);
};

  // Antes estaba definido igual a gastosFiltrados.length (el mismo total ya
  // filtrado), así que el contador "X de Y gastos" en la UI siempre
  // mostraba algo como "3 de 3" sin importar cuántos gastos hubiera en
  // total ni qué filtro estuviera activo.
  int get totalGastosLength => _gastos.length;
  List<Gasto> get filteredGastos => gastosFiltrados;

  List<Gasto> get paginatedGastos {
    final filtered = filteredGastos;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= filtered.length) return [];
    
    final endIndex = startIndex + _itemsPerPage;
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get totalPages {
    if (filteredGastos.isEmpty) return 1;
    return (filteredGastos.length / _itemsPerPage).ceil();
  }

  // --- CÁLCULOS FINANCIEROS CORREGIDOS (CON TU MODELO ORIGINAL) ---
  double get totalThisMonth {
    final ahora = DateTime.now();
    return _gastos.where((g) {
      try {
        final fechaGasto = DateTime.parse(g.date); // Propiedad original 'date'
        return fechaGasto.month == ahora.month && fechaGasto.year == ahora.year;
      } catch (_) {
        return false;
      }
    }).fold(0.0, (sum, item) => sum + (item.amount)); // Propiedad original 'amount'
  }

  double get totalAccumulated {
    return _gastos.fold(0.0, (sum, item) => sum + (item.amount)); // Propiedad original 'amount'
  }

  // --- MÉTODOS CRUD SOPORTANDO GASTOFORM SIN TOCAR EL MODELO ---
  Future<void> cargarGastos() async {
    _setLoading(true);
    _clearError();
    try {
      _gastos = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Mapeo manual si lo que manda la vista es un GastoForm
  Future<bool> addGasto(dynamic gastoInput) async {
    _setLoading(true);
    _clearError();
    try {
      Gasto gastoFinal;
      if (gastoInput is GastoForm) {
        gastoFinal = Gasto(
          date: gastoInput.date,
          concept: gastoInput.concept,
          category: gastoInput.category,
          amount: gastoInput.amount,
          method: gastoInput.method,
          notes: gastoInput.notes,
        );
      } else {
        gastoFinal = gastoInput as Gasto;
      }

      await _repository.create(gastoFinal);
      await cargarGastos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> crearGasto(dynamic gastoInput) => addGasto(gastoInput);

  Future<bool> updateGasto(String id, dynamic gastoInput) async {
    _setLoading(true);
    _clearError();
    try {
      Gasto gastoFinal;
      if (gastoInput is GastoForm) {
        gastoFinal = Gasto(
          id: id,
          date: gastoInput.date,
          concept: gastoInput.concept,
          category: gastoInput.category,
          amount: gastoInput.amount,
          method: gastoInput.method,
          notes: gastoInput.notes,
        );
      } else {
        gastoFinal = gastoInput as Gasto;
      }

      await _repository.update(id, gastoFinal);
      await cargarGastos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarGasto(String id, dynamic gastoInput) => updateGasto(id, gastoInput);

  Future<bool> deleteGasto(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.delete(id);
      await cargarGastos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarGasto(String id) => deleteGasto(id);

  // --- CONTROLES DE FILTRADO Y PAGINACIÓN ---
  void changePage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void seleccionarCategoria(String category) {
    setCategory(category);
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _currentPage = 1; 
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    _currentPage = 1; 
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Filtros internos basados estrictamente en tu modelo original
  List<Gasto> get gastosFiltrados {
    return _gastos.where((g) {
      final matchesSearch =
          g.concept.toLowerCase().contains(_searchTerm.toLowerCase()) || // g.concept original
          g.category.toLowerCase().contains(_searchTerm.toLowerCase()); // g.category original
      final matchesCategory =
          _selectedCategory == 'Todas' || g.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }
}
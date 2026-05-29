import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/producto_repository.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider(this._repository) {
    cargarDatosCompletos(); // Carga inicial
  }

  List<Producto> _productos = [];
  
  // DICCIONARIO: Conecta el nombre en la UI con el UUID de la base de datos
  final Map<String, String> _categoriaDiccionario = {}; 
  List<String> _categoriasUI = ['Todos'];

  String _searchTerm = '';
  String _selectedCategory = 'Todos';

  bool _isLoading = false;
  String? _errorMessage;

  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getter para los chips y dropdowns de la UI
  List<String> get categorias => _categoriasUI;

  // FUNCIÓN VITAL: Traduce de Nombre UI a UUID para guardarlo en la BD
  String? getCategoryIdByName(String name) {
    return _categoriaDiccionario[name];
  }

  // --- MÉTODOS CRUD ---
  Future<void> cargarDatosCompletos() async {
    _setLoading(true);
    _clearError();
    try {
      // 1. Cargar primero las categorías reales de la tabla 'categories'
      final catsDb = await _repository.getCategorias();
      _categoriaDiccionario.clear();
      List<String> nombresCat = [];
      
      for (var cat in catsDb) {
        final nombre = cat['name'].toString();
        final id = cat['id'].toString();
        _categoriaDiccionario[nombre] = id; // Guardamos en el diccionario
        nombresCat.add(nombre);
      }
      
      nombresCat.sort();
      _categoriasUI = ['Todos', ...nombresCat]; // Mantenemos 'Todos' al inicio

      // 2. Cargar los productos
      _productos = await _repository.getAll();

      // Validación de filtro actual
      if (!_categoriasUI.contains(_selectedCategory)) {
        _selectedCategory = 'Todos';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addProducto(Producto producto) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(producto);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProducto(String id, Producto producto) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.update(id, producto);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProducto(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.delete(id);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<Producto> get productosFiltrados {
    return _productos.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
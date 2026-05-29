import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/producto_repository.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider(this._repository) {
    cargarProductos(); // Carga inicial
  }

  List<Producto> _productos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todas';

  // --- ESTADOS DE CONTROL ---
  bool _isLoading = false;
  String? _errorMessage;

  // 1. Convertimos la lista de categorías en una variable interna dinámica
  List<String> _categorias = ['Todas'];

  // Getters para consultar los estados en la UI
  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getter público para que la UI siga leyendo 'categorias' exactamente igual que antes
  List<String> get categorias => _categorias;

  // --- MÉTODOS CRUD ---
  Future<void> cargarProductos() async {
    _setLoading(true);
    _clearError();
    try {
      _productos = await _repository.getAll();

      // 2. Extraemos las categorías reales de los productos obtenidos
      _actualizarCategoriasDinamicas();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 3. Función auxiliar para leer las categorías del JSON/Modelo y armar la lista sin duplicados
  void _actualizarCategoriasDinamicas() {
    // Usamos un Set para evitar elementos duplicados
    final deBaseDeDatos = _productos
        .map((p) => p.category)
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();


    // Ordenamos alfabéticamente para que el menú sea consistente
    deBaseDeDatos.sort();

    // Reconstruimos la lista manteniendo siempre 'Todas' al inicio
    _categorias = ['Todas', ...deBaseDeDatos];

    // Si la categoría que el usuario tenía seleccionada desaparece de la BD, lo regresamos a 'Todas'
    if (!_categorias.contains(_selectedCategory)) {
      _selectedCategory = 'Todas';
    }
  }

  Future<bool> addProducto(Producto producto) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(producto);
      await cargarProductos();
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
      await cargarProductos();
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
      await cargarProductos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS AUXILIARES DE ESTADO ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // --- FILTROS ---
  // En tu provider, ajusta los accesos así:
  List<Producto> get visibleProducts { 
  return _productos.where((product) {
    // Usamos .name y .category (del modelo nuevo)
    final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
    final matchesSearch = product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                          product.description.toLowerCase().contains(_searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  }).toList();
}

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // En tu ProductosProvider
List<Producto> get productosFiltrados {
  return  _productos.where((product) {
    final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
    final matchesSearch = product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                          product.description.toLowerCase().contains(_searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  }).toList();
}
}

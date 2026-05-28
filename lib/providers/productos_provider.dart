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

  // --- NUEVOS ESTADOS DE CONTROL ---
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> categorias = [
    'Todas',
    'Parrilla',
    'Entradas',
    'Bebidas',
    'Postres'
  ];

  // Getters para consultar los estados en la UI
  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // --- MÉTODOS CRUD REFACTORIZADOS ---
  Future<void> cargarProductos() async {
    _setLoading(true);
    _clearError();
    try {
      _productos = await _repository.getAll();
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
      await cargarProductos();
      return true; // Éxito
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false; // Falló
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
  List<Producto> get productosFiltrados {
    return _productos.where((p) {
      final matchesSearch =
          p.nombre.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Todas' || p.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
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
}
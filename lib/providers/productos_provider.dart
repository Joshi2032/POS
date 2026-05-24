// lib/providers/productos_provider.dart
import 'package:flutter/material.dart';
import '../repositories/producto_repository.dart';
import '../models/producto.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider(this._repository) {
    loadProductos();
  }

  List<Producto> _productos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todas';
  bool _isLoading = false;

  // Getters
  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;

  List<Producto> get productosFiltrados {
    return _productos.where((p) {
      final matchesSearch = p.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.unidad.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todas' ||
          p.categoria.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Acciones
  Future<void> loadProductos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _productos = await _repository.fetchProductos();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addProducto(Producto producto) async {
    await _repository.insertProducto(producto);
    await loadProductos();
  }

  Future<void> removeProducto(Producto producto) async {
    if (producto.id != null) {
      await _repository.deleteProducto(producto.id!);
      await loadProductos();
    }
  }
}
import 'package:flutter/material.dart';
import '../models/product.dart'; // Importación corregida
import '../repositories/producto_repository.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider(this._repository) {
    cargarProductos(); // Carga inicial
  }

  List<Producto> _productos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todas';

  // ¡AQUÍ ESTÁ LA LISTA QUE LE FALTABA A LA PÁGINA!
  final List<String> categorias = ['Todas', 'Parrilla', 'Entradas', 'Bebidas', 'Postres'];

  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;

  // --- MÉTODOS CRUD ---
  Future<void> cargarProductos() async {
    _productos = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addProducto(Producto producto) async {
    await _repository.create(producto);
    await cargarProductos();
  }

  Future<void> updateProducto(Producto producto) async {
    await _repository.update(producto);
    await cargarProductos();
  }

  Future<void> deleteProducto(String id) async {
    await _repository.delete(id);
    await cargarProductos();
  }

  // --- FILTROS ---
  List<Producto> get productosFiltrados {
    return _productos.where((p) {
      final matchesSearch = p.nombre.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todas' || p.categoria == _selectedCategory;
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
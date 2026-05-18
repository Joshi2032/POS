import 'package:flutter/material.dart';

class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String unidad;

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.unidad,
  });
}

class ProductosProvider extends ChangeNotifier {
  // Datos iniciales mudados desde la UI
  final List<Producto> _productos = [
    Producto(nombre: 'Arrachera 300g', categoria: 'Parrilla', precio: 285, stock: 40, unidad: 'plato'),
    Producto(nombre: 'T-Bone 500g', categoria: 'Parrilla', precio: 450, stock: 15, unidad: 'plato'),
    Producto(nombre: 'Costillas BBQ', categoria: 'Parrilla', precio: 320, stock: 25, unidad: 'rack'),
    Producto(nombre: 'Cerveza Artesanal', categoria: 'Bebidas', precio: 85, stock: 100, unidad: 'tarro'),
  ];

  final List<String> categorias = [
    'Todas', 'Parrilla', 'Entradas', 'Guarniciones', 'Ensaladas', 'Bebidas', 'Postres'
  ];

  String _searchTerm = '';
  String _selectedCategory = '';

  // Getters
  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;

  // Lógica de filtrado mudada desde la UI
  List<Producto> get productosFiltrados {
    return _productos.where((p) {
      final matchesSearch = p.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.unidad.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory.isEmpty ||
          _selectedCategory == 'Todas' ||
          p.categoria.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Acciones
  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addProducto(Producto producto) {
    _productos.add(producto);
    notifyListeners();
  }

  void updateProducto(int index, Producto producto) {
    _productos[index] = producto;
    notifyListeners();
  }

  void removeProducto(Producto producto) {
    _productos.remove(producto);
    notifyListeners();
  }
}
import 'package:flutter/material.dart';

class Producto {
  final String id;
  final String name;
  final String category;
  final double price;
  final double cost;
  final bool isAvailable;

  Producto({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cost,
    this.isAvailable = true,
  });

  Producto copyWith({String? name, String? category, double? price, double? cost, bool? isAvailable}) {
    return Producto(
      id: this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class ProductoForm {
  String name;
  String category;
  double price;
  double cost;
  bool isAvailable;

  ProductoForm({this.name = '', this.category = 'Alimentos', this.price = 0.0, this.cost = 0.0, this.isAvailable = true});
}

class ProductosProvider extends ChangeNotifier {
  final int pageSize = 10;
  final List<String> categorias = ['Todos', 'Alimentos', 'Bebidas', 'Postres', 'Extras'];
  
  List<Producto> _productos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todos';
  int _currentPage = 1;

  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;
  int get totalProductos => _productos.length;

  ProductosProvider() {
    _initData();
  }

  void _initData() {
    _productos = [
      Producto(id: 'PRD-001', name: 'Hamburguesa Zapata', category: 'Alimentos', price: 120.0, cost: 45.0),
      Producto(id: 'PRD-002', name: 'Tacos de Asada (3)', category: 'Alimentos', price: 105.0, cost: 35.0),
      Producto(id: 'PRD-003', name: 'Agua de Jamaica', category: 'Bebidas', price: 40.0, cost: 10.0),
      Producto(id: 'PRD-004', name: 'Flan Napolitano', category: 'Postres', price: 55.0, cost: 15.0, isAvailable: false),
    ];
  }

  List<Producto> get filteredProductos {
    return _productos.where((p) {
      final matchesSearch = _searchTerm.isEmpty || p.name.toLowerCase().contains(_searchTerm.toLowerCase()) || p.id.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Producto> get paginatedProductos {
    final list = filteredProductos;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + pageSize) > list.length ? list.length : (start + pageSize));
  }

  int get totalPages => (filteredProductos.length / pageSize).ceil();

  void onSearch(String value) { _searchTerm = value; _currentPage = 1; notifyListeners(); }
  void setCategory(String cat) { _selectedCategory = cat; _currentPage = 1; notifyListeners(); }
  void changePage(int page) { _currentPage = page; notifyListeners(); }

  void crearProducto(ProductoForm form) {
    _productos.insert(0, Producto(
      id: 'PRD-${(_productos.length + 1).toString().padLeft(3, '0')}',
      name: form.name, category: form.category, price: form.price, cost: form.cost, isAvailable: form.isAvailable,
    ));
    notifyListeners();
  }

  void actualizarProducto(String id, ProductoForm form) {
    final idx = _productos.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _productos[idx] = _productos[idx].copyWith(name: form.name, category: form.category, price: form.price, cost: form.cost, isAvailable: form.isAvailable);
      notifyListeners();
    }
  }

  void toggleDisponibilidad(String id, bool val) {
    final idx = _productos.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _productos[idx] = _productos[idx].copyWith(isAvailable: val);
      notifyListeners();
    }
  }

  void eliminarProducto(String id) {
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
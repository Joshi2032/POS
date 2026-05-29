import 'package:flutter/material.dart';
import '../repositories/producto_repository.dart';
import '../models/product.dart'; // Asegúrate que esta ruta sea correcta
import '../models/cart_item.dart';

enum OrderType { dineIn, takeaway }

class TomarOrdenProvider extends ChangeNotifier {
  final ProductoRepository _productoRepository;

  final Map<String, List<String>> tableAreas = {
    'A': ['A1', 'A2', 'A3', 'A4'],
    'B': ['B1', 'B2', 'B3']
  };

  TomarOrdenProvider(this._productoRepository) {
    cargarProductos();
  }

  List<Producto> _products = [];
  final List<CartItem> _cart = [];
  
  OrderType _orderType = OrderType.dineIn;
  String _selectedArea = 'A';
  String _selectedTable = 'A1';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';

  // Getters
  List<CartItem> get cart => _cart;
  OrderType get orderType => _orderType;
  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTable;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;
  
  List<String> get areas => tableAreas.keys.toList();
  List<String> get currentTables => tableAreas[_selectedArea] ?? [];
  int get itemsCount => _cart.fold(0, (sum, item) => sum + item.qty);
  double get total => _cart.fold(0.0, (sum, item) => sum + (item.qty * item.product.price));

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    return ['Todos', ...cats];
  }

  // CORRECCIÓN DE NULL SAFETY EN VISIBLE PRODUCTS
  List<Producto> get visibleProducts {
    return _products.where((product) {
      final name = product.name.toLowerCase();
      final desc = product.description.toLowerCase();
      final cat = product.category.toLowerCase();
      final search = _searchTerm.toLowerCase();
      
      final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = name.contains(search) || desc.contains(search) || cat.contains(search);
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> cargarProductos() async {
    try {
      _products = await _productoRepository.getAll();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void setOrderType(OrderType type) { _orderType = type; notifyListeners(); }
  void setArea(String area) { _selectedArea = area; _selectedTable = tableAreas[area]!.first; notifyListeners(); }
  void setTable(String table) { _selectedTable = table; notifyListeners(); }
  void setCategory(String category) { _selectedCategory = category; notifyListeners(); }
  void setSearchTerm(String term) { _searchTerm = term; notifyListeners(); }
  void setNotes(String notes) { _notes = notes; notifyListeners(); }

  void addToCart(Producto product) {
    // CORRECCIÓN: Comparamos IDs como strings para evitar errores de tipo int/string
    final index = _cart.indexWhere((item) => item.product.id.toString() == product.id.toString());
    if (index == -1) {
      _cart.add(CartItem(product: product));
    } else {
      _cart[index].qty++;
    }
    notifyListeners();
  }

  void increment(CartItem item) { item.qty++; notifyListeners(); }
  void decrement(CartItem item) {
    if (item.qty <= 1) {
      // CORRECCIÓN: Comparamos ID como String
      _cart.removeWhere((entry) => entry.product.id.toString() == item.product.id.toString());
    } else {
      item.qty--;
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    _cart.removeWhere((entry) => entry.product.id.toString() == item.product.id.toString());
    notifyListeners();
  }

  void sendOrder() { _cart.clear(); _notes = ''; notifyListeners(); }
}
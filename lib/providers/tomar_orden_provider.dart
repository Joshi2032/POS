import 'package:flutter/material.dart';
import '../models/product_item.dart';
import '../models/cart_item.dart';

enum OrderType { dineIn, takeaway }

class TomarOrdenProvider extends ChangeNotifier {
  final Map<String, List<String>> tableAreas = {
    'A': ['A1', 'A2', 'A3', 'A4'],
    'B': ['B1', 'B2', 'B3']
  };

  final List<String> categories = [
    'Todos',
    'Parrilla',
    'Entradas',
    'Ensaladas',
    'Guarniciones',
    'Bebidas',
    'Postres',
    'Extras'
  ];

  final List<ProductItem> _products = [
    ProductItem(
      id: 1,
      name: 'Arrachera 300g',
      description: 'Corte marinado a la brasa con chimichurri.',
      category: 'Parrilla',
      price: 285,
    ),
    ProductItem(
      id: 2,
      name: 'Brochetas Mixtas',
      description: 'Res y pollo a la parrilla con vegetales.',
      category: 'Parrilla',
      price: 175,
    ),
    ProductItem(
      id: 3,
      name: 'Costillas BBQ',
      description: 'Rack de costilla ahumada con salsa de la casa.',
      category: 'Parrilla',
      price: 320,
    ),
    ProductItem(
      id: 4,
      name: 'Elotes Asados',
      description: 'Con mayonesa, chile y limon.',
      category: 'Entradas',
      price: 65,
    ),
    ProductItem(
      id: 5,
      name: 'Guacamole Ahumado',
      description: 'Guacamole con chile ahumado y totopos.',
      category: 'Entradas',
      price: 95,
    ),
    ProductItem(
      id: 6,
      name: 'Ensalada Caesar',
      description: 'Lechuga romana, parmesano y crotones.',
      category: 'Ensaladas',
      price: 110,
    ),
    ProductItem(
      id: 7,
      name: 'Ensalada de la Casa',
      description: 'Mixta con vinagreta balsamica.',
      category: 'Ensaladas',
      price: 85,
    ),
    ProductItem(
      id: 8,
      name: 'Arroz a la Mexicana',
      description: 'Arroz tradicional con verduras.',
      category: 'Guarniciones',
      price: 45,
    ),
    ProductItem(
      id: 9,
      name: 'Frijoles Charros',
      description: 'Con tocino, chorizo y chile.',
      category: 'Guarniciones',
      price: 55,
    ),
    ProductItem(
      id: 10,
      name: 'Papas al Carbon',
      description: 'Papas asadas con hierbas.',
      category: 'Guarniciones',
      price: 75,
    ),
    ProductItem(
      id: 11,
      name: 'Agua de Jamaica',
      description: 'Agua fresca tradicional.',
      category: 'Bebidas',
      price: 40,
    ),
    ProductItem(
      id: 12,
      name: 'Cerveza Artesanal',
      description: 'IPA, Stout o Lager.',
      category: 'Bebidas',
      price: 85,
    ),
    ProductItem(
      id: 13,
      name: 'Limonada con Hierba Buena',
      description: 'Limonada natural refrescante.',
      category: 'Bebidas',
      price: 55,
    ),
    ProductItem(
      id: 14,
      name: 'Mezcal Oaxaqueno',
      description: 'Mezcal artesanal con sal de gusano.',
      category: 'Bebidas',
      price: 130,
    ),
    ProductItem(
      id: 15,
      name: 'Churros a la Brasa',
      description: 'Con chocolate caliente.',
      category: 'Postres',
      price: 75,
    ),
  ];

  OrderType _orderType = OrderType.dineIn;
  String _selectedArea = 'A';
  String _selectedTable = 'A1';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';
  final List<CartItem> _cart = [];

  OrderType get orderType => _orderType;
  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTable;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;
  List<CartItem> get cart => _cart;

  List<String> get areas => tableAreas.keys.toList();
  List<String> get currentTables => tableAreas[_selectedArea] ?? [];

  int get itemsCount => _cart.fold(0, (sum, item) => sum + item.qty);
  double get total => _cart.fold(0.0, (sum, item) => sum + item.total);

  List<ProductItem> get visibleProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = product.name
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          product.description
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  void setArea(String area) {
    if (_selectedArea == area) return;
    _selectedArea = area;
    _selectedTable = tableAreas[area]?.first ?? '';
    notifyListeners();
  }

  void setTable(String table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  void addToCart(ProductItem product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _cart.add(CartItem(product: product));
    } else {
      _cart[index].qty++;
    }
    notifyListeners();
  }

  void increment(CartItem item) {
    item.qty++;
    notifyListeners();
  }

  void decrement(CartItem item) {
    if (item.qty <= 1) {
      _cart.removeWhere((entry) => entry.product.id == item.product.id);
    } else {
      item.qty--;
    }
    notifyListeners();
  }

  void updateQty(CartItem item, int qty) {
    if (qty < 1) return;
    item.qty = qty;
    notifyListeners();
  }

  void remove(CartItem item) {
    _cart.removeWhere((entry) => entry.product.id == item.product.id);
    notifyListeners();
  }

  void sendOrder() {
    if (_cart.isEmpty) return;
    _cart.clear();
    _notes = '';
    notifyListeners();
  }
}

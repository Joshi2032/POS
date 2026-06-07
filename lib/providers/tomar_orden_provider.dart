import 'package:flutter/material.dart';
import '../repositories/producto_repository.dart';
import '../repositories/mesa_repository.dart';
import '../repositories/combo_repository.dart'; // AGREGADO
import '../models/product.dart'; // Asegúrate que esta ruta sea correcta
import '../models/cart_item.dart';
import '../models/mesa.dart';

enum OrderType { dineIn, takeaway }

class TomarOrdenProvider extends ChangeNotifier {
  final ProductoRepository _productoRepository;
  final MesaRepository _mesaRepository;
  final ComboRepository _comboRepository; // AGREGADO

  TomarOrdenProvider(
    this._productoRepository, 
    this._mesaRepository, 
    this._comboRepository, // AGREGADO
  ) {
    cargarProductos();
    cargarMesas();
  }

  List<Producto> _products = [];
  List<Mesa> _mesas = [];
  final List<CartItem> _cart = [];

  OrderType _orderType = OrderType.dineIn;
  String _selectedArea = '';
  String _selectedTableId = ''; // UUID de la mesa, no el nombre
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';

  // Getters
  List<CartItem> get cart => _cart;
  OrderType get orderType => _orderType;
  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTableId;
  String get selectedTableName {
    try {
      final mesa = _mesas.firstWhere((m) => m.id == _selectedTableId);
      return mesa.nombre;
    } catch (e) {
      return 'Sin mesa';
    }
  }

  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;

  List<String> get areas {
    final uniqueAreas = _mesas.map((m) => m.area).toSet().toList();
    uniqueAreas.sort();
    return uniqueAreas.isEmpty ? ['General'] : uniqueAreas;
  }

  List<String> get currentTables {
    if (_selectedArea.isEmpty) return [];
    return _mesas
        .where(
            (m) => m.area == _selectedArea && m.estado.toLowerCase() == 'libre')
        .map((m) => m.nombre)
        .toList();
  }

  String? getTableIdByName(String tableName) {
    try {
      return _mesas.firstWhere((m) => m.nombre == tableName).id;
    } catch (e) {
      return null;
    }
  }

  int get itemsCount => _cart.fold(0, (sum, item) => sum + item.qty);
  double get total =>
      _cart.fold(0.0, (sum, item) => sum + (item.qty * item.product.price));

  // CORREGIDO: Evitamos la duplicación de la categoría 'Combos'
  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    
    // Si por alguna razón la lista de combos está vacía, agregamos la categoría manualmente,
    // pero si ya existen combos cargados, evitamos duplicarla.
    if (!cats.contains('Combos')) {
      cats.add('Combos');
    }
    
    return ['Todos', ...cats];
  }

  List<Producto> get visibleProducts {
    return _products.where((product) {
      final name = product.name.toLowerCase();
      final desc = product.description.toLowerCase();
      final cat = product.category.toLowerCase();
      final search = _searchTerm.toLowerCase();

      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = name.contains(search) ||
          desc.contains(search) ||
          cat.contains(search);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> cargarProductos() async {
    try {
      // 1. Cargamos los productos normales
      final productosDB = await _productoRepository.getAll();
      
      // 2. Cargamos los combos
      final combosDB = await _comboRepository.getAll();

      // 3. Convertimos los ComboItem a Producto para que el carrito los entienda
      final combosConvertidos = combosDB.map((combo) {
        return Producto(
          id: combo.id, 
          name: combo.title,             // El título del combo pasa a ser el nombre
          description: combo.subtitle,   // El subtítulo pasa a ser la descripción
          price: combo.price,
          category: 'Combos',            // Forzamos la categoría para los filtros
          
          stock: 999,
          unit: 'combo',
          active: true,
          // NOTA: Si tu clase "Producto" en 'models/product.dart' requiere obligatoriamente 
          // campos como 'imageUrl', 'active', etc., agrégalos aquí. 
          // Por ejemplo: imageUrl: '', active: true
        );
      }).toList();

      // 4. Unimos ambas listas
      _products = [...productosDB, ...combosConvertidos];
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando productos y combos: $e');
    }
  }

  Future<void> cargarMesas() async {
    try {
      _mesas = await _mesaRepository.getAll();
      // Inicializa el área y mesa selectas si están vacías
      if (_selectedArea.isEmpty && areas.isNotEmpty) {
        _selectedArea = areas.first;
      }
      if (_selectedTableId.isEmpty && currentTables.isNotEmpty) {
        final firstTable = currentTables.first;
        _selectedTableId = getTableIdByName(firstTable) ?? '';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    }
  }

  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  void setArea(String area) {
    _selectedArea = area;
    final mesasEnArea = _mesas.where((m) => m.area == area).toList();
    if (mesasEnArea.isNotEmpty) {
      _selectedTableId = mesasEnArea.first.id;
    }
    notifyListeners();
  }

  void setTable(String tableName) {
    final mesaId = getTableIdByName(tableName);
    if (mesaId != null) {
      _selectedTableId = mesaId;
    }
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

  void addToCart(Producto product) {
    final index = _cart.indexWhere(
        (item) => item.product.id.toString() == product.id.toString());
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
      _cart.removeWhere(
          (entry) => entry.product.id.toString() == item.product.id.toString());
    } else {
      item.qty--;
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    _cart.removeWhere(
        (entry) => entry.product.id.toString() == item.product.id.toString());
    notifyListeners();
  }

  void sendOrder() {
    _cart.clear();
    _notes = '';
    notifyListeners();
  }
}
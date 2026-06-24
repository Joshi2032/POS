import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/mesa.dart';
import '../models/product.dart';
import '../repositories/combo_repository.dart';
import '../repositories/mesa_repository.dart';
import '../repositories/producto_repository.dart';

enum OrderType { dineIn, takeaway }

class TomarOrdenProvider extends ChangeNotifier {
  final ProductoRepository _productoRepository;
  final MesaRepository _mesaRepository;
  final ComboRepository _comboRepository;

  TomarOrdenProvider(
    this._productoRepository,
    this._mesaRepository,
    this._comboRepository,
  ) {
    cargarProductos();
    cargarMesas();
  }

  List<Producto> _products = [];
  List<Mesa> _mesas = [];
  final List<CartItem> _cart = [];

  OrderType _orderType = OrderType.dineIn;
  bool _isExistingTable = false;

  String _selectedArea = '';
  String _selectedTableId = '';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';

  List<CartItem> get cart => _cart;
  OrderType get orderType => _orderType;
  bool get isExistingTable => _isExistingTable;

  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTableId;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;

  String get selectedTableName {
    try {
      return _mesas
          .firstWhere(
            (mesa) =>
                mesa.id.toString() ==
                _selectedTableId.toString(),
          )
          .nombre;
    } catch (_) {
      return 'Sin mesa';
    }
  }

  List<String> get areas {
    final result = _mesas
        .map((mesa) => mesa.area.trim())
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();

    result.sort();

    return result;
  }

  List<String> get availableAreas {
    final result = _mesas
        .where((mesa) {
          final estado =
              mesa.estado.trim().toLowerCase();

          if (_isExistingTable) {
            return estado == 'ocupada';
          }

          return estado == 'libre' ||
              estado == 'disponible';
        })
        .map((mesa) => mesa.area.trim())
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();

    result.sort();

    return result;
  }

  List<String> get currentTables {
    if (_selectedArea.isEmpty) {
      return [];
    }

    final result = _mesas.where((mesa) {
      final mismaArea =
          mesa.area.trim().toLowerCase() ==
              _selectedArea.trim().toLowerCase();

      if (!mismaArea) {
        return false;
      }

      final estado =
          mesa.estado.trim().toLowerCase();

      if (_isExistingTable) {
        return estado == 'ocupada';
      }

      return estado == 'libre' ||
          estado == 'disponible';
    }).map((mesa) => mesa.nombre).toList();

    result.sort();

    return result;
  }

  List<String> get categories {
    final result = _products
        .map((product) => product.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    result.sort();

    return ['Todos', ...result];
  }

  List<Producto> get visibleProducts {
    final search =
        _searchTerm.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' ||
              product.category ==
                  _selectedCategory;

      final matchesSearch = search.isEmpty ||
          product.name
              .toLowerCase()
              .contains(search) ||
          product.description
              .toLowerCase()
              .contains(search) ||
          product.category
              .toLowerCase()
              .contains(search);

      return matchesCategory &&
          matchesSearch;
    }).toList();
  }

  int get itemsCount {
    return _cart.fold(
      0,
      (total, item) => total + item.qty,
    );
  }

  double get total {
    return _cart.fold(
      0,
      (total, item) => total + item.total,
    );
  }

  Future<void> cargarProductos() async {
    try {
      final productos =
          await _productoRepository.getAll();

      final combos =
          await _comboRepository.getAll();

      final combosConvertidos =
          combos.map((combo) {
        return Producto(
          id: combo.id,
          name: combo.title,
          description: combo.subtitle,
          price: combo.price,
          category: 'Combos',
          stock: 999,
          unit: 'combo',
          active: true,
        );
      }).toList();

      _products = [
        ...productos,
        ...combosConvertidos,
      ];

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error cargando productos y combos: $e',
      );
    }
  }

  Future<void> cargarMesas() async {
    try {
      _mesas = await _mesaRepository.getAll();

      if (_orderType == OrderType.takeaway) {
        _selectedArea = '';
        _selectedTableId = '';
        notifyListeners();
        return;
      }

      final areasValidas = availableAreas;

      if (areasValidas.isEmpty) {
        _selectedArea = '';
        _selectedTableId = '';
      } else {
        final areaActualSigueDisponible =
            areasValidas.any(
          (area) =>
              area.trim().toLowerCase() ==
              _selectedArea
                  .trim()
                  .toLowerCase(),
        );

        if (!areaActualSigueDisponible) {
          _selectedArea =
              areasValidas.first;
        }

        _seleccionarPrimeraMesaDisponible();
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error cargando mesas: $e',
      );
    }
  }

  Future<void> setOrderType(
    OrderType type,
  ) async {
    _orderType = type;

    if (type == OrderType.takeaway) {
      _isExistingTable = false;
      _selectedArea = '';
      _selectedTableId = '';

      notifyListeners();
      return;
    }

    _selectedArea = '';
    _selectedTableId = '';

    notifyListeners();

    await cargarMesas();
  }

  Future<void> setIsExistingTable(
    bool value,
  ) async {
    _isExistingTable = value;
    _selectedArea = '';
    _selectedTableId = '';

    notifyListeners();

    await cargarMesas();
  }

  void setArea(String area) {
    _selectedArea = area;
    _seleccionarPrimeraMesaDisponible();
    notifyListeners();
  }

  void setTable(String tableName) {
    final mesaId =
        getTableIdByName(tableName);

    if (mesaId == null) {
      return;
    }

    _selectedTableId = mesaId;
    notifyListeners();
  }

  String? getTableIdByName(
    String tableName,
  ) {
    try {
      return _mesas
          .firstWhere(
            (mesa) =>
                mesa.nombre.trim().toLowerCase() ==
                tableName
                    .trim()
                    .toLowerCase(),
          )
          .id
          .toString();
    } catch (_) {
      return null;
    }
  }

  void _seleccionarPrimeraMesaDisponible() {
    final mesasDisponibles =
        currentTables;

    if (mesasDisponibles.isEmpty) {
      _selectedTableId = '';
      return;
    }

    _selectedTableId =
        getTableIdByName(
              mesasDisponibles.first,
            ) ??
            '';
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
      (item) =>
          item.product.id.toString() ==
          product.id.toString(),
    );

    if (index == -1) {
      _cart.add(
        CartItem(product: product),
      );
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
      remove(item);
      return;
    }

    item.qty--;
    notifyListeners();
  }

  void remove(CartItem item) {
    _cart.removeWhere(
      (entry) =>
          entry.product.id.toString() ==
          item.product.id.toString(),
    );

    notifyListeners();
  }

  void sendOrder() {
    _cart.clear();
    _notes = '';
    notifyListeners();
  }
}

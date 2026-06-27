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

  // NUEVO: datos de la orden existente seleccionada
  String _selectedExistingOrderId = '';
  String _selectedExistingOrderNumber = '';

  List<CartItem> get cart => _cart;
  OrderType get orderType => _orderType;
  bool get isExistingTable => _isExistingTable;

  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTableId;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;

  // NUEVO
  String get selectedExistingOrderId => _selectedExistingOrderId;
  String get selectedExistingOrderNumber => _selectedExistingOrderNumber;

  bool get hasSelectedExistingOrder {
    return _selectedExistingOrderId.isNotEmpty;
  }

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

        // Solo selecciona primera mesa automáticamente
        // si NO hay una mesa ya seleccionada.
        if (_selectedTableId.isEmpty) {
          _seleccionarPrimeraMesaDisponible();
        }
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

    // Al cambiar tipo de orden, limpiamos selección existente
    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';

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

    // Limpiar orden existente anterior
    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';

    notifyListeners();

    await cargarMesas();
  }

  void setArea(String area) {
    _selectedArea = area;

    // Si el usuario cambia de área manualmente,
    // ya no debe quedarse amarrado a una orden anterior.
    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';

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

    // Si el usuario cambia mesa manualmente,
    // limpiamos la orden existente exacta.
    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';

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

  // NUEVO: esta es la función correcta para usar
  // cuando confirmas una orden existente desde el modal.
  Future<void> seleccionarOrdenExistente({
    required String orderId,
    required String orderNumber,
    required String tableId,
  }) async {
    if (_mesas.isEmpty) {
      await cargarMesas();
    }

    try {
      final mesa = _mesas.firstWhere(
        (item) =>
            item.id.toString() == tableId.toString(),
      );

      _isExistingTable = true;
      _orderType = OrderType.dineIn;
      _selectedArea = mesa.area;
      _selectedTableId = mesa.id.toString();

      _selectedExistingOrderId = orderId;
      _selectedExistingOrderNumber = orderNumber;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'No se encontró la mesa de la orden: $e',
      );
    }
  }

  // Puedes dejar esta por compatibilidad, pero ya no será la principal.
  Future<void> seleccionarMesaExistentePorId(
    String tableId,
  ) async {
    if (_mesas.isEmpty) {
      await cargarMesas();
    }

    try {
      final mesa = _mesas.firstWhere(
        (item) =>
            item.id.toString() == tableId.toString(),
      );

      _isExistingTable = true;
      _orderType = OrderType.dineIn;
      _selectedArea = mesa.area;
      _selectedTableId = mesa.id.toString();

      _selectedExistingOrderId = '';
      _selectedExistingOrderNumber = '';

      notifyListeners();
    } catch (e) {
      debugPrint(
        'No se encontró la mesa de la orden: $e',
      );
    }
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

    // Lo dejo así para que después de enviar
    // se siga quedando en "Existente", como dijiste.
    // Si quisieras que vuelva a Nueva, aquí se limpiaría:
    // _isExistingTable = false;
    // _selectedExistingOrderId = '';
    // _selectedExistingOrderNumber = '';

    notifyListeners();
  }
}
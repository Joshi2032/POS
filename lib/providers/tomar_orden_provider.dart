import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/mesa.dart';
import '../models/product.dart';
import '../repositories/combo_repository.dart';
import '../repositories/empleado_repository.dart';
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

  bool _isSendingOrder = false;
  bool get isSendingOrder => _isSendingOrder;

  void setSendingOrder(bool value) {
    _isSendingOrder = value;
    notifyListeners();
  }

  String _selectedArea = '';
  String _selectedTableId = '';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';

  // Datos del empleado logueado.
  List<String> _assignedAreas = [];
  String _currentEmployeePosition = '';
  bool _canSeeAllAreas = false;

  // Datos de la orden existente seleccionada.
  String _selectedExistingOrderId = '';
  String _selectedExistingOrderNumber = '';
  double _selectedExistingOrderTotal = 0.0;
  int _selectedExistingOrderItemsCount = 0;

  List<CartItem> get cart => _cart;
  OrderType get orderType => _orderType;
  bool get isExistingTable => _isExistingTable;

  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTableId;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;

  List<String> get assignedAreas => _assignedAreas;
  bool get hasAssignedAreas => _assignedAreas.isNotEmpty;

  String get currentEmployeePosition => _currentEmployeePosition;
  bool get canSeeAllAreas => _canSeeAllAreas;

  String get selectedExistingOrderId => _selectedExistingOrderId;
  String get selectedExistingOrderNumber => _selectedExistingOrderNumber;

  double get selectedExistingOrderTotal => _selectedExistingOrderTotal;
  int get selectedExistingOrderItemsCount => _selectedExistingOrderItemsCount;

  double get totalConOrdenExistente {
    if (_isExistingTable && _selectedExistingOrderId.isNotEmpty) {
      return _selectedExistingOrderTotal + total;
    }

    return total;
  }

  int get itemsCountConOrdenExistente {
    if (_isExistingTable && _selectedExistingOrderId.isNotEmpty) {
      return _selectedExistingOrderItemsCount + itemsCount;
    }

    return itemsCount;
  }

  bool get hasSelectedExistingOrder {
    return _selectedExistingOrderId.isNotEmpty;
  }

  bool get _isMesero {
    return _currentEmployeePosition.trim().toLowerCase() == 'mesero';
  }

  bool get _isAdminOrGerente {
    final position = _currentEmployeePosition.trim().toLowerCase();

    return position == 'admin' || position == 'gerente';
  }

  String get selectedTableName {
    try {
      return _mesas
          .firstWhere(
            (mesa) => mesa.id.toString() == _selectedTableId.toString(),
          )
          .nombre;
    } catch (_) {
      return 'Sin mesa';
    }
  }

  Set<String> get _assignedAreasNormalized {
    return _assignedAreas
        .map((area) => area.trim().toLowerCase())
        .where((area) => area.isNotEmpty)
        .toSet();
  }

  bool _isAreaAllowed(String area) {
    final normalizedArea = area.trim().toLowerCase();

    if (normalizedArea.isEmpty) {
      return false;
    }

    // Admin y Gerente ven todo.
    if (_canSeeAllAreas || _isAdminOrGerente) {
      return true;
    }

    // Mesero solo ve sus áreas asignadas.
    if (_isMesero) {
      return _assignedAreasNormalized.contains(normalizedArea);
    }

    // Cajero, Cocinero u otros roles no ven mesas en Tomar Orden.
    return false;
  }

  List<String> get areas {
    final result = _mesas
        .where((mesa) => _isAreaAllowed(mesa.area))
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
          if (!_isAreaAllowed(mesa.area)) {
            return false;
          }

          final estado = mesa.estado.trim().toLowerCase();

          if (_isExistingTable) {
            return estado == 'ocupada';
          }

          return estado == 'libre' || estado == 'disponible';
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

    final result = _mesas
        .where((mesa) {
          if (!_isAreaAllowed(mesa.area)) {
            return false;
          }

          final mismaArea = mesa.area.trim().toLowerCase() ==
              _selectedArea.trim().toLowerCase();

          if (!mismaArea) {
            return false;
          }

          final estado = mesa.estado.trim().toLowerCase();

          if (_isExistingTable) {
            return estado == 'ocupada';
          }

          return estado == 'libre' || estado == 'disponible';
        })
        .map((mesa) => mesa.nombre)
        .toList();

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
    final search = _searchTerm.trim().toLowerCase();

    return _products.where((product) {
      // Un producto desactivado no debe poder agregarse a una orden nueva,
      // aunque siga existiendo en el catálogo para administración.
      if (!product.active) return false;

      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;

      final matchesSearch = search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.description.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);

      return matchesCategory && matchesSearch;
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
      final productos = await _productoRepository.getAll();

      final combos = await _comboRepository.getAll();

      final combosConvertidos = combos.map((combo) {
        return Producto(
          id: combo.id,
          name: combo.title,
          description: combo.subtitle,
          price: combo.price,
          category: 'Combos',
          stock: 999,
          unit: 'combo',
          active: combo.active,
        );
      }).toList();

      _products = [
        ...productos,
        ...combosConvertidos,
      ];

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando productos y combos: $e');
    }
  }

  String _lastAuthUserIdLoaded = '';
  DateTime? _ultimaCargaAreas;
  bool _isLoadingAssignedAreas = false;

  // Antes de este cambio, una vez cargadas las áreas de un usuario no se
  // volvían a pedir en TODA la sesión (el provider vive a nivel de app). Si
  // un admin cambiaba el área asignada de un mesero ya conectado, la
  // pantalla de Tomar Orden de ese mesero seguía mostrando las áreas viejas
  // hasta que cerrara sesión por completo. Ahora se permite refrescar cada
  // par de minutos, sin volver a pedirlo en CADA notifyListeners() de
  // AuthProvider (que dispara este método vía ChangeNotifierProxyProvider).
  static const Duration _intervaloRecargaAreas = Duration(minutes: 2);

  Future<void> cargarAreasDelUsuario({
    required String authUserId,
    required EmpleadoRepository empleadoRepository,
  }) async {
    if (authUserId.trim().isEmpty) {
      return;
    }

    if (_isLoadingAssignedAreas) {
      return;
    }

    final cargadoRecientemente = _lastAuthUserIdLoaded == authUserId &&
        _ultimaCargaAreas != null &&
        DateTime.now().difference(_ultimaCargaAreas!) < _intervaloRecargaAreas;

    if (cargadoRecientemente) {
      return;
    }

    _isLoadingAssignedAreas = true;

    try {
      final empleado = await empleadoRepository.getByAuthUserId(authUserId);

      if (empleado == null) {
        _assignedAreas = [];
        _currentEmployeePosition = '';
        _canSeeAllAreas = false;
        _selectedArea = '';
        _selectedTableId = '';
        _lastAuthUserIdLoaded = authUserId;
        _ultimaCargaAreas = DateTime.now();

        notifyListeners();
        return;
      }

      _currentEmployeePosition = empleado.position.trim();

      if (_isAdminOrGerente) {
        // Admin y Gerente ven todas las áreas.
        _assignedAreas = [];
        _canSeeAllAreas = true;
      } else if (_isMesero) {
        // Mesero solo ve sus áreas asignadas.
        final areas = await empleadoRepository.getAreasByEmployeeId(
          empleado.id,
        );

        _assignedAreas = areas
            .map((area) => area.trim())
            .where((area) => area.isNotEmpty)
            .toSet()
            .toList();

        _canSeeAllAreas = false;
      } else {
        // Cajero, Cocinero u otros roles no ven mesas en Tomar Orden.
        _assignedAreas = [];
        _canSeeAllAreas = false;
      }

      _lastAuthUserIdLoaded = authUserId;
      _ultimaCargaAreas = DateTime.now();

      await cargarMesas();

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando áreas del usuario: $e');

      _assignedAreas = [];
      _currentEmployeePosition = '';
      _canSeeAllAreas = false;
      _selectedArea = '';
      _selectedTableId = '';
      _lastAuthUserIdLoaded = authUserId;
      _ultimaCargaAreas = DateTime.now();

      notifyListeners();
    } finally {
      _isLoadingAssignedAreas = false;
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
        final areaActualSigueDisponible = areasValidas.any(
          (area) =>
              area.trim().toLowerCase() == _selectedArea.trim().toLowerCase(),
        );

        if (!areaActualSigueDisponible) {
          _selectedArea = areasValidas.first;
          _selectedTableId = '';
        }

        if (_selectedTableId.isEmpty) {
          _seleccionarPrimeraMesaDisponible();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    }
  }

  Future<void> setOrderType(OrderType type) async {
    // Si ya está seleccionado este tipo, no hacemos nada: evita que un
    // doble-tap accidental sobre el mismo chip reasigne silenciosamente el
    // área/mesa (y con ella el pedido) mientras el carrito ya tiene productos.
    if (type == _orderType) return;

    _orderType = type;

    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';
    _selectedExistingOrderTotal = 0.0;
    _selectedExistingOrderItemsCount = 0;

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

  Future<void> setIsExistingTable(bool value) async {
    _isExistingTable = value;
    _selectedArea = '';
    _selectedTableId = '';

    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';

    notifyListeners();

    await cargarMesas();
  }

  void setArea(String area) {
    if (!_isAreaAllowed(area)) {
      return;
    }

    _selectedArea = area;

    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';
    _selectedExistingOrderTotal = 0.0;
    _selectedExistingOrderItemsCount = 0;

    _selectedTableId = '';
    _seleccionarPrimeraMesaDisponible();

    notifyListeners();
  }

  void setTable(String tableName) {
    final mesaId = getTableIdByName(tableName);

    if (mesaId == null) {
      return;
    }

    Mesa? mesa;
    try {
      mesa = _mesas.firstWhere(
        (item) => item.id.toString() == mesaId,
      );
    } catch (_) {
      return;
    }

    if (!_isAreaAllowed(mesa.area)) {
      return;
    }

    _selectedTableId = mesaId;

    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';
    _selectedExistingOrderTotal = 0.0;
    _selectedExistingOrderItemsCount = 0;

    notifyListeners();
  }

  String? getTableIdByName(String tableName) {
    try {
      return _mesas
          .firstWhere(
            (mesa) =>
                mesa.nombre.trim().toLowerCase() ==
                    tableName.trim().toLowerCase() &&
                _isAreaAllowed(mesa.area),
          )
          .id
          .toString();
    } catch (_) {
      return null;
    }
  }

  void _seleccionarPrimeraMesaDisponible() {
    final mesasDisponibles = currentTables;

    if (mesasDisponibles.isEmpty) {
      _selectedTableId = '';
      return;
    }

    _selectedTableId = getTableIdByName(mesasDisponibles.first) ?? '';
  }

 Future<void> seleccionarOrdenExistente({
  required String orderId,
  required String orderNumber,
  required String tableId,
  required double totalAmount,
  required int itemsCount,
}) async {
  if (_mesas.isEmpty) {
    await cargarMesas();
  }

  try {
    final mesa = _mesas.firstWhere(
      (item) => item.id.toString() == tableId.toString(),
    );

    if (!_isAreaAllowed(mesa.area)) {
      debugPrint(
        'La mesa de esta orden no pertenece a las áreas permitidas.',
      );
      return;
    }

    _isExistingTable = true;
    _orderType = OrderType.dineIn;
    _selectedArea = mesa.area;
    _selectedTableId = mesa.id.toString();

    _selectedExistingOrderId = orderId;
    _selectedExistingOrderNumber = orderNumber;
    _selectedExistingOrderTotal = totalAmount;
    _selectedExistingOrderItemsCount = itemsCount;

    _cart.clear();
    _notes = '';

    notifyListeners();
  } catch (e) {
    debugPrint('No se encontró la mesa de la orden: $e');
  }
}

  Future<void> seleccionarMesaExistentePorId(String tableId) async {
    if (_mesas.isEmpty) {
      await cargarMesas();
    }

    try {
      final mesa = _mesas.firstWhere(
        (item) => item.id.toString() == tableId.toString(),
      );

      if (!_isAreaAllowed(mesa.area)) {
        debugPrint('La mesa no pertenece a las áreas permitidas.');
        return;
      }

      _isExistingTable = true;
      _orderType = OrderType.dineIn;
      _selectedArea = mesa.area;
      _selectedTableId = mesa.id.toString();

      _selectedExistingOrderId = '';
      _selectedExistingOrderNumber = '';

      notifyListeners();
    } catch (e) {
      debugPrint('No se encontró la mesa de la orden: $e');
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
      (item) => item.product.id.toString() == product.id.toString(),
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
      (entry) => entry.product.id.toString() == item.product.id.toString(),
    );

    notifyListeners();
  }

  void sendOrder() {
    _cart.clear();
    _notes = '';

    // Este provider vive a nivel de app (no se recrea por página), así que
    // si no se limpia la orden existente seleccionada aquí, la próxima vez
    // que se abra "Tomar Orden" —aunque sea para una mesa distinta— seguiría
    // mostrando "Existente" con el id/total/cantidad de la orden que se
    // acaba de enviar, arriesgando que se agreguen productos a la orden
    // equivocada.
    _selectedExistingOrderId = '';
    _selectedExistingOrderNumber = '';
    _selectedExistingOrderTotal = 0.0;
    _selectedExistingOrderItemsCount = 0;

    notifyListeners();
  }
}

import 'package:flutter/material.dart';

typedef OrderStatus = String; // 'pendiente' | 'preparando' | 'lista' | 'entregada' | 'cancelada'
typedef ServiceType = String; // 'comedor' | 'llevar' | 'domicilio'

class OrderItem {
  final String productName;
  final int quantity;
  final double total;

  OrderItem({required this.productName, required this.quantity, required this.total});
}

class RestaurantOrder {
  final String id;
  final String tableOrCustomer;
  final String time;
  final OrderStatus status;
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double totalAmount;
  final String? notes;

  RestaurantOrder({
    required this.id,
    required this.tableOrCustomer,
    required this.time,
    required this.status,
    required this.serviceType,
    required this.items,
    required this.totalAmount,
    this.notes,
  });
}

class OrdenesProvider extends ChangeNotifier {
  final int pageSize = 6;
  
  final List<RestaurantOrder> _orders = []; // Inicialmente vacía para recibir comandas reales
  
  String _searchQuery = '';
  String _selectedFilterStatus = 'Todos';
  String _selectedFilterService = 'Todos';
  int _currentPage = 1;

  bool _showModal = false;
  RestaurantOrder? _selectedOrderForModal;

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedFilterStatus => _selectedFilterStatus;
  String get selectedFilterService => _selectedFilterService;
  int get currentPage => _currentPage;
  bool get showModal => _showModal;
  RestaurantOrder? get selectedOrderForModal => _selectedOrderForModal;

  List<RestaurantOrder> get filteredOrders {
    return _orders.where((order) {
      final matchesSearch = order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.tableOrCustomer.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedFilterStatus == 'Todos' || 
          order.status.toLowerCase() == _selectedFilterStatus.toLowerCase();
          
      final matchesService = _selectedFilterService == 'Todos' || 
          order.serviceType.toLowerCase() == _selectedFilterService.toLowerCase();

      return matchesSearch && matchesStatus && matchesService;
    }).toList();
  }

  List<RestaurantOrder> get paginatedOrders {
    final list = filteredOrders;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + pageSize) > list.length ? list.length : (start + pageSize));
  }

  int get totalPages => (filteredOrders.length / pageSize).ceil().clamp(1, 999999);
  int get activeOrdersCount => _orders.where((o) => o.status == 'pendiente' || o.status == 'preparando').length;
  int get readyOrdersCount => _orders.where((o) => o.status == 'lista').length;

  void onSearchChange(String val) { _searchQuery = val; _currentPage = 1; notifyListeners(); }
  void onStatusFilterChange(String val) { _selectedFilterStatus = val; _currentPage = 1; notifyListeners(); }
  void onServiceFilterChange(String val) { _selectedFilterService = val; _currentPage = 1; notifyListeners(); }
  void goToPage(int page) { _currentPage = page; notifyListeners(); }

  void abrirDetalleModal(RestaurantOrder order) { _selectedOrderForModal = order; _showModal = true; notifyListeners(); }
  void cerrarModal() { _showModal = false; _selectedOrderForModal = null; notifyListeners(); }

  // METODO DE INTERCONEXIÓN: Inserta órdenes creadas desde Tomar Orden
  void insertarNuevaComanda(RestaurantOrder nuevaOrden) {
    _orders.insert(0, nuevaOrden);
    notifyListeners();
  }

  bool cambiarEstadoOrden(String id, OrderStatus nuevoEstado) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _orders[idx] = RestaurantOrder(
        id: _orders[idx].id,
        tableOrCustomer: _orders[idx].tableOrCustomer,
        time: _orders[idx].time,
        status: nuevoEstado,
        serviceType: _orders[idx].serviceType,
        items: _orders[idx].items,
        totalAmount: _orders[idx].totalAmount,
        notes: _orders[idx].notes,
      );
      if (_selectedOrderForModal?.id == id) {
        _selectedOrderForModal = _orders[idx];
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}
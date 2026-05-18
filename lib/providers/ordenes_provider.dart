import 'package:flutter/material.dart';

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================
typedef OrderStatus = String; // 'pendiente' | 'preparando' | 'lista' | 'entregada' | 'cancelada'
typedef ServiceType = String; // 'comedor' | 'llevar' | 'domicilio'

class OrderDetail {
  final String productName;
  final int quantity;
  final double price;

  OrderDetail({required this.productName, required this.quantity, required this.price});

  double get total => quantity * price;
}

class Order {
  final String id;
  final String tableOrCustomer;
  final ServiceType serviceType;
  final List<OrderDetail> items;
  OrderStatus status;
  final String time;
  final String? notes;

  Order({
    required this.id,
    required this.tableOrCustomer,
    required this.serviceType,
    required this.items,
    required this.status,
    required this.time,
    this.notes,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      tableOrCustomer: tableOrCustomer,
      serviceType: serviceType,
      items: items,
      status: status ?? this.status,
      time: time,
      notes: notes,
    );
  }
}

// ==========================================
// 2. GESTOR DE ESTADO (CEREBRO DEL MÓDULO)
// ==========================================
class OrdenesProvider extends ChangeNotifier {
  final int pageSize = 8;

  // Variables privadas de estado
  List<Order> _orders = [];
  String _searchTerm = '';
  int _currentPage = 1;
  String _selectedFilterStatus = 'Todos';
  String _selectedFilterService = 'Todos';
  Order? _selectedOrderForModal;
  bool _showModal = false;

  // Getters para la UI
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  String get selectedFilterStatus => _selectedFilterStatus;
  String get selectedFilterService => _selectedFilterService;
  Order? get selectedOrderForModal => _selectedOrderForModal;
  bool get showModal => _showModal;

  OrdenesProvider() {
    _initData();
  }

  void _initData() {
    _orders = [
      Order(id: 'ORD-101', tableOrCustomer: 'Mesa 4', serviceType: 'comedor', status: 'pendiente', time: '14:25', items: [
        OrderDetail(productName: 'Tacos de Asada', quantity: 3, price: 35.0),
        OrderDetail(productName: 'Refresco Refill', quantity: 2, price: 30.0),
      ]),
      Order(id: 'ORD-102', tableOrCustomer: 'Carlos P.', serviceType: 'llevar', status: 'preparando', time: '14:30', items: [
        OrderDetail(productName: 'Hamburguesa Zapata', quantity: 1, price: 120.0),
        OrderDetail(productName: 'Papas Gajo', quantity: 1, price: 45.0),
      ], notes: 'Sin cebolla en la hamburguesa'),
      Order(id: 'ORD-103', tableOrCustomer: 'Calle Aldama #24', serviceType: 'domicilio', status: 'lista', time: '14:10', items: [
        OrderDetail(productName: 'Paquete Familiar Premium', quantity: 1, price: 389.0),
      ]),
      Order(id: 'ORD-104', tableOrCustomer: 'Mesa 1', serviceType: 'comedor', status: 'entregada', time: '13:15', items: [
        OrderDetail(productName: 'Combo Individual', quantity: 2, price: 149.0),
      ]),
      Order(id: 'ORD-105', tableOrCustomer: 'Mesa 7', serviceType: 'comedor', status: 'cancelada', time: '13:00', items: [
        OrderDetail(productName: 'Gringa de Pastor', quantity: 1, price: 65.0),
      ]),
    ];
  }

  // --- LÓGICA COMPUTADA (Filtros y Paginación) ---
  List<Order> get filteredOrders {
    final search = _searchTerm.toLowerCase();
    return _orders.where((order) {
      final matchesSearch = order.id.toLowerCase().contains(search) || 
                            order.tableOrCustomer.toLowerCase().contains(search);
      final matchesStatus = _selectedFilterStatus == 'Todos' || order.status == _selectedFilterStatus.toLowerCase();
      final matchesService = _selectedFilterService == 'Todos' || order.serviceType == _selectedFilterService.toLowerCase();
      
      return matchesSearch && matchesStatus && matchesService;
    }).toList();
  }

  List<Order> get paginatedOrders {
    final filtered = filteredOrders;
    final start = (_currentPage - 1) * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    return filtered.sublist(start, end);
  }

  int get totalPages => (filteredOrders.length / pageSize).ceil();
  int get activeOrdersCount => _orders.where((o) => o.status == 'pendiente' || o.status == 'preparando' || o.status == 'lista').length;
  int get readyOrdersCount => _orders.where((o) => o.status == 'lista').length;

  // --- ACCIONES MUTADORAS ---
  void onSearchChange(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void onStatusFilterChange(String status) {
    _selectedFilterStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void onServiceFilterChange(String service) {
    _selectedFilterService = service;
    _currentPage = 1;
    notifyListeners();
  }

  bool cambiarEstadoOrden(String id, OrderStatus nuevoEstado) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: nuevoEstado);
      // Actualizar la orden del modal si es la que se está editando
      if (_showModal && _selectedOrderForModal?.id == id) {
        _selectedOrderForModal = _orders[index];
      }
      notifyListeners();
      return true; // Retorna true si cambió exitosamente
    }
    return false;
  }

  void abrirDetalleModal(Order order) {
    _selectedOrderForModal = order;
    _showModal = true;
    notifyListeners();
  }

  void cerrarModal() {
    _showModal = false;
    _selectedOrderForModal = null;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }
}
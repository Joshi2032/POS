import 'package:flutter/material.dart';

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================
typedef PaymentMethod = String;

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({required this.name, required this.qty, required this.price});
}

class CashOrder {
  final String id;
  final String label;
  final String status;
  final int itemsCount;
  final String time;
  final double total;
  final List<OrderItem> items;

  CashOrder({
    required this.id,
    required this.label,
    required this.status,
    required this.itemsCount,
    required this.time,
    required this.total,
    required this.items,
  });

  CashOrder copyWith({String? status}) {
    return CashOrder(
      id: id,
      label: label,
      status: status ?? this.status,
      itemsCount: itemsCount,
      time: time,
      total: total,
      items: items,
    );
  }
}

// ==========================================
// 2. GESTOR DE ESTADO (CEREBRO DEL MÓDULO)
// ==========================================
class CajaProvider extends ChangeNotifier {
  final List<PaymentMethod> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  // Variables privadas de estado
  List<CashOrder> _pendingOrders = [];
  List<CashOrder> _paidToday = [];
  String? _selectedOrderId;
  PaymentMethod _selectedMethod = 'Efectivo';
  double? _receivedAmount;
  String _cashError = '';

  // Controlador de texto manejado por el Provider
  final TextEditingController receivedAmountController = TextEditingController();

  // Getters para la UI
  List<CashOrder> get pendingOrders => _pendingOrders;
  List<CashOrder> get paidToday => _paidToday;
  String? get selectedOrderId => _selectedOrderId;
  PaymentMethod get selectedMethod => _selectedMethod;
  double? get receivedAmount => _receivedAmount;
  String get cashError => _cashError;

  CajaProvider() {
    _initData();
  }

  @override
  void dispose() {
    receivedAmountController.dispose();
    super.dispose();
  }

  void _initData() {
    _pendingOrders = [
      CashOrder(id: 'ORD-120', label: 'Mesa A1', status: 'Pendiente', itemsCount: 2, time: '07:05 p.m.', total: 475.0, items: [
        OrderItem(name: 'Arrachera 300g', qty: 1, price: 285.0),
        OrderItem(name: 'Agua de Jamaica', qty: 1, price: 40.0),
        OrderItem(name: 'Papas al Carbon', qty: 1, price: 75.0),
        OrderItem(name: 'Mezcal Oaxaqueno', qty: 1, price: 75.0)
      ]),
      CashOrder(id: 'ORD-121', label: 'Llevar', status: 'Preparando', itemsCount: 1, time: '06:50 p.m.', total: 320.0, items: [
        OrderItem(name: 'Costillas BBQ', qty: 1, price: 320.0)
      ])
    ];

    _paidToday = [
      CashOrder(id: 'ORD-100', label: 'Mesa B2', status: 'Pagada', itemsCount: 3, time: '04:20 p.m.', total: 570.0, items: []),
      CashOrder(id: 'ORD-101', label: 'Mesa A3', status: 'Pagada', itemsCount: 2, time: '04:44 p.m.', total: 450.0, items: []),
      CashOrder(id: 'ORD-102', label: 'Llevar', status: 'Pagada', itemsCount: 1, time: '05:05 p.m.', total: 320.0, items: []),
      CashOrder(id: 'ORD-103', label: 'Mesa C1', status: 'Pagada', itemsCount: 4, time: '05:32 p.m.', total: 835.0, items: []),
      CashOrder(id: 'ORD-104', label: 'Mesa A2', status: 'Pagada', itemsCount: 1, time: '05:58 p.m.', total: 195.0, items: [])
    ];
  }

  // --- LÓGICA COMPUTADA (Matemáticas) ---
  CashOrder? get selectedOrder {
    if (_selectedOrderId == null) return null;
    return _pendingOrders.firstWhere((order) => order.id == _selectedOrderId, orElse: () => _pendingOrders.last);
  }

  int get paidTodayCount => _paidToday.length;

  double get totalInCash => _paidToday.fold(0.0, (sum, order) => sum + order.total);

  double get orderSubtotal {
    final order = selectedOrder;
    if (order == null) return 0.0;
    return order.items.fold(0.0, (sum, item) => sum + (item.qty * item.price));
  }

  double get changeDue {
    final order = selectedOrder;
    final received = _receivedAmount;
    if (order == null || received == null || _selectedMethod != 'Efectivo') return 0.0;
    
    final diff = received - order.total;
    return diff > 0 ? diff : 0.0;
  }

  // --- ACCIONES MUTADORAS ---
  void selectOrder(CashOrder order) {
    _selectedOrderId = order.id;
    _cashError = '';
    if (_selectedMethod == 'Efectivo') {
      _receivedAmount = order.total;
      receivedAmountController.text = order.total.toStringAsFixed(2);
    }
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _selectedMethod = method;
    _cashError = '';

    if (method != 'Efectivo') {
      _receivedAmount = selectedOrder?.total;
      notifyListeners();
      return;
    }

    if (_receivedAmount == null) {
      _receivedAmount = selectedOrder?.total;
      if (_receivedAmount != null) {
        receivedAmountController.text = _receivedAmount!.toStringAsFixed(2);
      }
    }
    notifyListeners();
  }

  void setReceivedAmount(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      _receivedAmount = null;
    } else {
      _receivedAmount = parsed > 0 ? parsed : 0.0;
    }
    notifyListeners();
  }

  void closeSelectedOrderPanel() {
    _selectedOrderId = null;
    _cashError = '';
    _receivedAmount = null;
    receivedAmountController.clear();
    notifyListeners();
  }

  bool chargeSelectedOrder() {
    final order = selectedOrder;
    if (order == null) return false;

    if (_selectedMethod == 'Efectivo') {
      final received = _receivedAmount ?? 0.0;
      if (received < order.total) {
        _cashError = 'El monto recibido no cubre el total de la orden.';
        notifyListeners();
        return false; // Falló el cobro
      }
    }

    _cashError = '';
    _pendingOrders.removeWhere((entry) => entry.id == order.id);
    _paidToday.insert(0, order.copyWith(status: 'Pagada'));
    _selectedOrderId = null;
    _receivedAmount = null;
    receivedAmountController.clear();
    
    notifyListeners();
    return true; // Cobro exitoso
  }
}
import 'package:flutter/material.dart';

class CashItem {
  final String name;
  final int qty;
  final double price;
  CashItem({required this.name, required this.qty, required this.price});
}

class CashOrder {
  final String id;
  final String label;
  final String time;
  final String status;
  final int itemsCount;
  final List<CashItem> items;
  final double total;

  CashOrder({
    required this.id, required this.label, required this.time, 
    required this.status, required this.itemsCount, required this.items, required this.total,
  });
}

class CajaProvider extends ChangeNotifier {
  final List<String> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];
  final TextEditingAmountController receivedAmountController = TextEditingAmountController();

  final List<CashOrder> _pendingOrders = []; // Vacía para recibir datos vivos de Tomar Orden
  final List<CashOrder> _paidToday = [];
  double _totalInCash = 15420.00;

  String? _selectedOrderId;
  CashOrder? _selectedOrder;
  String _selectedMethod = 'Efectivo';
  double _receivedAmount = 0.0;
  String _cashError = '';

  // Getters
  List<CashOrder> get pendingOrders => _pendingOrders;
  List<CashOrder> get paidToday => _paidToday;
  double get totalInCash => _totalInCash;
  String? get selectedOrderId => _selectedOrderId;
  CashOrder? get selectedOrder => _selectedOrder;
  String get selectedMethod => _selectedMethod;
  double get orderSubtotal => _selectedOrder?.total ?? 0.0;
  String get cashError => _cashError;
  int get paidTodayCount => _paidToday.length;

  double get changeDue {
    if (_selectedOrder == null || _receivedAmount < _selectedOrder!.total) return 0.0;
    return _receivedAmount - _selectedOrder!.total;
  }

  void selectOrder(CashOrder order) {
    _selectedOrderId = order.id;
    _selectedOrder = order;
    _receivedAmount = 0.0;
    receivedAmountController.clear();
    _cashError = '';
    notifyListeners();
  }

  void closeSelectedOrderPanel() {
    _selectedOrderId = null;
    _selectedOrder = null;
    _cashError = '';
    notifyListeners();
  }

  // METODO DE INTERCONEXIÓN: Recibe la cuenta por cobrar desde Tomar Orden
  void agregarCuentaPorCobrar(CashOrder nuevaCuenta) {
    _pendingOrders.insert(0, nuevaCuenta);
    notifyListeners();
  }

  void setPaymentMethod(String m) { _selectedMethod = m; _cashError = ''; notifyListeners(); }
  
  void setReceivedAmount(String val) {
    _receivedAmount = double.tryParse(val) ?? 0.0;
    _cashError = '';
    notifyListeners();
  }

  bool chargeSelectedOrder() {
    if (_selectedOrder == null) return false;
    if (_selectedMethod == 'Efectivo' && _receivedAmount < _selectedOrder!.total) {
      _cashError = 'Monto recibido insuficiente.';
      notifyListeners();
      return false;
    }

    _totalInCash += _selectedOrder!.total;
    _paidToday.insert(0, _selectedOrder!);
    _pendingOrders.removeWhere((o) => o.id == _selectedOrderId);
    
    closeSelectedOrderPanel();
    return true;
  }
}

class TextEditingAmountController extends TextEditingController {}
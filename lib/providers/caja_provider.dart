import 'package:flutter/material.dart';
import '../ui_models/cash_order.dart';
import '../repositories/caja_repository.dart';

class CajaProvider extends ChangeNotifier {
  final CajaRepository _repository;

  CajaProvider(this._repository) {
    _inicializarDatos();
  }

  final List<String> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];
  // Ya no hay TextEditingController aquí

  final List<CashOrder> _pendingOrders = []; 
  final List<CashOrder> _paidToday = [];
  double _totalInCash = 0.0;

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

  Future<void> _inicializarDatos() async {
    _totalInCash = await _repository.obtenerTotalEnCaja();
    notifyListeners();
  }

  void selectOrder(CashOrder order) {
    _selectedOrderId = order.id;
    _selectedOrder = order;
    _receivedAmount = 0.0;
    _cashError = '';
    notifyListeners();
  }

  void closeSelectedOrderPanel() {
    _selectedOrderId = null;
    _selectedOrder = null;
    _cashError = '';
    notifyListeners();
  }

  void agregarCuentaPorCobrar(CashOrder nuevaCuenta) {
    _pendingOrders.insert(0, nuevaCuenta);
    notifyListeners();
  }

  void setPaymentMethod(String m) { 
    _selectedMethod = m; 
    _cashError = ''; 
    notifyListeners(); 
  }
  
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

    _repository.registrarCobro(_selectedOrder!.total, _selectedMethod);

    _totalInCash += _selectedOrder!.total;
    _paidToday.insert(0, _selectedOrder!);
    _pendingOrders.removeWhere((o) => o.id == _selectedOrderId);
    
    closeSelectedOrderPanel();
    return true;
  }
}
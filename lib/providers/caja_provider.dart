import 'package:flutter/material.dart';
import '../ui_models/cash_order.dart';
import '../repositories/caja_repository.dart';

class CajaProvider extends ChangeNotifier {
  final CajaRepository _repository;

  CajaProvider(this._repository) {
    _inicializarDatos();
  }

  final List<String> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  final List<CashOrder> _pendingOrders = []; 
  final List<CashOrder> _paidToday = [];
  double _totalInCash = 0.0;

  String? _selectedOrderId;
  CashOrder? _selectedOrder;
  String _selectedMethod = 'Efectivo';
  double _receivedAmount = 0.0;
  String _cashError = '';

  // --- ESTADOS CENTRALIZADOS DE RED Y FLUJO ---
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS (Exactamente idénticos a los que necesita tu UI original) ---
  List<CashOrder> get pendingOrders => _pendingOrders;
  List<CashOrder> get paidToday => _paidToday;
  double get totalInCash => _totalInCash;
  String? get selectedOrderId => _selectedOrderId;
  CashOrder? get selectedOrder => _selectedOrder;
  String get selectedMethod => _selectedMethod;
  double get orderSubtotal => _selectedOrder?.total ?? 0.0;
  String get cashError => _cashError;
  int get paidTodayCount => _paidToday.length;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  double get changeDue {
    if (_selectedOrder == null || _receivedAmount < _selectedOrder!.total) return 0.0;
    return _receivedAmount - _selectedOrder!.total;
  }

  // --- LÓGICA DE DATOS ASÍNCRONA ROBUSTA ---
  Future<void> _inicializarDatos() async {
    _setLoading(true);
    _clearError();
    try {
      _totalInCash = await _repository.obtenerTotalEnCaja();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Método público para forzar la recarga desde la pantalla si fuera necesario
  Future<void> recargarCaja() => _inicializarDatos();

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

  // Tipo de retorno bool síncrono para satisfacer el "if" de caja_page.dart (Línea 491)
  bool chargeSelectedOrder() {
    if (_selectedOrder == null) return false;
    if (_selectedMethod == 'Efectivo' && _receivedAmount < _selectedOrder!.total) {
      _cashError = 'Monto recibido insuficiente.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _cashError = '';

    // Clonamos las variables necesarias para el hilo asíncrono de Supabase
    final String orderId = _selectedOrder!.id;
    final String metodo = _selectedMethod;
    final double total = _selectedOrder!.total;
    final CashOrder orderToMove = _selectedOrder!;

    // Ejecutamos la petición de Supabase en segundo plano de forma segura
    _repository.registrarCobro(orderId, metodo, total).then((_) {
      // Éxito en el servidor
    }).catchError((e) {
      // Si falla la red, guardamos el error en consola
      debugPrint('Error asíncrono en Supabase Caja: $e');
    });

    // Modificamos el estado local inmediatamente para mantener la UI fluida e idéntica
    _totalInCash += total;
    _paidToday.insert(0, orderToMove);
    _pendingOrders.removeWhere((o) => o.id == _selectedOrderId);
    
    closeSelectedOrderPanel();
    _setLoading(false);
    
    return true; // Devuelve el bool instantáneo que tu vista necesita en el if
  }

  // --- MÉTODOS AUXILIARES ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
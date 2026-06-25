import 'package:flutter/material.dart';
import '../ui_models/cash_order.dart';
import '../ui_models/cash_item.dart';
import '../repositories/caja_repository.dart';
import 'ordenes_provider.dart';
import '../models/restaurant_order.dart';

class CajaProvider extends ChangeNotifier {
  final CajaRepository _repository;
  final OrdenesProvider _ordenesProvider;

  CajaProvider(this._repository, this._ordenesProvider) {
    _inicializarDatos();
  }

  final List<String> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

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
List<CashOrder> get pendingOrders =>
    _ordenesProvider.orders.where((o) {
      final status = o.status.toLowerCase().trim();

      return status == 'pending' ||
          status == 'pendiente' ||
          status == 'preparing' ||
          status == 'preparando';
    }).map(_mapRestaurantToCashOrder).toList();

List<CashOrder> get paidToday =>
    _ordenesProvider.orders.where((o) {
      final status = o.status.toLowerCase().trim();

      return status == 'paid' || status == 'pagada';
    }).map(_mapRestaurantToCashOrder).toList();

double get totalInCash => _totalInCash;
String? get selectedOrderId => _selectedOrderId;
CashOrder? get selectedOrder => _selectedOrder;
String get selectedMethod => _selectedMethod;
double get orderSubtotal => _selectedOrder?.total ?? 0.0;
String get cashError => _cashError;
int get paidTodayCount => paidToday.length;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  double get changeDue {
    if (_selectedOrder == null || _receivedAmount < _selectedOrder!.total) {
      return 0.0;
    }
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

  // NOTA: se eliminó agregarCuentaPorCobrar() y su lista interna
  // _pendingOrdersInternal. Insertaban un CashOrder en una lista que ningún
  // getter de esta clase llegaba a leer (pendingOrders/paidToday solo leen
  // de _ordenesProvider.orders), así que era código muerto: no aportaba
  // nada visible y generaba un notifyListeners() redundante. La fuente de
  // verdad real para "cuentas por cobrar" sigue siendo OrdenesProvider,
  // que ya se sincroniza dentro de insertarNuevaComanda().

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
  Future<bool> chargeSelectedOrder() async {
    if (_selectedOrder == null) return false;
    if (_selectedMethod == 'Efectivo' &&
        _receivedAmount < _selectedOrder!.total) {
      _cashError = 'Monto recibido insuficiente.';
      notifyListeners();
      return false;
    }

    // Operación ahora espera la confirmación del servidor y sincroniza el estado
    _setLoading(true);
    _cashError = '';

    final String orderId = _selectedOrder!.id;
    final String metodo = _selectedMethod;
    final double total = _selectedOrder!.total;

    try {
      await _repository.registrarCobro(orderId, metodo, total);

      // Re-sincronizar órdenes y totales desde las fuentes canónicas
      await _ordenesProvider.cargarOrdenes();
      _totalInCash = await _repository.obtenerTotalEnCaja();

      closeSelectedOrderPanel();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error asíncrono en Supabase Caja: $e');
      _cashError = 'Error al cobrar la orden: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
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

CashOrder _mapRestaurantToCashOrder(RestaurantOrder o) {
  final items = o.items
      .map((it) =>
          CashItem(name: it.productName, qty: it.quantity, price: it.unitPrice))
      .toList();

  return CashOrder(
    id: o.id,
    label: o.orderNumber.isNotEmpty ? o.orderNumber : o.tableOrCustomer,
    time: o.time,
    status: o.status,
    itemsCount: o.items.length,
    items: items,
    total: o.totalAmount,
  );
}
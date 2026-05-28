import 'package:flutter/material.dart';
import '../models/provider_payment.dart';
import '../repositories/payment_repository.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentRepository _repository;
  final int pageSize = 10;

  PaymentsProvider(this._repository) {
    cargarPagos(); // Carga inicial
  }

  List<ProviderPayment> _payments = [];
  String _searchTerm = '';
  int _currentPage = 1;

  // --- ESTADOS CENTRALIZADOS DE FLUJO Y RED ---
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS COMPATIBLES CON TU INTERFAZ (proveedores_page.dart) ---
  List<ProviderPayment> get payments => _payments;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // --- FILTRADO Y BÚSQUEDA ---
  List<ProviderPayment> get filteredPayments {
    if (_searchTerm.isEmpty) return _payments;
    return _payments.where((p) {
      final matchProvider = p.provider.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchCategory = p.category.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchProvider || matchCategory;
    }).toList();
  }

  // --- PAGINACIÓN REQUERIDA POR TU UI ---
  List<ProviderPayment> get paginatedPayments {
    final list = filteredPayments;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.skip(start).take(pageSize).toList();
  }

  int get totalPages => (filteredPayments.length / pageSize).ceil().clamp(1, 999999);

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  void setSearch(String val) {
    _searchTerm = val;
    _currentPage = 1;
    notifyListeners();
  }

  // --- ESTADÍSTICAS MÉTRICAS (KPI Cards de tu pantalla) ---
  
  double get todayTotal {
    final String hoy = DateTime.now().toIso8601String().substring(0, 10);
    return _payments
        .where((p) => p.date == hoy)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get todayPaymentsCount {
    final String hoy = DateTime.now().toIso8601String().substring(0, 10);
    return _payments.where((p) => p.date == hoy).length;
  }

  double get weekTotal {
    final ahora = DateTime.now();
    final sieteDiasAntes = ahora.subtract(const Duration(days: 7));
    return _payments.where((p) {
      try {
        final fechaPago = DateTime.parse(p.date);
        return fechaPago.isAfter(sieteDiasAntes) && fechaPago.isBefore(ahora.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthTotal {
    final String mesActual = DateTime.now().toIso8601String().substring(0, 7); // "YYYY-MM"
    return _payments
        .where((p) => p.date.startsWith(mesActual))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get uniqueProvidersCount {
    return _payments.map((p) => p.provider.trim().toLowerCase()).toSet().length;
  }

  // --- LÓGICA DE DATOS SEGURA ---
  Future<void> cargarPagos() async {
    _setLoading(true);
    _clearError();
    try {
      _payments = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando pagos a proveedores: $e');
    } finally { // <--- CORREGIDO AQUÍ: Ahora sí está escrito 'finally' de forma correcta
      _setLoading(false);
    }
  }

  // --- ACCIONES C.R.U.D ADAPTADAS AL DISEÑO ORIGINAL ---
  
  // Ultra-flexible (dynamic) para interceptar el 'InventarioProvider' intruso sin romper la compilación
  Future<bool> addPayment(dynamic arg1, [dynamic arg2]) async {
    _setLoading(true);
    _clearError();
    try {
      ProviderPayment payment;

      if (arg2 is ProviderPayment) {
        payment = arg2;
      } else if (arg1 is ProviderPayment) {
        payment = arg1;
      } else {
        throw Exception('No se detectó un objeto ProviderPayment válido en los argumentos.');
      }

      await _repository.create(payment);
      await cargarPagos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error en addPayment: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePayment(dynamic id, ProviderPayment payment) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, payment);
      await cargarPagos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removePayment(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarPagos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
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
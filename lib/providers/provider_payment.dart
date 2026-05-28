// lib/providers/payments_provider.dart
import 'package:flutter/material.dart';
import '../models/provider_payment.dart';
import '../repositories/payment_repository.dart';
import '../providers/inventario_provider.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  List<ProviderPayment> _payments = [];
  String _searchTerm = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoading = false;

  PaymentsProvider(this._repository) {
    cargarPagos();
  }

  // --- Getters ---
  List<ProviderPayment> get payments => _payments;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;

  List<ProviderPayment> get filteredPayments {
    return _payments
        .where((p) =>
            p.provider.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  List<ProviderPayment> get paginatedPayments {
    final filtered = filteredPayments;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    return filtered.skip(startIndex).take(_pageSize).toList();
  }

  int get totalPages =>
      (filteredPayments.length / _pageSize).ceil().clamp(1, 999999);

  // --- Estadísticas ---
  String get _todayString => DateTime.now().toString().substring(0, 10);

  double get todayTotal => _payments
      .where((p) => p.date == _todayString)
      .fold(0.0, (sum, p) => sum + p.amount);

  int get todayPaymentsCount =>
      _payments.where((p) => p.date == _todayString).length;

  // Nota: Si necesitas weekTotal/monthTotal, implementa aquí la lógica de fechas
  double get weekTotal => 0.0;
  double get monthTotal => 0.0;

  int get uniqueProvidersCount =>
      _payments.map((p) => p.provider).toSet().length;

  // --- Métodos de Acción ---

  void setSearch(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  Future<void> cargarPagos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _payments = await _repository.getAll();
    } catch (e) {
      debugPrint('Error al cargar pagos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Métodos CRUD (Firmas ajustadas a tu UI) ---

  Future<void> addPayment(
      ProviderPayment payment, InventarioProvider inventario) async {
    await _repository.create(payment);
    await cargarPagos();
  }

  Future<void> updatePayment(String id, ProviderPayment payment) async {
    await _repository.update(id, payment);
    await cargarPagos();
  }

  Future<void> removePayment(String id) async {
    await _repository.delete(id);
    await cargarPagos();
  }
}

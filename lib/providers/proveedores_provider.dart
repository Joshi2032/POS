import 'package:flutter/material.dart';

import '../models/provider_payment.dart';
import 'inventario_provider.dart';

class ProveedoresProvider extends ChangeNotifier {
  final int pageSize = 10;
  final List<ProviderPayment> _payments = [];
  String _searchTerm = '';
  int _currentPage = 1;

  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  List<ProviderPayment> get payments => List.unmodifiable(_payments);

  List<ProviderPayment> get filteredPayments {
    if (_searchTerm.isEmpty) return List.unmodifiable(_payments);
    final q = _searchTerm.toLowerCase();
    return _payments.where((payment) {
      return [
        payment.provider,
        payment.category,
        payment.method,
        payment.cashier,
      ].any((value) => value.toLowerCase().contains(q));
    }).toList();
  }

  int get totalPages => (filteredPayments.length / pageSize).ceil().clamp(1, 999999);

  List<ProviderPayment> get paginatedPayments {
    final start = (_currentPage - 1) * pageSize;
    return filteredPayments.skip(start).take(pageSize).toList();
  }

  // Corrección en los folds garantizando que la lectura trate al valor como num
  double get todayTotal {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _payments
        .where((payment) => payment.date == today)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  int get todayPaymentsCount {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _payments.where((payment) => payment.date == today).length;
  }

  double get weekTotal {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _payments
        .where((payment) {
          final date = DateTime.tryParse(payment.date);
          return date != null && date.isAfter(weekAgo);
        })
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double get monthTotal {
    final now = DateTime.now();
    return _payments
        .where((payment) {
          final date = DateTime.tryParse(payment.date);
          return date != null && date.month == now.month && date.year == now.year;
        })
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  int get uniqueProvidersCount {
    return _payments.map((payment) => payment.provider).toSet().length;
  }

  void setSearch(String val) {
    _searchTerm = val;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  // Inyección limpia pasándole un incremento double estándar (ej. 10.0 unidades)
  void addPayment(ProviderPayment payment, InventarioProvider inventario) {
    _payments.insert(0, payment);
    inventario.aumentarStockPorCompra(payment.category, 10.0);
    notifyListeners();
  }

  void updatePayment(String id, ProviderPayment payment) {
    final idx = _payments.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _payments[idx] = payment;
      notifyListeners();
    }
  }

  void removePayment(String id) {
    _payments.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
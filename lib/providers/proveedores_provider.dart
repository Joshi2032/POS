// lib/providers/payments_provider.dart
import 'package:flutter/material.dart';
import '../models/provider_payment.dart';
import '../repositories/payment_repository.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentRepository _repository;
  List<ProviderPayment> _payments = [];
  bool _isLoading = false;

  PaymentsProvider(this._repository) {
    cargarPagos();
  }

  List<ProviderPayment> get payments => _payments;
  bool get isLoading => _isLoading;

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

  Future<void> addPayment(ProviderPayment payment) async {
    await _repository.create(payment);
    await cargarPagos();
  }

  Future<void> updatePayment(String id, ProviderPayment payment) async {
    await _repository.update(payment.copyWith(id: id));
    await cargarPagos();
  }

  Future<void> removePayment(String id) async {
    await _repository.delete(id);
    await cargarPagos();
  }
}
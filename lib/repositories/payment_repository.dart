// lib/repositories/payment_repository.dart
import '../services/supabase_service.dart';
import '../models/provider_payment.dart';

class PaymentRepository {
  final _client = SupabaseService.client;

  Future<List<ProviderPayment>> getAll() async {
    final response = await _client.from('supplier_payments').select().order('date', ascending: false);
    return (response as List).map((json) => ProviderPayment.fromJson(json)).toList();
  }

  Future<void> create(ProviderPayment payment) async {
    await _client.from('supplier_payments').insert(payment.toJson());
  }

  Future<void> update(ProviderPayment payment) async {
    await _client.from('supplier_payments').update(payment.toJson()).eq('id', payment.id);
  }

  Future<void> delete(String id) async {
    await _client.from('supplier_payments').delete().eq('id', id);
  }
}
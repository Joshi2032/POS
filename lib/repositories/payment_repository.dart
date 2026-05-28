import '../services/supabase_service.dart';
import '../models/provider_payment.dart';

class PaymentRepository {
  final _client = SupabaseService.client;
  final String _table = 'supplier_payments';

  Future<List<ProviderPayment>> getAll() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => ProviderPayment.fromJson(json))
        .toList();
  }

  Future<void> create(ProviderPayment payment) async {
    await _client.from(_table).insert(payment.toJson());
  }

  Future<void> update(String id, ProviderPayment payment) async {
    final data = payment.toJson();
    data.remove('id'); // No actualizar el id
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_payment.dart';

class PaymentRepository {
  final SupabaseClient _client;
  final String _table = 'supplier_payments';

  // Inyección limpia mediante constructor
  PaymentRepository(this._client);

  // READ: Obtener todos los pagos a proveedores ordenados
  Future<List<ProviderPayment>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);
          
      return (response as List)
          .map((json) => ProviderPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los pagos a proveedores de Supabase: $e');
    }
  }

  // CREATE: Registrar un nuevo desembolso a proveedor
  Future<void> create(ProviderPayment payment) async {
    try {
      final data = payment.toJson();
      if (payment.id.isEmpty) {
        data.remove('id'); // Permitimos que Supabase gestione la llave primaria si es autogenerada
      }
      await _client.from(_table).insert(data);
    } catch (e) {
      throw Exception('Error al registrar el pago en Supabase: $e');
    }
  }

  // UPDATE: Modificar un pago existente
  Future<void> update(String id, ProviderPayment payment) async {
    try {
      final data = payment.toJson();
      data.remove('id'); // Protegemos la llave primaria de mutaciones
      await _client.from(_table).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el pago a proveedor $id: $e');
    }
  }

  // DELETE: Remover el registro del pago
  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el pago a proveedor $id de Supabase: $e');
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nomina_pago.dart';

class NominaPagoRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos por constructor
  NominaPagoRepository(this._client);

  // READ: Obtener todos los registros de nómina
  Future<List<NominaPago>> getAll() async {
    try {
      final response = await _client
          .from('payroll') // Asegúrate de que coincida con el nombre de tu tabla en Supabase
          .select('*, employees(first_name, last_name)');

      return (response as List).map((json) => NominaPago.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener el historial de nóminas de Supabase: $e');
    }
  }

  // CREATE: Registrar una nueva transacción de nómina
  // CREATE: Registrar una nueva transacción de nómina
  Future<void> create(NominaPago nomina) async {
    try {
      final data = nomina.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('payroll').insert(data);
    } catch (e) {
      throw Exception('Error al registrar el pago de nómina en Supabase: $e');
    }
  }

  // UPDATE: Modificar un registro de nómina existente
  Future<void> update(String id, NominaPago nomina) async {
    try {
      final data = nomina.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('payroll').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el registro de nómina $id: $e');
    }
  }

  // DELETE: Remover un registro de nómina
  Future<void> delete(String id) async {
    try {
      await _client.from('payroll').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el registro de nómina $id de Supabase: $e');
    }
  }
}
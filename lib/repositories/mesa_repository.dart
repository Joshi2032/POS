import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';

class MesaRepository {
  final SupabaseClient _client;

  // Inyección de dependencia por constructor
  MesaRepository(this._client);

  // READ: Obtener todas las mesas
  Future<List<Mesa>> getAll() async {
    try {
      final response = await _client
          .from('tables') // Asegúrate de que coincida con tu tabla en Supabase
          .select('*');

      return (response as List).map((json) => Mesa.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las mesas de Supabase: $e');
    }
  }

  // CREATE: Agregar nueva mesa
  Future<void> create(Mesa mesa) async {
    try {
      await _client.from('tables').insert(mesa.toJson());
    } catch (e) {
      throw Exception('Error al crear la mesa: $e');
    }
  }

  // UPDATE: Actualizar estado o datos de una mesa
  Future<void> update(String id, Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.remove('id'); // Protegemos el ID original
      await _client.from('tables').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar la mesa: $e');
    }
  }

  // DELETE: Eliminar mesa
  Future<void> delete(String id) async {
    try {
      await _client.from('tables').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la mesa: $e');
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gasto.dart';
import '../utils/json_payload_utils.dart';

class GastoRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos por constructor
  GastoRepository(this._client);

  // READ: Obtener todos los gastos
  Future<List<Gasto>> getAll() async {
    try {
      final response = await _client
          .from('expenses')
          .select('*'); // Asegúrate de que coincida con el nombre de tu tabla

      return (response as List).map((json) => Gasto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los gastos de Supabase: $e');
    }
  }

  // CREATE: Registrar un nuevo gasto
  Future<void> create(Gasto gasto) async {
    try {
      final data = gasto.toJson();
      limpiarCamposUuidVacios(data);

      await _client.from('expenses').insert(data);
    } catch (e) {
      throw Exception('Error al registrar el gasto: $e');
    }
}    


  // UPDATE: Modificar un gasto existente
  Future<void> update(String id, Gasto gasto) async {
    try {
      final data = gasto.toJson();
      data.remove('id'); // Protegemos el id para que no sea modificado
      await _client.from('expenses').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el gasto: $e');
    }
  }

  // DELETE: Eliminar un registro de gasto
  Future<void> delete(String id) async {
    try {
      await _client.from('expenses').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el gasto: $e');
    }
  }
}
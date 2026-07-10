import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';

class MesaRepository {
  final SupabaseClient _client;
  MesaRepository(this._client);

  Future<List<Mesa>> getAll() async {
    try {
      // CORRECCIÓN: Nombre real de la tabla
      final response = await _client.from('restaurant_tables').select('*');
      return (response as List).map((json) => Mesa.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener mesas: $e');
    }
  }

  Future<void> create(Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('restaurant_tables').insert(data);
    } catch (e) {
      throw Exception('Error al crear mesa: $e');
    }
  }

  Future<void> update(String id, Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('restaurant_tables').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar mesa: $e');
    }
  }

  /// Actualiza SOLO el estado de la mesa (a diferencia de update(), que
  /// reenvía nombre/capacidad/área tomados de una copia en caché que podría
  /// estar desactualizada si alguien más editó esos campos mientras tanto).
  /// `estado` viene en el formato de UI ('Libre'/'Ocupada'/'Por cobrar', sin
  /// importar mayúsculas) y se traduce al mismo valor que espera la columna
  /// `status`, igual que hace Mesa.toJson().
  Future<void> actualizarEstado(String id, String estado) async {
    try {
      final estadoNormalizado = estado.trim().toLowerCase();

      String statusDb = 'free';
      if (estadoNormalizado == 'ocupada') {
        statusDb = 'occupied';
      } else if (estadoNormalizado == 'por cobrar' ||
          estadoNormalizado == 'cuenta') {
        statusDb = 'pending_payment';
      }

      await _client
          .from('restaurant_tables')
          .update({'status': statusDb}).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el estado de la mesa: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('restaurant_tables').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar mesa: $e');
    }
  }
}
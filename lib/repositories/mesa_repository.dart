import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';
import '../utils/json_payload_utils.dart';

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
      limpiarCamposUuidVacios(data);
      await _client.from('restaurant_tables').insert(data);
    } catch (e) {
      throw Exception('Error al crear mesa: $e');
    }
  }

  // No incluye 'status': editar nombre/capacidad/área no debe tocar el
  // estado. Si mientras el formulario de edición está abierto un mesero
  // ocupa/libera la mesa, un update() de fila completa con el estado
  // capturado al abrir el formulario revertiría ese cambio concurrente. Los
  // cambios de estado van por [actualizarEstado].
  Future<void> update(String id, Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.remove('id');
      data.remove('status');
      limpiarCamposUuidVacios(data);
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
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item.dart';

class InventarioRepository {
  final SupabaseClient _client;

  // Inyección de dependencias por constructor
  InventarioRepository(this._client);

  // READ: Obtener todos los artículos del inventario
  Future<List<InventoryItem>> getAll() async {
    try {
      final response = await _client
          .from('inventory') // Asegúrate de que coincida con el nombre de tu tabla en Supabase
          .select('*');

      return (response as List).map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener el inventario de Supabase: $e');
    }
  }

  // CREATE: Registrar un nuevo insumo/artículo
  Future<void> create(InventoryItem item) async {
    try {
      // Excluimos el 'id' si tu base de datos genera UUIDs de manera automática
      final data = item.toJson();
      if (item.id.isEmpty) {
        data.remove('id');
      }
      await _client.from('inventory').insert(data);
    } catch (e) {
      throw Exception('Error al agregar el artículo al inventario: $e');
    }
  }

  // UPDATE: Modificar datos generales de un artículo
  Future<void> update(String id, InventoryItem item) async {
    try {
      final data = item.toJson();
      data.remove('id'); // Protegemos la llave primaria de modificaciones accidentales
      await _client.from('inventory').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el artículo $id: $e');
    }
  }

  // DELETE: Eliminar un artículo del inventario
  Future<void> delete(String id) async {
    try {
      await _client.from('inventory').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el artículo de inventario $id: $e');
    }
  }

  // LÓGICA DE CONTROL DE STOCK ESPECÍFICA: Actualizar cantidad en Supabase
  Future<void> actualizarStock(String id, double nuevaCantidad) async {
    try {
      await _client
          .from('inventory')
          .update({'stock': nuevaCantidad})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar la cantidad de stock para el artículo $id: $e');
    }
  }

  // LÓGICA DE HISTORIAL: Registrar movimientos de inventario (Kárdex)
  Future<void> registrarMovimiento(String itemId, double diferencia, String razon) async {
    try {
      await _client.from('inventory_movements').insert({
        'inventory_item_id': itemId,
        'quantity_changed': diferencia,
        'reason': razon,
        'movement_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Nota: Si no tienes creada la tabla 'inventory_movements', esto fallará. 
      // Capturamos el error silenciosamente en consola para que no interrumpa el POS si es opcional.
      debugPrint('Advertencia Historial: No se pudo insertar movimiento de auditoría: $e');
    }
  }
}
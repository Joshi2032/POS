import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item.dart';

class InventarioRepository {
  final SupabaseClient _client;
  InventarioRepository(this._client);

  Future<List<InventoryItem>> getAll() async {
    try {
      // CORRECCIÓN: La tabla se llama inventory_items, no inventory
      final response = await _client.from('inventory_items').select('*');
      return (response as List).map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener el inventario: $e');
    }
  }

  Future<void> create(InventoryItem item) async {
    try {
      final data = item.toJson();
      // LIMPIEZA UUID
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('inventory_items').insert(data);
    } catch (e) {
      throw Exception('Error al agregar artículo: $e');
    }
  }

  Future<void> update(String id, InventoryItem item) async {
    try {
      final data = item.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('inventory_items').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar artículo: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('inventory_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar: $e');
    }
  }

  Future<void> actualizarStock(String id, double nuevaCantidad) async {
    try {
      // CORRECCIÓN: Tu esquema dice que la columna es 'quantity', no 'stock'
      await _client.from('inventory_items').update({'quantity': nuevaCantidad}).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }

  Future<void> registrarMovimiento(String itemId, double diferencia, String razon) async {
    try {
      await _client.from('inventory_movements').insert({
        'inventory_item_id': itemId,
        'change_qty': diferencia, // CORRECCIÓN: Tu esquema usa change_qty
        'reason': razon,
        // Eliminamos movement_date porque la BD tiene DEFAULT now() en created_at
      });
    } catch (e) {
      debugPrint('Advertencia Historial: $e');
    }
  }

  /// Incremento/decremento ATÓMICO de stock (a diferencia de actualizarStock,
  /// que sobreescribe con un valor absoluto calculado en el cliente y puede
  /// perder ajustes concurrentes). Usa la función de Postgres
  /// `adjust_inventory_stock` (ver supabase/inventory_functions.sql) para que
  /// el cálculo `quantity + delta` ocurra en el servidor sobre el valor
  /// actual, no sobre una copia potencialmente desactualizada en el cliente.
  /// También registra el movimiento en inventory_movements dentro de la
  /// misma función, así que NO debe llamarse registrarMovimiento aparte.
  Future<double> ajustarStockAtomico(
    String itemId,
    double delta,
    String razon,
  ) async {
    try {
      final resultado = await _client.rpc('adjust_inventory_stock', params: {
        'p_item_id': itemId,
        'p_delta': delta,
        'p_reason': razon,
      });
      return (resultado as num).toDouble();
    } catch (e) {
      throw Exception('Error al ajustar stock de forma atómica: $e');
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_order.dart';

class OrdenRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos por constructor
  OrdenRepository(this._client);

  // READ: Obtener las órdenes activas (ej: que no estén completadas o archivadas)
  Future<List<RestaurantOrder>> getOrdenesActivas() async {
    try {
      // Usamos un select relacional si tu tabla tiene una llave foránea con order_items
      final response = await _client
          .from('orders')
          .select('*, order_items(*)'); 

      return (response as List).map((json) => RestaurantOrder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes de Supabase: $e');
    }
  }

  // CREATE: Insertar la comanda principal y sus productos asociados dentro de una transacción o lote
  Future<void> crearOrden(RestaurantOrder orden, List<Map<String, dynamic>> itemsMap) async {
    try {
      // 1. Preparamos y enviamos los datos de la orden principal
      final ordenData = orden.toJson();
      if (orden.id.isEmpty) {
        ordenData.remove('id'); // Dejamos que Supabase asigne el UUID
      }

      // Insertamos y pedimos de regreso la fila creada para obtener el ID real de la orden
      final responseOrden = await _client
          .from('orders')
          .insert(ordenData)
          .select()
          .single();

      final String orderIdAsignado = responseOrden['id'].toString();

      // 2. Si la comanda contiene artículos, les asociamos el ID de la orden principal y los insertamos
      if (itemsMap.isNotEmpty) {
        final itemsConRelacion = itemsMap.map((item) {
          return {
            ...item,
            'order_id': orderIdAsignado, // Llave foránea de relación
          };
        }).toList();

        await _client.from('order_items').insert(itemsConRelacion);
      }
    } catch (e) {
      throw Exception('Error al procesar e insertar la nueva comanda en Supabase: $e');
    }
  }

  // UPDATE: Cambiar el estado de la comanda (ej: de 'pendiente' a 'preparando' o 'lista')
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    try {
      await _client
          .from('orders')
          .update({'status': nuevoEstado.toLowerCase()})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al modificar el estado de la orden $id: $e');
    }
  }
}
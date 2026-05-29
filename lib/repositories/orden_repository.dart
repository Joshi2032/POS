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
      final response = await _client.from('orders').select('*, order_items(*)');

      return (response as List)
          .map((json) => RestaurantOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes de Supabase: $e');
    }
  }

  Future<List<RestaurantOrder>> getAll() async {
    try {
      // ✅ EL SECRETO ESTÁ EN EL SELECT: '*, order_items(*)'
      // Esto le dice a Supabase: "Trae la orden Y TODOS sus artículos"
      final response = await _client.from('orders').select('*, order_items(*)');

      return (response as List)
          .map((json) => RestaurantOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener órdenes: $e');
    }
  }

  // CREATE: Insertar la comanda principal y sus productos asociados dentro de una transacción o lote
  Future<void> crearOrden(
      RestaurantOrder orden, List<Map<String, dynamic>> itemsMap) async {
    try {
      final Map<String, dynamic> ordenData = orden.toJson();

      // ==========================================
      // LA SOLUCIÓN DEFINITIVA AL ERROR 22P02
      // ==========================================
      // Borramos dinámicamente CUALQUIER campo que sea nulo o un string vacío.
      // Esto limpia 'id', 'table_id', 'waiter_id', 'discount_id', etc., si vienen vacíos.
      // Así Supabase no intentará convertirlos a UUID y usará nulos o sus valores DEFAULT.
      ordenData.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);

      // Insertamos la orden y pedimos el ID generado
      final responseOrden =
          await _client.from('orders').insert(ordenData).select('id').single();

      final String orderIdAsignado = responseOrden['id'].toString();

      // Procesamos los artículos de la comanda
      if (itemsMap.isNotEmpty) {
        final itemsConRelacion = itemsMap.map((item) {
          // Clonamos el mapa para poder modificarlo
          final Map<String, dynamic> itemLimpio =
              Map<String, dynamic>.from(item);

          itemLimpio['order_id'] =
              orderIdAsignado; // Asignamos la llave foránea

          // CORRECCIÓN DE ESQUEMA: Tu base de datos espera 'total_price', no 'total'
          if (itemLimpio.containsKey('total')) {
            itemLimpio['total_price'] = itemLimpio['total'];
            itemLimpio.remove('total');
          }

          // Limpieza nuclear también para los artículos (limpia product_id, combo_id, etc. si van vacíos)
          itemLimpio.removeWhere(
              (key, value) => value == null || value.toString().trim().isEmpty);

          return itemLimpio;
        }).toList();

        await _client.from('order_items').insert(itemsConRelacion);
      }
    } catch (e) {
      throw Exception('Error al insertar comanda en Supabase: $e');
    }
  }

  // UPDATE: Cambiar el estado de la comanda (ej: de 'pendiente' a 'preparando' o 'lista')
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    try {
      await _client
          .from('orders')
          .update({'status': nuevoEstado.toLowerCase()}).eq('id', id);
    } catch (e) {
      throw Exception('Error al modificar el estado de la orden $id: $e');
    }
  }
}

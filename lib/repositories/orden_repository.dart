import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_order.dart';
import '../utils/json_payload_utils.dart';

class OrdenRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos por constructor
  OrdenRepository(this._client);

  // ─── helpers ────────────────────────────────────────────────────────────────

  /// Dado un JSON de orden ya parseado por Supabase, inyecta el nombre del
  /// mesero consultando directamente la tabla profiles.
  /// Se llama DESPUÉS de cargar las órdenes para no bloquear la carga
  /// principal si profiles falla (devuelve la orden sin nombre en ese caso).
  Future<Map<String, String>> _obtenerNombresPorWaiterId(
      List<String> waiterIds) async {
    if (waiterIds.isEmpty) return {};
    try {
      // profiles.user_id es el UUID del auth.user, igual que orders.waiter_id.
      // Esta query SÍ funciona porque es un select directo a profiles en public,
      // sin necesitar cruzar el esquema privado auth.users como intermediario.
      final response = await _client
          .from('profiles')
          .select('user_id, full_name')
          .filter('user_id', 'in', '(${waiterIds.join(',')})');

      final Map<String, String> mapa = {};
      for (final row in (response as List)) {
        final uid = row['user_id']?.toString();
        final nombre = row['full_name']?.toString().trim();
        if (uid != null && nombre != null && nombre.isNotEmpty) {
          mapa[uid] = nombre;
        }
      }
      return mapa;
    } catch (e) {
      debugPrint('ORDEN_REPO: No se pudieron resolver nombres de meseros: $e');
      return {};
    }
  }

  // ─── READ ────────────────────────────────────────────────────────────────────

  // READ: Obtener las órdenes activas (ej: que no estén completadas o archivadas)
  Future<List<RestaurantOrder>> getOrdenesActivas() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*), restaurant_tables(name)');

      final List<dynamic> ordenesData = response as List;

      // Recolectamos los waiter_ids no nulos para resolver sus nombres en batch.
      final waiterIds = ordenesData
          .map((o) => o['waiter_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final nombresMap = await _obtenerNombresPorWaiterId(waiterIds);

      return ordenesData.map((json) {
        // Inyectamos el nombre resuelto directamente en el mapa del JSON
        // para que fromJson() lo encuentre bajo la clave 'waiterName'.
        final uid = json['waiter_id']?.toString();
        if (uid != null && nombresMap.containsKey(uid)) {
          (json as Map<String, dynamic>)['waiterName'] = nombresMap[uid];
        }
        return RestaurantOrder.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes de Supabase: $e');
    }
  }

  Future<List<RestaurantOrder>> getAll() async {
    try {
      // Se pide también la categoría REAL del producto (usada por
      // ReportesProvider para clasificar ventas/rendimiento por categoría,
      // en vez de adivinarla por palabras clave en el nombre).
      final response = await _client.from('orders').select(
          '*, order_items(*, products(categories(name))), restaurant_tables(name)');
      final List<dynamic> ordenesData = response as List<dynamic>;

      debugPrint('✅ ORDEN_REPO: Cantidad de órdenes: ${ordenesData.length}');

      // Batch lookup de nombres de meseros.
      final waiterIds = ordenesData
          .map((o) => o['waiter_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final nombresMap = await _obtenerNombresPorWaiterId(waiterIds);

      return ordenesData.map((json) {
        debugPrint(
            '📄 ORDEN_REPO: Procesando orden: ${json['id']}, items: ${json['order_items']}');
        final uid = json['waiter_id']?.toString();
        if (uid != null && nombresMap.containsKey(uid)) {
          (json as Map<String, dynamic>)['waiterName'] = nombresMap[uid];
        }
        return RestaurantOrder.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('❌ ORDEN_REPO: Error en getAll: $e');
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
      // Limpia 'id', 'table_id', 'waiter_id', 'discount_id', etc. si vienen
      // vacíos, para que Supabase no intente convertirlos a UUID.
      limpiarCamposUuidVacios(ordenData);

      // Insertamos la orden y pedimos el ID generado
      final responseOrden =
          await _client.from('orders').insert(ordenData).select('id').single();

      final String orderIdAsignado = responseOrden['id'].toString();

      // Procesamos los artículos de la comanda
      if (itemsMap.isNotEmpty) {
        try {
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

            // También limpia los artículos (product_id, combo_id, etc. si van vacíos)
            limpiarCamposUuidVacios(itemLimpio);

            return itemLimpio;
          }).toList();

          await _client.from('order_items').insert(itemsConRelacion);
        } catch (e) {
          // La orden ya se creó pero sus items no se pudieron guardar: la
          // eliminamos para no dejar una orden fantasma (con total, sin
          // productos) atorada en caja/mesas.
          try {
            await _client.from('orders').delete().eq('id', orderIdAsignado);
          } catch (_) {
            // Si tampoco se pudo borrar, seguimos y dejamos que el error
            // original se propague; ya se hizo el mejor esfuerzo posible.
          }
          rethrow;
        }

        await _descontarInventarioPorVenta(itemsMap);
      }
    } catch (e) {
      throw Exception('Error al insertar comanda en Supabase: $e');
    }
  }

  /// Descuenta de inventory_items los insumos de receta de los productos
  /// vendidos (ver supabase/inventory_functions.sql). Es "mejor esfuerzo":
  /// si falla (ej. la función RPC no existe todavía porque no se ha corrido
  /// ese script), NO debe bloquear ni revertir la venta, solo se registra
  /// en el log de depuración.
  Future<void> _descontarInventarioPorVenta(
    List<Map<String, dynamic>> itemsMap,
  ) async {
    try {
      final itemsValidos = itemsMap
          .where((item) =>
              item['product_id'] != null &&
              item['product_id'].toString().trim().isNotEmpty)
          .map((item) => {
                'product_id': item['product_id'].toString(),
                'quantity': item['quantity'] ?? 1,
              })
          .toList();

      if (itemsValidos.isEmpty) return;

      await _client.rpc('descontar_inventario_por_venta', params: {
        'p_items': itemsValidos,
      });
    } catch (e) {
      debugPrint(
          'Advertencia: no se pudo descontar el inventario de la venta: $e');
    }
  }

  Future<void> recalcularTotalOrden(String orderId) async {
  try {
    final response = await _client
        .from('order_items')
        .select('total_price, unit_price, quantity')
        .eq('order_id', orderId);

    final items = response as List<dynamic>;

    final nuevoTotal = items.fold<double>(0, (sum, item) {
      final map = item as Map<String, dynamic>;

      final totalPrice = (map['total_price'] as num?)?.toDouble();
      final unitPrice = (map['unit_price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (map['quantity'] as num?)?.toInt() ?? 1;

      return sum + (totalPrice ?? (unitPrice * quantity));
    });

    await _client
        .from('orders')
        .update({
          'subtotal': nuevoTotal,
          'total': nuevoTotal,
        })
        .eq('id', orderId);

    debugPrint('ORDEN_REPO: Total recalculado para $orderId = $nuevoTotal');
  } catch (e) {
    debugPrint('ORDEN_REPO: Error recalculando total de orden $orderId: $e');
    throw Exception('Error recalculando total de orden: $e');
  }
}

Future<RestaurantOrder?> obtenerOrdenActivaPorMesa(String tableId) async {
  final response = await _client
      .from('orders')
      .select('*, order_items(*)')
      .eq('table_id', tableId);

  final ordenes = (response as List)
      .map((e) => RestaurantOrder.fromJson(e))
      .where(
        (o) =>
            o.status != 'pagada' &&
            o.status != 'cancelada',
      )
      .toList();

  if (ordenes.isEmpty) return null;

  return ordenes.first;
}

Future<void> agregarItemsAOrden(
  String orderId,
  List<Map<String, dynamic>> itemsMap,
) async {
  final itemsConRelacion = itemsMap.map((item) {
    final itemLimpio = Map<String, dynamic>.from(item);

    itemLimpio['order_id'] = orderId;

    if (itemLimpio.containsKey('total')) {
      itemLimpio['total_price'] = itemLimpio['total'];
      itemLimpio.remove('total');
    }

    limpiarCamposUuidVacios(itemLimpio);

    return itemLimpio;
  }).toList();

  await _client
      .from('order_items')
      .insert(itemsConRelacion);

  await _descontarInventarioPorVenta(itemsMap);

  // Los productos ya quedaron guardados en este punto. Si el recálculo del
  // total falla (ej. corte de red momentáneo), reintentamos una vez antes
  // de avisar con un mensaje claro de que el total podría estar
  // desactualizado, en vez de dejar la excepción cruda de recalcularTotalOrden.
  try {
    await recalcularTotalOrden(orderId);
  } catch (_) {
    try {
      await recalcularTotalOrden(orderId);
    } catch (e) {
      throw Exception(
        'Los productos se agregaron correctamente, pero no se pudo '
        'actualizar el total de la orden. Refresca la pantalla para '
        'verificarlo. ($e)',
      );
    }
  }
}

  // UPDATE: Cambiar el estado de la comanda (ej: de 'pendiente' a 'preparando' o 'lista')
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    try {
      final estadoNormalized = nuevoEstado.toLowerCase();
      debugPrint(
          'ORDEN_REPO: actualizarEstado id=$id status=$estadoNormalized');
      await _client
          .from('orders')
          .update({'status': estadoNormalized}).eq('id', id);
    } catch (e) {
      debugPrint(
          'ORDEN_REPO: Error al modificar el estado de la orden $id: $e');
      throw Exception('Error al modificar el estado de la orden $id: $e');
    }
  }
}
// lib/repositories/orden_repository.dart
import '../services/supabase_service.dart';
import '../models/restaurant_order.dart';

class OrdenRepository {
  Future<List<RestaurantOrder>> getOrdenesActivas() async {
    // 1. CORRECCIÓN: La tabla se llama 'orders' según tu esquema
    final response = await SupabaseService.client
        .from('orders') 
        .select('*, order_items(*)')
        // Excluimos las canceladas, entregadas y también las "pagadas" 
        // para que desaparezcan de cocina una vez que la caja las cobra
        .neq('status', 'cancelada')
        .neq('status', 'entregada')
        .neq('status', 'pagado')
        .order('created_at', ascending: false); // 2. CORRECCIÓN: Ordenar por 'created_at'
        
    return (response as List).map((json) => RestaurantOrder.fromJson(json)).toList();
  }

  Future<void> crearOrden(RestaurantOrder orden, List<Map<String, dynamic>> items) async {
    // Insertamos la orden en la tabla 'orders'
    await SupabaseService.client
        .from('orders')
        .insert(orden.toJson());

    // Vinculamos el ID de la orden a los items
    final itemsConOrden = items.map((item) {
      item['order_id'] = orden.id; 
      return item;
    }).toList();

    // Guardamos los productos en 'order_items' (Esta tabla sí se llama así en tu esquema)
    if(itemsConOrden.isNotEmpty) {
       await SupabaseService.client.from('order_items').insert(itemsConOrden);
    }
  }

  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    await SupabaseService.client
        .from('orders') // CORRECCIÓN: tabla 'orders'
        .update({'status': nuevoEstado})
        .eq('id', id);
  }
}
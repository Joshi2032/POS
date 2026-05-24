import '../services/supabase_service.dart';
import '../models/restaurant_order.dart';

class OrdenRepository {
  Future<List<RestaurantOrder>> getOrdenesActivas() async {
    // Al añadir '*, order_items(*)', Supabase hace el "Join" automático
    final response = await SupabaseService.client
        .from('restaurant_order')
        .select('*, order_items(*)')
        // Excluimos las canceladas/entregadas si solo quieres ver activas
        .neq('status', 'cancelada')
        .neq('status', 'entregada')
        .order('time', ascending: false);
        
    return (response as List).map((json) => RestaurantOrder.fromJson(json)).toList();
  }

  Future<void> crearOrden(RestaurantOrder orden, List<Map<String, dynamic>> items) async {
    // 1. Insertamos la orden (Supabase respetará el ID generado en Flutter)
    await SupabaseService.client
        .from('restaurant_order')
        .insert(orden.toJson());

    // 2. Vinculamos el ID de la orden a los items
    final itemsConOrden = items.map((item) {
      item['order_id'] = orden.id; 
      return item;
    }).toList();

    // 3. Guardamos los productos en order_items
    if(itemsConOrden.isNotEmpty) {
       await SupabaseService.client.from('order_items').insert(itemsConOrden);
    }
  }

  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    await SupabaseService.client
        .from('restaurant_order')
        .update({'status': nuevoEstado})
        .eq('id', id);
  }
}
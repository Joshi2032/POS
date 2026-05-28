// lib/repositories/inventario_repository.dart
import '../services/supabase_service.dart';
import '../models/inventory_item.dart';

class InventarioRepository {
  final _client = SupabaseService.client;

  // Obtener todos los artículos del inventario
  Future<List<InventoryItem>> getAll() async {
    final response = await _client
        .from('inventory_items')
        .select()
        .order('name');
    return (response as List).map((json) => InventoryItem.fromJson(json)).toList();
  }

  // Actualizar cantidad (se usa después de una compra o venta)
  Future<void> actualizarStock(String id, int nuevaCantidad) async {
    await _client
        .from('inventory_items')
        .update({'quantity': nuevaCantidad})
        .eq('id', id);
  }

  // Registrar un movimiento de inventario (auditoría)
  Future<void> registrarMovimiento(String itemId, int cambio, String razon) async {
    await _client.from('inventory_movements').insert({
      'inventory_item_id': itemId,
      'change_qty': cambio,
      'reason': razon,
    });
  }
}
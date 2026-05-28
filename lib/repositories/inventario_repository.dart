import '../services/supabase_service.dart';
import '../models/inventory_item.dart';

class InventarioRepository {
  final _client = SupabaseService.client;

  Future<List<InventoryItem>> getAll() async {
    final response =
        await _client.from('inventory_items').select().order('name');
    return (response as List)
        .map((json) => InventoryItem.fromJson(json))
        .toList();
  }

  Future<void> create(InventoryItem item) async {
    await _client.from('inventory_items').insert(item.toJson());
  }

  Future<void> update(String id, InventoryItem item) async {
    final data = item.toJson();
    data.remove('id'); // No actualizar el id
    await _client.from('inventory_items').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('inventory_items').delete().eq('id', id);
  }

  Future<void> actualizarStock(String id, double nuevaCantidad) async {
    await _client
        .from('inventory_items')
        .update({'stock': nuevaCantidad}).eq('id', id);
  }

  Future<void> registrarMovimiento(
      String itemId, double cambio, String razon) async {
    await _client.from('inventory_movements').insert({
      'inventory_item_id': itemId,
      'change_qty': cambio,
      'reason': razon,
    });
  }
}

import '../services/supabase_service.dart';
import '../models/product.dart';

class ProductoRepository {
  // READ: Obtener todos
  Future<List<Producto>> getAll() async {
    final response = await SupabaseService.client
        .from('products')
        .select('*, categories(name)');

    return (response as List).map((json) => Producto.fromJson(json)).toList();
  }

  // CREATE: Agregar nuevo
  Future<void> create(Producto product) async {
    await SupabaseService.client.from('products').insert(product.toJson());
  }

  // UPDATE: Actualizar existente
  Future<void> update(Producto product) async {
    await SupabaseService.client
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }

  // DELETE: Eliminar
  Future<void> delete(String id) async {
    await SupabaseService.client.from('products').delete().eq('id', id);
  }
}
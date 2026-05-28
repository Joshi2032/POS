import '../services/supabase_service.dart';
import '../models/product.dart';

class ProductoRepository {
  // READ: Obtener todos con manejo de excepciones
  Future<List<Producto>> getAll() async {
    try {
      final response = await SupabaseService.client
          .from('products')
          .select('*, categories(name)');

      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos de Supabase: $e');
    }
  }

  // CREATE: Agregar nuevo
  Future<void> create(Producto product) async {
    try {
      await SupabaseService.client.from('products').insert(product.toJson());
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // UPDATE: Actualizar existente
  Future<void> update(String id, Producto product) async {
    try {
      final data = product.toJson();
      data.remove('id'); // No actualizar el id
      await SupabaseService.client.from('products').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // DELETE: Eliminar
  Future<void> delete(String id) async {
    try {
      await SupabaseService.client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
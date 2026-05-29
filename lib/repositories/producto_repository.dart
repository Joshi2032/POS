import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductoRepository {
  final SupabaseClient _client;

  ProductoRepository(this._client);

  Future<List<Producto>> getAll() async {
  try {
    // CAMBIO: Select con join a 'categories'
    // La coma después del asterisco es vital: '*, categories(name)'
    final response = await _client
        .from('products')
        .select('*, categories(name)'); 

    return (response as List).map((json) => Producto.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Error al obtener productos: $e');
  }
}

  Future<void> create(Producto product) async {
    try {
      await _client.from('products').insert(product.toJson()); // Ahora toJson existe
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  Future<void> update(String id, Producto product) async {
    try {
      final data = product.toJson();
      await _client.from('products').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
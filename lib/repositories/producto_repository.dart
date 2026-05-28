import 'package:supabase_flutter/supabase_flutter.dart'; // Importamos el tipo oficial de Supabase
import '../models/product.dart';

class ProductoRepository {
  // 1. Declaramos el cliente como una propiedad final
  final SupabaseClient _client;

  // 2. Lo requerimos obligatoriamente en el constructor
  ProductoRepository(this._client);

  // READ: Obtener todos
  Future<List<Producto>> getAll() async {
    try {
      // 3. Reemplazamos la llamada estática por nuestra propiedad local '_client'
      final response = await _client
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
      await _client.from('products').insert(product.toJson());
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // UPDATE: Actualizar existente
  Future<void> update(String id, Producto product) async {
    try {
      final data = product.toJson();
      data.remove('id'); 
      await _client.from('products').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // DELETE: Eliminar
  Future<void> delete(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
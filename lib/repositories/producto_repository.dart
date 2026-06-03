import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductoRepository {
  final SupabaseClient _client;

  ProductoRepository(this._client);

  // NUEVO: Obtener el catálogo real de categorías desde Supabase
  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final response = await _client
          .from('categories')
          .select('id, name')
          .eq('active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<void> createCategoria(String name) async {
    try {
      await _client.from('categories').insert({
        'name': name,
        'active': true,
      });
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  Future<List<Producto>> getAll() async {
    try {
      // El JOIN para traer el nombre de la categoría
      final response =
          await _client.from('products').select('*, categories(name)');
      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  Future<void> create(Producto product) async {
    try {
      final data = product.toJson();
      data.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('products').insert(data);
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  Future<void> update(String id, Producto product) async {
    try {
      final data = product.toJson();
      data.remove('id');
      data.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);
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

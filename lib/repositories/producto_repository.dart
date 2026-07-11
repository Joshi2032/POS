import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../utils/json_payload_utils.dart';

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

  Future<void> updateCategoria(String id, String name) async {
    try {
      await _client.from('categories').update({'name': name}).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> deleteCategoria(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  Future<List<Producto>> getAll() async {
    try {
      // El JOIN para traer el nombre de la categoría
      final response =
    await _client.from('products').select('*, active, categories(name)');
      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  Future<void> toggleActive(String id, bool active) async {
  try {
    await _client
        .from('products')
        .update({'active': active})
        .eq('id', id);
  } catch (e) {
    throw Exception('Error al cambiar estado del producto: $e');
  }
}

  Future<void> create(Producto product) async {
    try {
      final data = product.toJson();
      limpiarCamposUuidVacios(data);
      await _client.from('products').insert(data);
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // No incluye 'active': editar nombre/precio/categoría/etc. no debe tocar
  // si el producto está activo. Si mientras el formulario de edición está
  // abierto alguien más lo activa/desactiva desde el switch rápido de la
  // lista, un update() de fila completa con el 'active' capturado al abrir
  // el formulario revertiría ese cambio concurrente. Los cambios de estado
  // van por [toggleActive].
  Future<void> update(String id, Producto product) async {
    try {
      final data = product.toJson();
      data.remove('id');
      data.remove('active');
      limpiarCamposUuidVacios(data);
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

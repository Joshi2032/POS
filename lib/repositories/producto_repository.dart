// lib/repositories/producto_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/producto.dart';

class ProductoRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Producto>> fetchProductos() async {
    try {
      final response = await _client.from('productos').select();
      return (response as List).map((json) => Producto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  Future<void> insertProducto(Producto producto) async {
    try {
      await _client.from('productos').insert(producto.toJson());
    } catch (e) {
      throw Exception('Error al insertar producto: $e');
    }
  }

  Future<void> updateProducto(String id, Producto producto) async {
    try {
      await _client.from('productos').update(producto.toJson()).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> deleteProducto(String id) async {
    try {
      await _client.from('productos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
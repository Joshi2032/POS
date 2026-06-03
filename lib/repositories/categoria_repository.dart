import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriaRepository {
  final SupabaseClient _client;

  CategoriaRepository(this._client);

  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await _client
          .from('categories')
          .select('id, name, active, created_at')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<void> create(String name) async {
    try {
      await _client.from('categories').insert({
        'name': name,
        'active': true,
      });
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  Future<void> update(String id, String name) async {
    try {
      await _client.from('categories').update({'name': name}).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}

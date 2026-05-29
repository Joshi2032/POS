import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';

class MesaRepository {
  final SupabaseClient _client;
  MesaRepository(this._client);

  Future<List<Mesa>> getAll() async {
    try {
      // CORRECCIÓN: Nombre real de la tabla
      final response = await _client.from('restaurant_tables').select('*');
      return (response as List).map((json) => Mesa.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener mesas: $e');
    }
  }

  Future<void> create(Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('restaurant_tables').insert(data);
    } catch (e) {
      throw Exception('Error al crear mesa: $e');
    }
  }

  Future<void> update(String id, Mesa mesa) async {
    try {
      final data = mesa.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('restaurant_tables').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar mesa: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('restaurant_tables').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar mesa: $e');
    }
  }
}
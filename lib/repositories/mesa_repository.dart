// lib/repositories/mesa_repository.dart
import '../services/supabase_service.dart';
import '../models/mesa.dart';

class MesaRepository {
  final _client = SupabaseService.client;

  Future<List<Mesa>> getAll() async {
    final response = await _client
        .from('restaurant_tables')
        .select()
        .order('area') // Ordena por área
        .order('name'); // Y luego alfabéticamente por nombre

    return (response as List).map((json) => Mesa.fromJson(json)).toList();
  }

  Future<void> create(Mesa mesa) async {
    await _client.from('restaurant_tables').insert(mesa.toJson());
  }

  Future<void> update(String id, Mesa mesa) async {
    final data = mesa.toJson();
    data.remove('id'); // No actualizar el id
    await _client.from('restaurant_tables').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('restaurant_tables').delete().eq('id', id);
  }
}

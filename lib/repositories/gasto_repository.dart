import '../services/supabase_service.dart';
import '../models/gasto.dart';

class GastoRepository {
  final _client = SupabaseService.client;

  Future<List<Gasto>> getAll() async {
    // Ordenamos por fecha descendente (los más recientes primero)
    final response = await _client.from('expenses').select().order('expense_date', ascending: false);
    return (response as List).map((json) => Gasto.fromJson(json)).toList();
  }

  Future<void> create(Gasto gasto) async {
    await _client.from('expenses').insert(gasto.toJson());
  }

  Future<void> update(String id, Gasto gasto) async {
    await _client.from('expenses').update(gasto.toJson()).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}
import '../services/supabase_service.dart';
import '../models/corte_caja.dart';

class CorteCajaRepository {
  final _client = SupabaseService.client;
  final String _table = 'cash_cuts';

  Future<List<CorteCaja>> getAll() async {
    final response =
        await _client.from(_table).select().order('date', ascending: false);
    return (response as List).map((json) => CorteCaja.fromJson(json)).toList();
  }

  Future<void> create(CorteCaja corte) async {
    await _client.from(_table).insert(corte.toJson());
  }

  Future<void> update(String id, CorteCaja corte) async {
    final data = corte.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<CorteCaja?> getById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();
      return CorteCaja.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

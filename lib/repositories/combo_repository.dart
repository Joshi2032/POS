import '../services/supabase_service.dart';
import '../models/combo_item.dart';

class ComboRepository {
  final _client = SupabaseService.client;
  final String _table = 'combos';

  Future<List<ComboItem>> getAll() async {
    final response = await _client.from(_table).select().order('title');
    return (response as List).map((json) => ComboItem.fromJson(json)).toList();
  }

  Future<void> create(ComboItem combo) async {
    await _client.from(_table).insert(combo.toJson());
  }

  Future<void> update(String id, ComboItem combo) async {
    final data = combo.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<ComboItem?> getById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();
      return ComboItem.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

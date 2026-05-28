import '../services/supabase_service.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final _client = SupabaseService.client;
  final String _table = 'recipes';

  Future<List<Recipe>> getAll() async {
    final response = await _client
        .from(_table)
        .select('*, recipe_supplies(*)')
        .order('name');
    return (response as List).map((json) => Recipe.fromJson(json)).toList();
  }

  Future<List<Recipe>> getActivas() async {
    final response = await _client
        .from(_table)
        .select('*, recipe_supplies(*)')
        .eq('active', true)
        .order('name');
    return (response as List).map((json) => Recipe.fromJson(json)).toList();
  }

  Future<void> create(Recipe recipe) async {
    await _client.from(_table).insert(recipe.toJson());
  }

  Future<void> update(String id, Recipe recipe) async {
    final data = recipe.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<Recipe?> getById(String id) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, recipe_supplies(*)')
          .eq('id', id)
          .single();
      return Recipe.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleActiva(String id, bool activa) async {
    await _client.from(_table).update({'active': activa}).eq('id', id);
  }
}

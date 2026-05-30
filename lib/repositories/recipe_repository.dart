import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final SupabaseClient _client;
  RecipeRepository(this._client);

  Future<List<Recipe>> getAll() async {
    try {
      // Descargamos recetas con sus insumos gracias al JOIN
      final response = await _client.from('recipes').select('*, recipe_supplies(*)');
      return (response as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener recetas: $e');
    }
  }

  Future<void> create(Recipe recipe) async {
    try {
      final data = recipe.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      // 1. Insertar receta y recuperar ID
      final response = await _client.from('recipes').insert(data).select('id').single();
      final recipeId = response['id'];

      // 2. Insertar los insumos vinculados a esta receta
      if (recipe.supplies.isNotEmpty) {
        final suppliesData = recipe.supplies.map((s) {
          final sData = s.toJson();
          sData['recipe_id'] = recipeId;
          return sData;
        }).toList();
        await _client.from('recipe_supplies').insert(suppliesData);
      }
    } catch (e) {
      throw Exception('Error al crear la receta: $e');
    }
  }

  Future<void> update(String id, Recipe recipe) async {
    try {
      final data = recipe.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      // 1. Actualizar datos base de la receta
      await _client.from('recipes').update(data).eq('id', id);

      // 2. Borrar insumos viejos
      await _client.from('recipe_supplies').delete().eq('recipe_id', id);

      // 3. Insertar los nuevos insumos
      if (recipe.supplies.isNotEmpty) {
        final suppliesData = recipe.supplies.map((s) {
          final sData = s.toJson();
          sData['recipe_id'] = id;
          return sData;
        }).toList();
        await _client.from('recipe_supplies').insert(suppliesData);
      }
    } catch (e) {
      throw Exception('Error al actualizar la receta: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('recipes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la receta: $e');
    }
  }
}
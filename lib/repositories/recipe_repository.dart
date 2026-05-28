import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final SupabaseClient _client;
  final String _table = 'recipes';

  // Inyección limpia mediante constructor
  RecipeRepository(this._client);

  // READ: Obtener todas las recetas con sus insumos anidados
  Future<List<Recipe>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select('*, recipe_supplies(*)')
          .order('name', ascending: true);
          
      return (response as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las recetas de Supabase: $e');
    }
  }

  // READ FILTERED: Obtener sólo las recetas marcadas como activas
  Future<List<Recipe>> getActives() async {
    try {
      final response = await _client
          .from(_table)
          .select('*, recipe_supplies(*)')
          .eq('active', true)
          .order('name', ascending: true);
          
      return (response as List).map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener recetas activas de Supabase: $e');
    }
  }

  // CREATE: Registrar receta principal e insertar sus insumos asociados en lote
  Future<void> create(Recipe recipe) async {
    try {
      final recipeData = recipe.toJson();
      if (recipe.id.isEmpty) {
        recipeData.remove('id'); // Supabase genera automáticamente el UUID
      }

      // Insertamos y recuperamos la fila generada para enlazar la llave foránea
      final responseRecipe = await _client
          .from(_table)
          .insert(recipeData)
          .select()
          .single();

      final String recipeIdAsignado = responseRecipe['id'].toString();

      // Si la receta cuenta con suministros/insumos asignados, los insertamos en lote
      if (recipe.supplies.isNotEmpty) {
        final suppliesData = recipe.supplies.map((s) {
          final jsonSupply = s.toJson();
          jsonSupply['recipe_id'] = recipeIdAsignado; // Llave foránea relacional
          return jsonSupply;
        }).toList();

        await _client.from('recipe_supplies').insert(suppliesData);
      }
    } catch (e) {
      throw Exception('Error al procesar e insertar la nueva receta en Supabase: $e');
    }
  }

  // UPDATE: Modificar datos de una receta y actualizar su estado estructural
  Future<void> update(String id, Recipe recipe) async {
    try {
      final data = recipe.toJson();
      data.remove('id'); // Protegemos el ID para no corromper la tabla
      
      await _client.from(_table).update(data).eq('id', id);

      // Si tu diseño visual requiere sobreescribir insumos, se puede vaciar e insertar el nuevo lote aquí
      if (recipe.supplies.isNotEmpty) {
        await _client.from('recipe_supplies').delete().eq('recipe_id', id);
        final suppliesData = recipe.supplies.map((s) {
          final jsonSupply = s.toJson();
          jsonSupply['recipe_id'] = id;
          return jsonSupply;
        }).toList();
        await _client.from('recipe_supplies').insert(suppliesData);
      }
    } catch (e) {
      throw Exception('Error al actualizar la receta $id en el servidor: $e');
    }
  }

  // TOGGLE: Alternar el estado lógico de activación sin reescribir toda la fila
  Future<void> toggleActiva(String id, bool activa) async {
    try {
      await _client.from(_table).update({'active': activa}).eq('id', id);
    } catch (e) {
      throw Exception('Error al modificar el estado de activación de la receta $id: $e');
    }
  }

  // DELETE: Remover permanentemente una receta de la cocina
  Future<void> delete(String id) async {
    try {
      // Si tu tabla de Supabase no tiene activada la eliminación en cascada, primero vaciamos sus hijos
      await _client.from('recipe_supplies').delete().eq('recipe_id', id);
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la receta $id de Supabase: $e');
    }
  }

  // BY ID: Localizar una receta por su identificador único
  Future<Recipe?> getById(String id) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, recipe_supplies(*)')
          .eq('id', id)
          .single();
      return Recipe.fromJson(response);
    } catch (e) {
      throw Exception('Error al buscar la receta $id: $e');
    }
  }
}
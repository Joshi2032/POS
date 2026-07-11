import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../utils/json_payload_utils.dart';

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
      limpiarCamposUuidVacios(data);

      // 1. Insertar receta y recuperar ID
      final response = await _client.from('recipes').insert(data).select('id').single();
      final recipeId = response['id'];

      // 2. Insertar los insumos vinculados a esta receta
      if (recipe.supplies.isNotEmpty) {
        try {
          final suppliesData = recipe.supplies.map((s) {
            final sData = s.toJson();
            sData['recipe_id'] = recipeId;
            return sData;
          }).toList();
          await _client.from('recipe_supplies').insert(suppliesData);
        } catch (e) {
          // La receta ya se creó pero sus insumos no se pudieron guardar:
          // la eliminamos para no dejar una receta sin insumos (rompería
          // el descuento de inventario al vender).
          try {
            await _client.from('recipes').delete().eq('id', recipeId);
          } catch (_) {}
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Error al crear la receta: $e');
    }
  }

  Future<void> update(String id, Recipe recipe) async {
    try {
      final data = recipe.toJson();
      data.remove('id');
      limpiarCamposUuidVacios(data);

      // 1. Actualizar datos base de la receta
      await _client.from('recipes').update(data).eq('id', id);

      // 2. Guardamos una copia de los insumos viejos ANTES de borrarlos,
      // por si hay que restaurarlos (si el insert de los nuevos falla justo
      // después de borrar, no queremos dejar la receta sin insumos).
      final viejosResponse = await _client
          .from('recipe_supplies')
          .select('supply_id, supply_name, quantity, unit')
          .eq('recipe_id', id);
      final viejosSupplies =
          (viejosResponse as List).map((e) => Map<String, dynamic>.from(e)).toList();

      await _client.from('recipe_supplies').delete().eq('recipe_id', id);

      // 3. Insertar los nuevos insumos
      if (recipe.supplies.isNotEmpty) {
        try {
          final suppliesData = recipe.supplies.map((s) {
            final sData = s.toJson();
            sData['recipe_id'] = id;
            return sData;
          }).toList();
          await _client.from('recipe_supplies').insert(suppliesData);
        } catch (e) {
          if (viejosSupplies.isNotEmpty) {
            try {
              await _client.from('recipe_supplies').insert(
                    viejosSupplies
                        .map((s) => {
                              'recipe_id': id,
                              'supply_id': s['supply_id'],
                              'supply_name': s['supply_name'],
                              'quantity': s['quantity'],
                              'unit': s['unit'],
                            })
                        .toList(),
                  );
            } catch (_) {}
          }
          rethrow;
        }
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
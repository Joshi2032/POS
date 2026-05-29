import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/combo_item.dart';

class ComboRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos mediante el constructor
  ComboRepository(this._client);

  // READ: Obtener todos los combos activos
  Future<List<ComboItem>> getAll() async {
    try {
      final response = await _client
          .from('combos') // Asegúrate de que coincida con tu tabla en Supabase
          .select('*');

      return (response as List).map((json) => ComboItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los combos de Supabase: $e');
    }
  }

  // CREATE: Registrar un nuevo combo promocional
  Future<void> create(ComboItem combo) async {
    try {
      final data = combo.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('combos').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el combo en Supabase: $e');
    }
  }

  // UPDATE: Modificar la información de un combo existente
  Future<void> update(String id, ComboItem combo) async {
    try {
      final data = combo.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('combos').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el combo $id: $e');
    }
  }

  // DELETE: Eliminar definitivamente un combo
  Future<void> delete(String id) async {
    try {
      await _client.from('combos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el combo $id de Supabase: $e');
    }
  }
}
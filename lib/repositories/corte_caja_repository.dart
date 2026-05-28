import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/corte_caja.dart';
import 'package:flutter/foundation.dart';

class CorteCajaRepository {
  final SupabaseClient _client;
  final String _table = 'cash_cuts';

  // Inyección limpia mediante constructor
  CorteCajaRepository(this._client);

  // READ: Obtener todos los cortes ordenados por fecha descendente
  Future<List<CorteCaja>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('date', ascending: false);
      return (response as List).map((json) => CorteCaja.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los cortes de caja desde Supabase: $e');
    }
  }

  // CREATE: Insertar un arqueo o corte final de turno
  Future<void> create(CorteCaja corte) async {
    try {
      final data = corte.toJson();
      if (corte.id.isEmpty) {
        data.remove('id'); // Dejamos que Supabase asigne la llave primaria UUID
      }
      await _client.from(_table).insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja en Supabase: $e');
    }
  }

  // UPDATE: Actualizar datos informativos de un corte
  Future<void> update(String id, CorteCaja corte) async {
    try {
      final data = corte.toJson();
      data.remove('id'); // Protegemos el ID para no mutar llaves primarias
      await _client.from(_table).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el corte de caja $id: $e');
    }
  }

  // DELETE: Remover un registro de arqueo
  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el corte de caja $id de Supabase: $e');
    }
  }

  // READ SINGLE: Buscar un arqueo por su identificador único
  Future<CorteCaja?> getById(String id) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .single();
      return CorteCaja.fromJson(response);
    } catch (e) {
      debugPrint('No se localizó el arqueo $id: $e');
      return null;
    }
  }
}
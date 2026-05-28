import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_caja.dart';

class MovimientoCajaRepository {
  final SupabaseClient _client;
  final String _table = 'cash_movements';

  // Inyección limpia del cliente mediante constructor
  MovimientoCajaRepository(this._client);

  // READ: Obtener todos los movimientos ordenados por fecha de forma descendente
  Future<List<MovimientoCaja>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('date', ascending: false);
      return (response as List)
          .map((json) => MovimientoCaja.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los movimientos de caja en Supabase: $e');
    }
  }

  // CREATE: Insertar un ingreso o egreso de efectivo
  Future<void> create(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      if (movimiento.id.isEmpty) {
        data.remove('id'); // Permitimos que la base de datos asigne el UUID
      }
      await _client.from(_table).insert(data);
    } catch (e) {
      throw Exception('Error al registrar el movimiento en Supabase: $e');
    }
  }

  // UPDATE: Modificar datos de un registro existente
  Future<void> update(String id, MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      data.remove('id'); // Evitamos modificar la llave primaria
      await _client.from(_table).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el movimiento $id: $e');
    }
  }

  // DELETE: Remover permanentemente un registro de auditoría
  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el movimiento $id de Supabase: $e');
    }
  }

  // FILTER: Consultar un lote específico por día
  Future<List<MovimientoCaja>> getMovimientosPorFecha(String fecha) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('date', fecha)
          .order('date', ascending: false);
      return (response as List)
          .map((json) => MovimientoCaja.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al consultar movimientos por fecha ($fecha): $e');
    }
  }
}
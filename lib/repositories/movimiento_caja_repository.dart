import '../services/supabase_service.dart';
import '../models/movimiento_caja.dart';

class MovimientoCajaRepository {
  final _client = SupabaseService.client;
  final String _table = 'cash_movements';

  Future<List<MovimientoCaja>> getAll() async {
    final response =
        await _client.from(_table).select().order('date', ascending: false);
    return (response as List)
        .map((json) => MovimientoCaja.fromJson(json))
        .toList();
  }

  Future<void> create(MovimientoCaja movimiento) async {
    await _client.from(_table).insert(movimiento.toJson());
  }

  Future<void> update(String id, MovimientoCaja movimiento) async {
    final data = movimiento.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<List<MovimientoCaja>> getMovimientosPorFecha(String fecha) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('date', fecha)
        .order('date', ascending: false);
    return (response as List)
        .map((json) => MovimientoCaja.fromJson(json))
        .toList();
  }
}

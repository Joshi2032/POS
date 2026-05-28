import '../services/supabase_service.dart';
import '../models/empleado.dart';

class EmpleadoRepository {
  final _client = SupabaseService.client;
  final String _table = 'employees';

  Future<List<Empleado>> getAll() async {
    final response = await _client.from(_table).select().order('name');
    return (response as List).map((json) => Empleado.fromJson(json)).toList();
  }

  Future<List<Empleado>> getActivos() async {
    final response =
        await _client.from(_table).select().eq('active', true).order('name');
    return (response as List).map((json) => Empleado.fromJson(json)).toList();
  }

  Future<void> create(Empleado empleado) async {
    await _client.from(_table).insert(empleado.toJson());
  }

  Future<void> update(String id, Empleado empleado) async {
    final data = empleado.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<Empleado?> getById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();
      return Empleado.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleActivo(String id, bool activo) async {
    await _client.from(_table).update({'active': activo}).eq('id', id);
  }
}

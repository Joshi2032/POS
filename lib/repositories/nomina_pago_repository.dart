import '../services/supabase_service.dart';
import '../models/nomina_pago.dart';

class NominaPagoRepository {
  final _client = SupabaseService.client;
  final String _table = 'payroll';

  Future<List<NominaPago>> getAll() async {
    final response =
        await _client.from(_table).select().order('date', ascending: false);
    return (response as List).map((json) => NominaPago.fromJson(json)).toList();
  }

  Future<void> create(NominaPago nomina) async {
    await _client.from(_table).insert(nomina.toJson());
  }

  Future<void> update(String id, NominaPago nomina) async {
    final data = nomina.toJson();
    data.remove('id');
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<List<NominaPago>> getNominasPorEmpleado(String empleadoId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('employee_id', empleadoId)
        .order('date', ascending: false);
    return (response as List).map((json) => NominaPago.fromJson(json)).toList();
  }

  Future<List<NominaPago>> getNominasPorPeriodo(String periodo) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('period', periodo)
        .order('date', ascending: false);
    return (response as List).map((json) => NominaPago.fromJson(json)).toList();
  }
}

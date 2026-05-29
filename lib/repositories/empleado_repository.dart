import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado.dart';

class EmpleadoRepository {
  final SupabaseClient _client;

  EmpleadoRepository(this._client);

  Future<List<Empleado>> getAll() async {
    try {
      final response = await _client.from('employees').select('*');
      return (response as List).map((json) => Empleado.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los empleados de Supabase: $e');
    }
  }

  Future<void> create(Empleado empleado) async {
    try {
      final data = empleado.toJson();
      // Elimina cualquier llave vacía ("") para que se use el DEFAULT de Supabase
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('employees').insert(data);
    } catch (e) {
      throw Exception('Error al registrar al empleado: $e');
    }
  }

  Future<void> update(String id, Empleado empleado) async {
    try {
      final data = empleado.toJson();
      data.remove('id');
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      await _client.from('employees').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el empleado $id: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('employees').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar al empleado $id: $e');
    }
  }
}
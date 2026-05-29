import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado.dart';

class EmpleadoRepository {
  final SupabaseClient _client;

  // Inyección del cliente de base de datos por constructor
  EmpleadoRepository(this._client);

  // READ: Obtener todos los empleados
  Future<List<Empleado>> getAll() async {
    try {
      final response = await _client
          .from('employees') // Asegúrate de que coincida con el nombre de tu tabla en Supabase
          .select('*');

      return (response as List).map((json) => Empleado.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los empleados de Supabase: $e');
    }
  }

  // CREATE: Registrar un nuevo empleado
  Future<void> create(Empleado empleado) async {
    try {
      final data = empleado.toJson();
      // Limpieza de datos nulos o vacíos para evitar error de UUID
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      await _client.from('employees').insert(data);
    } catch (e) {
      throw Exception('Error al registrar al empleado: $e');
    }
  }

  // UPDATE: Actualizar datos de un empleado existente
  Future<void> update(String id, Empleado empleado) async {
    try {
      final data = empleado.toJson();
      data.remove('id'); // Protegemos la llave primaria de modificaciones por error
      await _client.from('employees').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar el empleado $id: $e');
    }
  }

  // DELETE: Eliminar un empleado
  Future<void> delete(String id) async {
    try {
      await _client.from('employees').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar al empleado $id: $e');
    }
  }
}
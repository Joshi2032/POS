import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado.dart';

class EmpleadoRepository {
  final SupabaseClient _client;

  EmpleadoRepository(this._client);

  Future<List<Empleado>> getAll() async {
    try {
      final response = await _client
          .from('employees')
          .select('*')
          .order('first_name');

      return (response as List)
          .map((json) => Empleado.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Error al obtener los empleados de Supabase: $e',
      );
    }
  }

  Future<Empleado?> getByProfileId(String profileId) async {
    try {
      final response = await _client
          .from('employees')
          .select('*')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Empleado.fromJson(response);
    } catch (e) {
      throw Exception(
        'Error al obtener empleado por perfil: $e',
      );
    }
  }

  Future<List<String>> getAreasByEmployeeId(
    String employeeId,
  ) async {
    try {
      final response = await _client
          .from('employee_areas')
          .select('area')
          .eq('employee_id', employeeId)
          .order('area');

      return (response as List)
          .map((json) => json['area']?.toString() ?? '')
          .map((area) => area.trim())
          .where((area) => area.isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      throw Exception(
        'Error al obtener áreas del empleado: $e',
      );
    }
  }

  Future<void> setAreasForEmployee({
    required String employeeId,
    required List<String> areas,
  }) async {
    try {
      final cleanAreas = areas
          .map((area) => area.trim())
          .where((area) => area.isNotEmpty)
          .toSet()
          .toList();

      await _client
          .from('employee_areas')
          .delete()
          .eq('employee_id', employeeId);

      if (cleanAreas.isEmpty) {
        return;
      }

      final data = cleanAreas.map((area) {
        return {
          'employee_id': employeeId,
          'area': area,
        };
      }).toList();

      await _client.from('employee_areas').insert(data);
    } catch (e) {
      throw Exception(
        'Error al asignar áreas al empleado: $e',
      );
    }
  }

  Future<void> create(Empleado empleado) async {
    try {
      final data = empleado.toJson();

      data.removeWhere(
        (key, value) =>
            value == null ||
            value.toString().trim().isEmpty,
      );

      await _client.from('employees').insert(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Ya existe un empleado registrado con ese correo.',
        );
      }

      throw Exception(
        'Error al registrar al empleado: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error al registrar al empleado: $e',
      );
    }
  }

  Future<void> update(
    String id,
    Empleado empleado,
  ) async {
    try {
      final data = empleado.toJson();

      data.remove('id');

      data.removeWhere(
        (key, value) =>
            value == null ||
            value.toString().trim().isEmpty,
      );

      await _client
          .from('employees')
          .update(data)
          .eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Ya existe otro empleado registrado con ese correo.',
        );
      }

      throw Exception(
        'Error al actualizar el empleado: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error al actualizar el empleado $id: $e',
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client
          .from('employees')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception(
        'Error al eliminar al empleado $id: $e',
      );
    }
  }

Future<Empleado?> getByAuthUserId(String authUserId) async {
  try {
    final profileResponse = await _client
        .from('profiles')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();

    if (profileResponse == null) {
      return null;
    }

    final profileId =
        profileResponse['id']?.toString() ?? '';

    if (profileId.isEmpty) {
      return null;
    }

    final employeeResponse = await _client
        .from('employees')
        .select('*')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (employeeResponse == null) {
      return null;
    }

    return Empleado.fromJson(employeeResponse);
  } catch (e) {
    throw Exception(
      'Error al obtener empleado por usuario auth: $e',
    );
  }
}
}
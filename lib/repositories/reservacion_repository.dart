import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservacion.dart';

class ReservacionRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos mediante el constructor
  ReservacionRepository(this._client);

  // Obtener reservaciones filtradas por una fecha específica
  Future<List<Reservacion>> getReservacionesPorFecha(String fecha) async {
    try {
      final response = await _client
          .from('reservations') // Asegúrate de que coincida con el nombre exacto de tu tabla
          .select('*')
          .eq('reservation_date', fecha);

      return (response as List).map((json) => Reservacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reservaciones para la fecha $fecha: $e');
    }
  }

  // Crear un nuevo registro de reservación
  Future<void> crearReservacion(Reservacion reservacion) async {
    try {
      await _client.from('reservations').insert(reservacion.toJson());
    } catch (e) {
      throw Exception('Error al insertar la reservación en Supabase: $e');
    }
  }

  // Actualizar los datos de una reservación existente
  Future<void> actualizarReservacion(String id, Reservacion reservacion) async {
    try {
      final data = reservacion.toJson();
      data.remove('id'); // Protegemos la llave primaria
      await _client.from('reservations').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar la reservación $id: $e');
    }
  }

  // Cambiar únicamente el estado (ej. de 'confirmada' a 'cancelada')
  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    try {
      await _client
          .from('reservations')
          .update({'status': nuevoEstado})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al modificar el estado de la reservación $id: $e');
    }
  }

  // Eliminar definitivamente un registro
  Future<void> eliminarReservacion(String id) async {
    try {
      await _client.from('reservations').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la reservación $id: $e');
    }
  }
}
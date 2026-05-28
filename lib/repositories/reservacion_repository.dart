// lib/repositories/reservacion_repository.dart
import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../models/reservacion.dart';

class ReservacionRepository {
  final _client = SupabaseService.client;

  // Obtiene las reservaciones de un día en específico
  Future<List<Reservacion>> getReservacionesPorFecha(String fecha) async {
    try {
      final response = await _client
          .from('reservations')
          .select()
          .eq('reservation_date', fecha)
          .order('reservation_time', ascending: true);

      return (response as List)
          .map((json) => Reservacion.fromJson(json))
          .toList();
    } catch (e) {
      // Cambio de print a debugPrint
      debugPrint('Error al cargar reservaciones: $e'); 
      return [];
    }
  }

  // Agrega una nueva reservación
  Future<void> crearReservacion(Reservacion reservacion) async {
    await _client.from('reservations').insert(reservacion.toJson());
  }

  // Actualiza los datos de una reservación existente
  Future<void> actualizarReservacion(String id, Reservacion reservacion) async {
    final data = reservacion.toJson();
    data.remove('id'); // No actualizar el id
    await _client.from('reservations').update(data).eq('id', id);
  }

  // Cambia el estado (ej. de "Pendiente" a "Cancelada" o "Completada")
  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    await _client
        .from('reservations')
        .update({'status': nuevoEstado}).eq('id', id);
  }

  // Elimina definitivamente la reservación
  Future<void> eliminarReservacion(String id) async {
    await _client.from('reservations').delete().eq('id', id);
  }
}

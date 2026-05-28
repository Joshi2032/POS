// lib/repositories/caja_repository.dart
import 'package:flutter/foundation.dart';

import '../services/supabase_service.dart';

class CajaRepository {
  // Obtenemos la instancia estática del cliente de Supabase
  final _client = SupabaseService.client;

  /// Obtiene el total de ingresos del día actual
  Future<double> obtenerTotalEnCaja() async {
    try {
      // Obtenemos la fecha de hoy al inicio del día
      final hoy = DateTime.now();
      final inicioDia =
          DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();

      // Consultamos la tabla 'orders' sumando los totales de las órdenes PAGADAS hoy
      // (Asumiendo que 'pagado' es el status que usas en Supabase para órdenes cerradas)
      final response = await _client
          .from('orders')
          .select('total')
          .eq('status', 'pagado')
          .gte('created_at', inicioDia);

      double totalDia = 0.0;

      // Iteramos la respuesta para sumar los totales
      for (var row in response as List<dynamic>) {
        // Aseguramos la conversión a double
        totalDia += (row['total'] ?? 0).toDouble();
      }

      // Devolvemos el total calculado desde la base de datos
      return totalDia;
    } catch (e) {
      // Si falla la conexión o no hay datos, retornamos 0 para no romper la app
      debugPrint('Error al obtener total en caja de Supabase: $e');
      return 0.0;
    }
  }

  /// Registra que una orden ya fue cobrada y con qué método de pago
  /// [orderId] es el ID de la tabla orders
  Future<void> registrarCobro(String orderId, String metodoPago) async {
    try {
      // Actualizamos la orden en Supabase a estado "pagado" y registramos el método de pago
      await _client.from('orders').update({
        'status': 'pagado',
        'payment_method': metodoPago.toLowerCase(), // Ej: 'efectivo', 'tarjeta'
        'paid_at':
            DateTime.now().toIso8601String() // Fecha y hora exacta del cobro
      }).eq('id', orderId); // Apuntamos a la orden específica
    } catch (e) {
      debugPrint('Error al registrar el cobro en Supabase: $e');
      // Podrías lanzar la excepción (throw e;) si quieres manejar el error visualmente en el Provider
    }
  }
}

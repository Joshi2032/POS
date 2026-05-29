import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_caja.dart';
import '../models/corte_caja.dart';

class CajaRepository {
  final SupabaseClient _client;

  // Inyección del cliente de datos por constructor
  CajaRepository(this._client);

  // Obtener el saldo total actual en la caja registradora
  Future<double> obtenerTotalEnCaja() async {
    try {
      // ADVERTENCIA: En tu esquema actual no existe 'cash_register'.
      // Si la tabla no existe, devolveremos 0.0 para que la interfaz no colapse.
      final response = await _client
          .from('cash_register')
          .select('balance')
          .maybeSingle();

      if (response != null && response['balance'] != null) {
        return (response['balance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Advertencia: No se pudo obtener el saldo de caja (¿Falta crear la tabla cash_register?): $e');
      return 0.0;
    }
  }

  // Registrar un cobro de orden directamente en la base de datos
  Future<void> registrarCobro(String orderId, String metodoPago, double total) async {
    // 1. Traducción del método de pago de Español (UI) a Inglés (BD)
    String paymentMethodDb;
    switch (metodoPago.toLowerCase()) {
      case 'tarjeta':
        paymentMethodDb = 'card';
        break;
      case 'transferencia':
        paymentMethodDb = 'transfer';
        break;
      case 'efectivo':
      default:
        paymentMethodDb = 'cash';
    }

    try {
      // 2. Actualizamos la orden asegurando que cumple con los CHECK de Supabase
      final updateQuery = _client.from('orders').update({
        'status': 'paid', // En lugar de 'pagada'
        'payment_method': paymentMethodDb, // 'cash', 'card', o 'transfer'
        'paid_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Si recibimos un UUID real, actualizamos por id; de lo contrario usamos order_number.
      final uuidRegExp = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      
      if (uuidRegExp.hasMatch(orderId)) {
        await updateQuery.eq('id', orderId);
      } else {
        await updateQuery.eq('order_number', orderId);
      }

      // 3. Intentamos insertar el flujo de efectivo correspondiente
      try {
        await _client.from('cash_movements').insert({
          'concept': 'Cobro de Orden #$orderId',
          'type': 'Ingreso',
          'amount': total,
          'date': DateTime.now().toIso8601String().substring(0, 10),
        });
      } catch (e) {
        // Capturamos el error silenciosamente por si la tabla cash_movements aún no está creada
        debugPrint('Advertencia: No se pudo guardar el movimiento de kárdex (¿Falta tabla cash_movements?): $e');
      }
      
    } catch (e) {
      throw Exception('Error al registrar el cobro de la orden $orderId en Supabase: $e');
    }
  }

  // Registrar un corte de caja/arqueo al finalizar el turno
  Future<void> realizarCorte(CorteCaja corte) async {
    try {
      final data = corte.toJson();
      // Limpieza de strings vacíos para UUID
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      // CORRECCIÓN: La tabla real en tu esquema se llama 'cash_register_cuts'
      await _client.from('cash_register_cuts').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja en Supabase: $e');
    }
  }

  // Registrar una entrada o salida de efectivo manual
  Future<void> registrarMovimientoManual(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      await _client.from('cash_movements').insert(data);
    } catch (e) {
      throw Exception('Error al registrar el movimiento manual de caja: $e');
    }
  }
}
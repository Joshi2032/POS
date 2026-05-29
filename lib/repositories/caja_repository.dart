import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_caja.dart';
import '../models/corte_caja.dart';

class CajaRepository {
  final SupabaseClient _client;

  CajaRepository(this._client);

  // Obtener el saldo total actual en la caja registradora (Sumando las órdenes en efectivo de hoy)
  Future<double> obtenerTotalEnCaja() async {
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      
      // Buscamos todas las órdenes pagadas HOY en EFECTIVO
      final response = await _client
          .from('orders')
          .select('total')
          .eq('status', 'paid')
          .eq('payment_method', 'cash')
          .gte('paid_at', hoy);

      double totalEfectivo = 0.0;
      
      if (response != null && response is List) {
        for (var row in response) {
          totalEfectivo += (row['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return totalEfectivo;
    } catch (e) {
      debugPrint('Advertencia: No se pudo calcular el saldo de caja: $e');
      return 0.0;
    }
  }

  // Registrar un cobro de orden directamente en la base de datos
  Future<void> registrarCobro(String orderId, String metodoPago, double total) async {
    String paymentMethodDb = 'cash';
    if (metodoPago.toLowerCase() == 'tarjeta') paymentMethodDb = 'card';
    if (metodoPago.toLowerCase() == 'transferencia') paymentMethodDb = 'transfer';

    try {
      final updateQuery = _client.from('orders').update({
        'status': 'paid',
        'payment_method': paymentMethodDb,
        'paid_at': DateTime.now().toUtc().toIso8601String(),
      });

      final uuidRegExp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      
      if (uuidRegExp.hasMatch(orderId)) {
        await updateQuery.eq('id', orderId);
      } else {
        await updateQuery.eq('order_number', orderId);
      }

      // Intentamos insertar el flujo de efectivo
      try {
        await _client.from('cash_movements').insert({
          'concept': 'Cobro de Orden #$orderId',
          'type': 'Ingreso',
          'amount': total,
          'date': DateTime.now().toIso8601String().substring(0, 10),
        });
      } catch (e) {
        debugPrint('Advertencia: Tabla cash_movements falló: $e');
      }
      
    } catch (e) {
      throw Exception('Error al registrar el cobro: $e');
    }
  }

  // Registrar un corte de caja/arqueo al finalizar el turno
  Future<void> realizarCorte(CorteCaja corte) async {
    try {
      final data = corte.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      await _client.from('cash_register_cuts').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja: $e');
    }
  }

  // Registrar una entrada o salida de efectivo manual
  Future<void> registrarMovimientoManual(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      data.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
      
      await _client.from('cash_movements').insert(data);
    } catch (e) {
      throw Exception('Error al registrar movimiento manual: $e');
    }
  }
}
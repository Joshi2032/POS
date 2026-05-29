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
      // Si manejas una tabla de estado de caja o sumatoria de movimientos, se consulta aquí.
      // Por ahora simulamos la lectura asíncrona segura desde Supabase:
      final response = await _client
          .from(
              'cash_register') // Ajusta al nombre de tu tabla de balance general si aplica
          .select('balance')
          .maybeSingle();

      if (response != null && response['balance'] != null) {
        return (response['balance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      throw Exception(
          'Error al obtener el saldo total de caja de Supabase: $e');
    }
  }

  // Registrar un cobro de orden directamente en la base de datos
  Future<void> registrarCobro(
      String orderId, String metodoPago, double total) async {
    try {
      // 1. Actualizamos el estado de la comanda/factura a pagada
      final updateQuery = _client.from('orders').update({
        'status': 'pagada',
        'payment_method': metodoPago.toLowerCase(),
      });

      // Si recibimos un UUID real, actualizamos por id; de lo contrario usamos order_number.
      final uuidRegExp = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (uuidRegExp.hasMatch(orderId)) {
        await updateQuery.eq('id', orderId);
      } else {
        await updateQuery.eq('order_number', orderId);
      }

      // 2. Insertamos el flujo de efectivo correspondiente en el kárdex/movimientos de caja
      await _client.from('cash_movements').insert({
        'concept': 'Cobro de Orden #$orderId',
        'type': 'Ingreso',
        'amount': total,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
    } catch (e) {
      throw Exception(
          'Error al registrar el cobro de la orden $orderId en Supabase: $e');
    }
  }

  // Registrar un corte de caja/arqueo al finalizar el turno
  Future<void> realizarCorte(CorteCaja corte) async {
    try {
      final data = corte.toJson();
      await _client.from('cash_cuts').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja en Supabase: $e');
    }
  }

  // Registrar una entrada o salida de efectivo manual
  Future<void> registrarMovimientoManual(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      await _client.from('cash_movements').insert(data);
    } catch (e) {
      throw Exception('Error al registrar el movimiento manual de caja: $e');
    }
  }
}

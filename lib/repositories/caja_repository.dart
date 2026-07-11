import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_caja.dart';
import '../models/corte_caja.dart';
import '../utils/mexico_time.dart';
import '../utils/json_payload_utils.dart';

class CajaRepository {
  final SupabaseClient _client;

  CajaRepository(this._client);

  /// Retorna el inicio del día de "hoy" en hora de México, expresado en UTC.
  DateTime _inicioDiaHoyEnUtc() => inicioDeDiaMexicoEnUtc(hoyEnMexico());

  // Obtener el saldo total actual en la caja registradora (Sumando las órdenes en efectivo de hoy)
  Future<double> obtenerTotalEnCaja() async {
    try {
      final inicioUtc = _inicioDiaHoyEnUtc();
      final finUtc = inicioUtc.add(const Duration(days: 1));

      // Buscamos todas las órdenes pagadas HOY (en hora de México) en EFECTIVO.
      // Usamos un rango [inicioUtc, finUtc) en vez de solo gte, para no
      // arrastrar ventas del día siguiente si el corte se hace tarde.
      final response = await _client
          .from('orders')
          .select('total')
          .eq('status', 'paid')
          .eq('payment_method', 'cash')
          .gte('paid_at', inicioUtc.toIso8601String())
          .lt('paid_at', finUtc.toIso8601String());

      double totalEfectivo = 0.0;

      if (response != null && response is List) {
        for (var row in response) {
          totalEfectivo += (row['total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return totalEfectivo;
    } catch (e) {
      throw Exception('Error al calcular el saldo de caja: $e');
    }
  }

  // Resumen de ventas de HOY desglosado por método de pago, para el corte
  // de caja de fin de turno.
  Future<Map<String, dynamic>> obtenerResumenVentasHoy() async {
    try {
      final inicioUtc = _inicioDiaHoyEnUtc();
      final finUtc = inicioUtc.add(const Duration(days: 1));

      final response = await _client
          .from('orders')
          .select('total, payment_method')
          .eq('status', 'paid')
          .gte('paid_at', inicioUtc.toIso8601String())
          .lt('paid_at', finUtc.toIso8601String());

      double cash = 0.0;
      double card = 0.0;
      double transfer = 0.0;
      int totalOrdenes = 0;

      for (final row in (response as List)) {
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        final metodo = row['payment_method']?.toString() ?? 'cash';
        totalOrdenes++;

        switch (metodo) {
          case 'card':
            card += total;
            break;
          case 'transfer':
            transfer += total;
            break;
          default:
            cash += total;
        }
      }

      return {
        'cash': cash,
        'card': card,
        'transfer': transfer,
        'totalOrdenes': totalOrdenes,
      };
    } catch (e) {
      throw Exception('Error al calcular el resumen de ventas de hoy: $e');
    }
  }

  // Total pagado a proveedores HOY. Es un dato complementario para el corte
  // de caja: si falla, no debe impedir cerrar el corte, solo se reporta 0.
  Future<double> obtenerPagosProveedoresHoy() async {
    try {
      final inicioUtc = _inicioDiaHoyEnUtc();
      final finUtc = inicioUtc.add(const Duration(days: 1));

      final response = await _client
          .from('supplier_payments')
          .select('amount')
          .gte('created_at', inicioUtc.toIso8601String())
          .lt('created_at', finUtc.toIso8601String());

      double total = 0.0;
      for (final row in (response as List)) {
        total += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      debugPrint(
          'Advertencia: no se pudo calcular pagos a proveedores de hoy: $e');
      return 0.0;
    }
  }

  // Registrar un cobro de orden directamente en la base de datos.
  // Retorna `true` si el cobro y el movimiento de caja quedaron completos,
  // o `false` si el cobro se realizó pero NO se pudo registrar el
  // movimiento de caja (para que la UI pueda avisar al cajero en vez de
  // ocultar el problema).
 Future<bool> registrarCobro(
  String orderId,
  String metodoPago,
  double totalClienteFallback,
) async {
  String paymentMethodDb = 'cash';

  if (metodoPago.toLowerCase() == 'tarjeta') {
    paymentMethodDb = 'card';
  }

  if (metodoPago.toLowerCase() == 'transferencia') {
    paymentMethodDb = 'transfer';
  }

  try {
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    // 1. Buscar primero la orden para obtener table_id, status y el total
    // REAL guardado en servidor (no el que traiga el cliente en memoria,
    // que puede estar desactualizado si alguien agregó productos después).
    Map<String, dynamic>? ordenData;

    if (uuidRegExp.hasMatch(orderId)) {
      ordenData = await _client
          .from('orders')
          .select('id, order_number, table_id, order_type, status, total')
          .eq('id', orderId)
          .maybeSingle();
    } else {
      ordenData = await _client
          .from('orders')
          .select('id, order_number, table_id, order_type, status, total')
          .eq('order_number', orderId)
          .maybeSingle();
    }

    if (ordenData == null) {
      throw Exception('No se encontró la orden para cobrar: $orderId');
    }

    final String realOrderId = ordenData['id'].toString();
    final String? tableId = ordenData['table_id']?.toString();
    final String? orderNumber = ordenData['order_number']?.toString();
    final String folioLegible =
        (orderNumber != null && orderNumber.trim().isNotEmpty)
            ? orderNumber
            : realOrderId;

    final String statusActual =
        ordenData['status']?.toString().toLowerCase().trim() ?? '';

    // Ya no hay flujo de cocina: cualquier orden creada es cobrable de
    // inmediato, salvo que ya se haya cobrado o cancelado.
    if (statusActual == 'paid' || statusActual == 'pagada') {
      throw Exception('Esta orden ya fue cobrada anteriormente.');
    }
    if (statusActual == 'cancelled' || statusActual == 'cancelada') {
      throw Exception('No se puede cobrar una orden cancelada.');
    }

    final double totalReal =
        (ordenData['total'] as num?)?.toDouble() ?? totalClienteFallback;

    debugPrint(
      'CAJA_REPO: cobrando orden=$realOrderId table_id=$tableId metodo=$paymentMethodDb total=$totalReal status=$statusActual',
    );

    // 2. Marcar orden como pagada, SOLO si su estado sigue siendo el mismo
    // que acabamos de leer (compare-and-swap). Esto evita que dos taps o
    // dos cajeros simultáneos cobren la misma orden dos veces: si otro
    // proceso ya la cambió de estado entre la lectura y este update, aquí
    // no se actualiza ninguna fila y lo detectamos con .select().
    final actualizadas = await _client
        .from('orders')
        .update({
          'status': 'paid',
          'payment_method': paymentMethodDb,
          'paid_at': DateTime.now().toUtc().toIso8601String(),
          'total': totalReal,
          'subtotal': totalReal,
        })
        .eq('id', realOrderId)
        .eq('status', statusActual)
        .select('id');

    if (actualizadas is List && actualizadas.isEmpty) {
      throw Exception(
        'La orden ya fue cobrada o su estado cambió; no se realizó el cobro de nuevo.',
      );
    }

    // 3. Liberar mesa solo después de haber cobrado una orden entregada
    if (tableId != null && tableId.trim().isNotEmpty) {
      await _client.from('restaurant_tables').update({
        'status': 'free',
      }).eq('id', tableId);

      debugPrint('CAJA_REPO: mesa liberada correctamente: $tableId');
    } else {
      debugPrint('CAJA_REPO: la orden no tiene table_id, no se liberó mesa.');
    }

    // 4. Registrar movimiento de caja. Si esto falla, la orden YA quedó
    // cobrada (paso 2 tuvo éxito) — no relanzamos la excepción como si
    // hubiera fallado el cobro completo, solo avisamos con el retorno.
    try {
      await _client.from('cash_movements').insert({
        'concept': 'Cobro de Orden #$folioLegible',
        'type': 'Ingreso',
        'amount': totalReal,
        'date': fechaHoyMexicoStr(),
      });
    } catch (e) {
      debugPrint('Advertencia: Tabla cash_movements falló: $e');
      return false;
    }

    return true;
  } catch (e) {
    throw Exception('Error al registrar el cobro: $e');
  }
}

  // Registrar un corte de caja/arqueo al finalizar el turno
  Future<void> realizarCorte(CorteCaja corte) async {
    try {
      final data = corte.toJson();
      limpiarCamposUuidVacios(data);

      await _client.from('cash_register_cuts').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja: $e');
    }
  }

  // Registrar una entrada o salida de efectivo manual
  Future<void> registrarMovimientoManual(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      limpiarCamposUuidVacios(data);

      await _client.from('cash_movements').insert(data);
    } catch (e) {
      throw Exception('Error al registrar movimiento manual: $e');
    }
  }
}

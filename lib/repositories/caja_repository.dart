import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_caja.dart';
import '../models/corte_caja.dart';

class CajaRepository {
  final SupabaseClient _client;

  CajaRepository(this._client);

  // Offset fijo de México zona Centro (America/Mexico_City) respecto a UTC.
  // México eliminó el horario de verano desde 2022 (excepto franja fronteriza
  // norte), así que este offset es constante todo el año: UTC-6.
  static const Duration _offsetMexicoCentro = Duration(hours: -6);

  /// Retorna el inicio del día de "hoy" en hora de México, expresado en UTC.
  /// Nota: se separó en un método simple en vez de retornar un Record (tupla)
  /// para mantener compatibilidad con Dart 2.18+. Records requieren Dart >=3.0.
  DateTime _inicioDiaHoyEnUtc() {
    final ahoraUtc = DateTime.now().toUtc();
    final ahoraMexico = ahoraUtc.add(_offsetMexicoCentro);
    final inicioDiaMexico = DateTime.utc(
      ahoraMexico.year,
      ahoraMexico.month,
      ahoraMexico.day,
    );
    return inicioDiaMexico.subtract(_offsetMexicoCentro);
  }

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
      debugPrint('Advertencia: No se pudo calcular el saldo de caja: $e');
      return 0.0;
    }
  }

  /// Fecha de "hoy" en hora de México (YYYY-MM-DD), para columnas de tipo
  /// `date` como `cash_movements.date`. Usa el mismo offset fijo que
  /// [_rangoDeHoyEnUtc] para que ambas columnas queden consistentes entre sí.
  String _fechaDeHoyMexico() {
    final ahoraMexico = DateTime.now().toUtc().add(_offsetMexicoCentro);
    final anio = ahoraMexico.year.toString().padLeft(4, '0');
    final mes = ahoraMexico.month.toString().padLeft(2, '0');
    final dia = ahoraMexico.day.toString().padLeft(2, '0');
    return '$anio-$mes-$dia';
  }

  // Registrar un cobro de orden directamente en la base de datos
 Future<void> registrarCobro(
  String orderId,
  String metodoPago,
  double total,
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

    // 1. Buscar primero la orden para obtener table_id antes de pagar
    Map<String, dynamic>? ordenData;

    if (uuidRegExp.hasMatch(orderId)) {
      ordenData = await _client
          .from('orders')
          .select('id, order_number, table_id, order_type')
          .eq('id', orderId)
          .maybeSingle();
    } else {
      ordenData = await _client
          .from('orders')
          .select('id, order_number, table_id, order_type')
          .eq('order_number', orderId)
          .maybeSingle();
    }

    if (ordenData == null) {
      throw Exception('No se encontró la orden para cobrar: $orderId');
    }

    final String realOrderId = ordenData['id'].toString();

    final String? tableId = ordenData['table_id']?.toString();

    debugPrint(
      'CAJA_REPO: cobrando orden=$realOrderId table_id=$tableId metodo=$paymentMethodDb total=$total',
    );

    // 2. Marcar orden como pagada
    await _client.from('orders').update({
      'status': 'paid',
      'payment_method': paymentMethodDb,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
      'total': total,
      'subtotal': total,
    }).eq('id', realOrderId);

    // 3. Liberar mesa si la orden tiene mesa
    if (tableId != null && tableId.trim().isNotEmpty) {
      await _client.from('restaurant_tables').update({
        'status': 'free',
      }).eq('id', tableId);

      debugPrint('CAJA_REPO: mesa liberada correctamente: $tableId');
    } else {
      debugPrint('CAJA_REPO: la orden no tiene table_id, no se liberó mesa.');
    }

    // 4. Registrar movimiento de caja
    try {
      await _client.from('cash_movements').insert({
        'concept': 'Cobro de Orden #$realOrderId',
        'type': 'Ingreso',
        'amount': total,
        'date': _fechaDeHoyMexico(),
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
      data.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);

      await _client.from('cash_register_cuts').insert(data);
    } catch (e) {
      throw Exception('Error al guardar el corte de caja: $e');
    }
  }

  // Registrar una entrada o salida de efectivo manual
  Future<void> registrarMovimientoManual(MovimientoCaja movimiento) async {
    try {
      final data = movimiento.toJson();
      data.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);

      await _client.from('cash_movements').insert(data);
    } catch (e) {
      throw Exception('Error al registrar movimiento manual: $e');
    }
  }
}

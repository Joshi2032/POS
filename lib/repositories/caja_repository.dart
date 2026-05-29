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
  Future<void> registrarCobro(String orderId, String metodo, double total) async {
    // 1. Traducción del método de pago de Español (UI) a Inglés (Base de datos)
    String paymentMethodDb;
    switch (metodo.toLowerCase()) {
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
      await _client
          .from('orders')
          .update({
            // 2. CORRECCIÓN: El estado también debe estar en inglés ('paid' en lugar de 'pagada')
            'status': 'paid', 
            'payment_method': paymentMethodDb,
            'total': total, // Opcional, si deseas asegurar que el total coincida
            'paid_at': DateTime.now().toUtc().toIso8601String(), // Registra la hora exacta del pago
          })
          // 3. OJO: Si 'orderId' es "CMD-75269", debes buscar por 'order_number', 
          // NO por 'id', ya que 'id' es un UUID interno de Supabase.
          .eq('order_number', orderId); 
          
    } catch (e) {
      throw Exception('Error al registrar el cobro en Supabase: $e');
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

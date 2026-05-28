// lib/repositories/caja_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CajaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Simulación de carga del total desde la base de datos
  Future<double> obtenerTotalEnCaja() async {
    // Aquí irá tu lógica real con Supabase:
    // final response = await _client.from('caja').select('total').single();
    // return response['total'] as double;
    
    return 15420.00; // Mantenemos el valor por ahora para no romper la UI
  }

  // Simulación de registro de un cobro en la base de datos
  Future<void> registrarCobro(double total, String metodoPago) async {
    // Aquí irá tu insert en Supabase:
    // await _client.from('movimientos_caja').insert({ ... });
  }
}
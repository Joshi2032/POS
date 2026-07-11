import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_settings.dart';

class SettingsRepository {
  final SupabaseClient _client;
  final String _table = 'restaurant_settings';

  SettingsRepository(this._client);

  Future<RestaurantSettings> obtener() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('id', 'default')
          .maybeSingle();

      if (response == null) {
        // La fila 'default' se crea con el script SQL; si aún no se ha
        // corrido, devolvemos valores en blanco en vez de tronar.
        return RestaurantSettings.fromJson(const {});
      }

      return RestaurantSettings.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener los ajustes del restaurante: $e');
    }
  }

  Future<void> guardar(RestaurantSettings settings) async {
    try {
      await _client
          .from(_table)
          .update({
            ...settings.toJson(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', 'default');
    } catch (e) {
      throw Exception('Error al guardar los ajustes del restaurante: $e');
    }
  }
}

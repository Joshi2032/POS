import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/combo_item.dart';
import '../utils/json_payload_utils.dart';

class ComboRepository {
  final SupabaseClient _client;
  ComboRepository(this._client);

  Future<List<ComboItem>> getAll() async {
    try {
      final response = await _client.from('combos').select('*, combo_items(product_id, products(name))');
      return (response as List).map((json) => ComboItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los combos: $e');
    }
  }

  // --- NUEVA LÓGICA DE TRANSACCIÓN: COMBO + PRODUCTOS ---
  Future<void> create(ComboItem combo, List<String> productIds) async {
  try {
    final data = combo.toJson();

    // Quitamos el ID para que Supabase/PostgreSQL genere el UUID automáticamente
    data.remove('id');

    limpiarCamposUuidVacios(data);

    // 1. Insertamos el combo y obtenemos el UUID generado
    final response = await _client
        .from('combos')
        .insert(data)
        .select('id')
        .single();

    final comboId = response['id'];

    // 2. Insertamos los productos asociados al combo
    if (productIds.isNotEmpty) {
      try {
        final itemsToInsert = productIds.map((pId) => {
              'combo_id': comboId,
              'product_id': pId,
              'quantity': 1,
            }).toList();

        await _client.from('combo_items').insert(itemsToInsert);
      } catch (e) {
        // El combo ya se creó pero sus productos no se pudieron guardar:
        // lo eliminamos para no dejar un combo vendible con 0 productos.
        try {
          await _client.from('combos').delete().eq('id', comboId);
        } catch (_) {}
        rethrow;
      }
    }
  } catch (e) {
    throw Exception('Error al guardar el combo: $e');
  }
}

  Future<void> update(String id, ComboItem combo, List<String> productIds) async {
    try {
      final data = combo.toJson();
      data.remove('id');
      limpiarCamposUuidVacios(data);

      // 1. Actualizar el combo principal
      await _client.from('combos').update(data).eq('id', id);

      // 2. Guardamos una copia de las relaciones viejas ANTES de borrarlas,
      // por si hay que restaurarlas (si el insert de las nuevas falla justo
      // después de borrar, no queremos dejar el combo con 0 productos).
      final viejosResponse = await _client
          .from('combo_items')
          .select('product_id, quantity')
          .eq('combo_id', id);
      final viejosItems =
          (viejosResponse as List).map((e) => Map<String, dynamic>.from(e)).toList();

      await _client.from('combo_items').delete().eq('combo_id', id);

      if (productIds.isNotEmpty) {
        try {
          final itemsToInsert = productIds.map((pId) => {
            'combo_id': id,
            'product_id': pId,
            'quantity': 1
          }).toList();
          await _client.from('combo_items').insert(itemsToInsert);
        } catch (e) {
          if (viejosItems.isNotEmpty) {
            try {
              await _client.from('combo_items').insert(
                    viejosItems
                        .map((item) => {
                              'combo_id': id,
                              'product_id': item['product_id'],
                              'quantity': item['quantity'] ?? 1,
                            })
                        .toList(),
                  );
            } catch (_) {}
          }
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Error al actualizar el combo: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('combos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el combo: $e');
    }
  }
}
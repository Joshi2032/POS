import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final SupabaseClient _client;
  final String _table = 'suppliers';

  SupplierRepository(this._client);

  Future<List<Supplier>> getAll() async {
    try {
      final response =
          await _client.from(_table).select().order('name', ascending: true);
      return (response as List)
          .map((json) => Supplier.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los proveedores de Supabase: $e');
    }
  }

  /// Busca un proveedor existente por nombre (sin distinguir mayúsculas); si
  /// no existe, lo crea. Evita crear un proveedor duplicado cada vez que un
  /// cajero vuelve a escribir el mismo nombre con distinta capitalización.
  Future<Supplier> obtenerOCrearPorNombre(String nombre) async {
    final nombreLimpio = nombre.trim();
    try {
      // ilike() trata '%' y '_' del texto como comodines de patrón, no como
      // caracteres literales: sin escaparlos, un nombre como "Coca_Cola"
      // podría emparejar con un proveedor completamente distinto (el '_'
      // coincide con cualquier caracter). Se busca como lista (no
      // .maybeSingle()) para no lanzar una excepción si, por datos ya
      // existentes sin restricción de unicidad, hubiera 2+ coincidencias.
      final coincidencias = await _client
          .from(_table)
          .select()
          .ilike('name', _escaparPatronLike(nombreLimpio));

      if (coincidencias is List && coincidencias.isNotEmpty) {
        return Supplier.fromJson(coincidencias.first);
      }

      final creado = await _client
          .from(_table)
          .insert({'name': nombreLimpio})
          .select()
          .single();

      return Supplier.fromJson(creado);
    } catch (e) {
      throw Exception(
          'Error al obtener o crear el proveedor "$nombreLimpio": $e');
    }
  }

  /// Escapa los comodines de ILIKE ('%', '_' y la barra invertida como
  /// caracter de escape) para que la búsqueda sea una comparación EXACTA
  /// (insensible a mayúsculas) del texto, no un patrón.
  String _escaparPatronLike(String texto) {
    return texto
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }
}

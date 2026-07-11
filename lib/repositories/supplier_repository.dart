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
      final existente = await _client
          .from(_table)
          .select()
          .ilike('name', nombreLimpio)
          .maybeSingle();

      if (existente != null) {
        return Supplier.fromJson(existente);
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
}

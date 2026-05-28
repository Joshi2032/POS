// lib/providers/inventario_provider.dart
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../repositories/inventario_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final InventarioRepository _repository;
  List<InventoryItem> _items = [];
  String _searchTerm = '';
  bool _isLoading = false;

  InventarioProvider(this._repository) {
    cargarInventario();
  }

  // --- Getters ---
  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;

  // Getter requerido por tu UI: Listado filtrado por nombre
  List<InventoryItem> get filteredItems {
    if (_searchTerm.isEmpty) return _items;
    return _items
        .where((i) => i.name.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  // --- Setters ---
  // Setter requerido por tu UI: Actualiza la búsqueda
  void setSearch(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  // --- Lógica de Datos ---
  Future<void> cargarInventario() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getAll();
    } catch (e) {
      debugPrint('Error al cargar inventario: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Métodos CRUD requeridos por inventario_page.dart ---

  Future<void> addInventoryItem(InventoryItem item) async {
    await _repository.create(item);
    await cargarInventario();
  }

  Future<void> updateInventoryItem(String id, InventoryItem item) async {
    // Usamos copyWith para asegurar que el ID coincida con el que viene de la UI
    final itemActualizado = item.copyWith(id: id);
    await _repository.update(id, itemActualizado);
    await cargarInventario();
  }

  Future<void> removeInventoryItem(String id) async {
    await _repository.delete(id);
    await cargarInventario();
  }

  // --- Lógica de Stock ---

  Future<void> ajustarStock(
      InventoryItem item, double nuevaCantidad, String razon) async {
    try {
      await _repository.actualizarStock(item.id, nuevaCantidad);

      // La diferencia es double, igual que tu modelo
      final diferencia = nuevaCantidad - item.stock;

      await _repository.registrarMovimiento(item.id, diferencia, razon);
      await cargarInventario();
    } catch (e) {
      debugPrint('Error al ajustar stock: $e');
      rethrow;
    }
  }

  Future<void> aumentarStockPorCompra(String itemId, double cantidad) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    await ajustarStock(item, item.stock + cantidad, 'Compra a proveedor');
  }
}

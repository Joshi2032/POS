import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

class InventarioProvider extends ChangeNotifier {
  // Estandarizamos los valores numéricos a double para evitar errores de casteo
  final List<InventoryItem> _inventory = [
    InventoryItem(
      id: 'INS-01',
      name: 'Carne Molida',
      category: 'Carnes',
      stock: 15.0,
      cost: 85.0,
      provider: 'Distribuidora Carnes SA',
    ),
    InventoryItem(
      id: 'INS-02',
      name: 'Pan de Hamburguesa',
      category: 'Panadería',
      stock: 120.0,
      cost: 4.5,
      provider: 'Panificadora Central',
    ),
    InventoryItem(
      id: 'INS-03',
      name: 'Tomate Bola',
      category: 'Verduras',
      stock: 8.0,
      cost: 22.0,
      provider: 'Frutas y Verduras del Centro',
    ),
  ];

  String _search = '';

  List<InventoryItem> get inventory => _inventory;
  String get search => _search;

  List<InventoryItem> get filteredItems {
    return _inventory.where((i) {
      if (_search.isEmpty) return true;
      return i.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  void setSearch(String val) {
    _search = val;
    notifyListeners();
  }

  void addInventoryItem(InventoryItem item) {
    _inventory.add(item);
    notifyListeners();
  }

  void updateInventoryItem(String id, InventoryItem data) {
    final index = _inventory.indexWhere((i) => i.id == id);
    if (index != -1) {
      _inventory[index] = data;
      notifyListeners();
    }
  }

  void removeInventoryItem(String id) {
    _inventory.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // LÓGICA DE INTERCONEXIÓN MEJORADA: Suma de forma segura usando números reales
  void aumentarStockPorCompra(String nombreInsumo, double cantidadAumentar) {
    final index = _inventory.indexWhere(
      (i) => i.name.toLowerCase() == nombreInsumo.toLowerCase(),
    );

    if (index != -1) {
      final currentStock = _inventory[index].stock;
      _inventory[index] = _inventory[index].copyWith(stock: currentStock + cantidadAumentar);
    } else {
      // Si es un insumo nuevo que trajo el proveedor, lo auto-registramos limpio
      _inventory.add(
        InventoryItem(
          id: 'INS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          name: nombreInsumo,
          category: 'Insumos Varios',
          stock: cantidadAumentar,
          cost: 0.0,
          provider: 'Proveedor Nuevo',
        ),
      );
    }
    notifyListeners();
  }
}
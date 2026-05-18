import 'package:flutter/material.dart';

class InventarioProvider extends ChangeNotifier {
  // Lista de insumos iniciales en memoria
  final List<Map<String, dynamic>> _inventory = [
    {
      'id': 'INS-01',
      'name': 'Carne Molida',
      'category': 'Carnes',
      'stock': 15,
      'cost': 85.0,
      'provider': 'Distribuidora Carnes SA'
    },
    {
      'id': 'INS-02',
      'name': 'Pan de Hamburguesa',
      'category': 'Panadería',
      'stock': 120,
      'cost': 4.5,
      'provider': 'Panificadora Central'
    },
    {
      'id': 'INS-03',
      'name': 'Tomate Bola',
      'category': 'Verduras',
      'stock': 8,
      'cost': 22.0,
      'provider': 'Frutas y Verduras del Centro'
    },
  ];

  String _search = '';

  List<Map<String, dynamic>> get inventory => _inventory;
  String get search => _search;

  List<Map<String, dynamic>> get filteredItems {
    return _inventory.where((i) {
      if (_search.isEmpty) return true;
      return (i['name'] as String).toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  void setSearch(String val) {
    _search = val;
    notifyListeners();
  }

  void addInventoryItem(Map<String, dynamic> item) {
    _inventory.add(item);
    notifyListeners();
  }

  void updateInventoryItem(String id, Map<String, dynamic> data) {
    final index = _inventory.indexWhere((i) => i['id'] == id);
    if (index != -1) {
      _inventory[index] = data;
      notifyListeners();
    }
  }

  void removeInventoryItem(String id) {
    _inventory.removeWhere((i) => i['id'] == id);
    notifyListeners();
  }

  // LÓGICA DE INTERCONEXIÓN: Incrementa el stock cuando se compra a un proveedor
  void aumentarStockPorCompra(String nombreInsumo, int cantidadAumentar) {
    final index = _inventory.indexWhere(
      (i) => (i['name'] as String).toLowerCase() == nombreInsumo.toLowerCase()
    );

    if (index != -1) {
      // Si el insumo ya existe en el catálogo, sumamos el stock recibido
      final currentStock = _inventory[index]['stock'] as int;
      _inventory[index]['stock'] = currentStock + cantidadAumentar;
    } else {
      // Si el proveedor nos trae un insumo nuevo que no teníamos, lo auto-registramos
      _inventory.add({
        'id': 'INS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'name': nombreInsumo,
        'category': 'Insumos Varios',
        'stock': cantidadAumentar,
        'cost': 0.0,
        'provider': 'Proveedor Nuevo',
      });
    }
    notifyListeners();
  }
}
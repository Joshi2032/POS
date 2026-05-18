import 'package:flutter/material.dart';

class Insumo {
  final String id;
  final String name;
  final String unit; // Kg, Litros, Piezas
  final double currentStock;
  final double minStock;

  Insumo({required this.id, required this.name, required this.unit, required this.currentStock, required this.minStock});

  Insumo copyWith({String? name, String? unit, double? currentStock, double? minStock}) {
    return Insumo(id: this.id, name: name ?? this.name, unit: unit ?? this.unit, currentStock: currentStock ?? this.currentStock, minStock: minStock ?? this.minStock);
  }
}

class InventarioProvider extends ChangeNotifier {
  List<Insumo> _insumos = [];
  String _searchTerm = '';
  bool _showLowStock = false;

  String get searchTerm => _searchTerm;
  bool get showLowStock => _showLowStock;

  InventarioProvider() {
    _insumos = [
      Insumo(id: 'INS-01', name: 'Carne Molida', unit: 'Kg', currentStock: 15.5, minStock: 20.0), // Bajo stock
      Insumo(id: 'INS-02', name: 'Pan de Hamburguesa', unit: 'Piezas', currentStock: 120, minStock: 50),
      Insumo(id: 'INS-03', name: 'Tomate', unit: 'Kg', currentStock: 8.0, minStock: 10.0), // Bajo stock
      Insumo(id: 'INS-04', name: 'Aceite', unit: 'Litros', currentStock: 25.0, minStock: 10.0),
    ];
  }

  List<Insumo> get filteredInsumos {
    return _insumos.where((i) {
      final matchesSearch = i.name.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesLowStock = _showLowStock ? i.currentStock <= i.minStock : true;
      return matchesSearch && matchesLowStock;
    }).toList();
  }

  int get alertasStock => _insumos.where((i) => i.currentStock <= i.minStock).length;

  void onSearch(String val) { _searchTerm = val; notifyListeners(); }
  void toggleLowStock(bool val) { _showLowStock = val; notifyListeners(); }

  void ajustarStock(String id, double nuevoStock) {
    final idx = _insumos.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _insumos[idx] = _insumos[idx].copyWith(currentStock: nuevoStock);
      notifyListeners();
    }
  }
}
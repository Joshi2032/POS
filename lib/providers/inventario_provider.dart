import 'package:flutter/material.dart';

class InventarioProvider extends ChangeNotifier {
  // Lista mudada desde AppState
  final List<Map<String, dynamic>> _inventory = [];
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
}
import 'package:flutter/material.dart';

class NominasProvider extends ChangeNotifier {
  final int pageSize = 10;
  final List<String> tipos = ['Todos', 'Salario', 'Adelanto', 'Bono', 'Deducción'];

  // En el futuro, esta lista la alimentarás desde Supabase en _initData
  final List<Map<String, dynamic>> _nominas = [];
  
  String _search = '';
  String _selectedType = 'Todos';
  int _currentPage = 1;

  String get search => _search;
  String get selectedType => _selectedType;
  int get currentPage => _currentPage;

  List<Map<String, dynamic>> get nominasFiltradas {
    return _nominas.where((n) {
      final matchSearch = _search.isEmpty ||
          [n['empleado'], n['tipo'], n['metodo']]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(_search.toLowerCase()));
      final matchType = _selectedType == 'Todos' || n['tipo'] == _selectedType;
      return matchSearch && matchType;
    }).toList();
  }

  int get totalPages => (nominasFiltradas.length / pageSize).ceil().clamp(1, 999999);

  List<Map<String, dynamic>> get paginatedNominas {
    final start = (_currentPage - 1) * pageSize;
    return nominasFiltradas.skip(start).take(pageSize).toList();
  }

  double get totalMensual {
    return _nominas.fold(0.0, (sum, item) => sum + (item['monto'] as double));
  }

  void setSearch(String val) {
    _search = val;
    _currentPage = 1;
    notifyListeners();
  }

  void setType(String type) {
    _selectedType = type;
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int newPage) {
    _currentPage = newPage;
    notifyListeners();
  }

  void addNomina(Map<String, dynamic> data) {
    _nominas.add(data);
    notifyListeners();
  }

  void updateNomina(String id, Map<String, dynamic> data) {
    final idx = _nominas.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _nominas[idx] = data;
      notifyListeners();
    }
  }

  void removeNomina(String id) {
    _nominas.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }
}
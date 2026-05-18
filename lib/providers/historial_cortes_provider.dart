import 'package:flutter/material.dart';

class HistorialCortesProvider extends ChangeNotifier {
  final List<String> metodos = ['Todos', 'Efectivo', 'Tarjeta', 'Mixto'];

  // Simulamos los cortes que antes venían de AppState
  final List<Map<String, dynamic>> _cortes = [
    {'id': 'COR-001', 'cajero': 'Laura S.', 'metodo': 'Efectivo', 'fecha': DateTime.now().toIso8601String().split('T').first, 'hora': '14:30', 'monto': 4500.0},
    {'id': 'COR-002', 'cajero': 'Carlos M.', 'metodo': 'Tarjeta', 'fecha': DateTime.now().toIso8601String().split('T').first, 'hora': '16:15', 'monto': 3200.0},
    {'id': 'COR-003', 'cajero': 'Laura S.', 'metodo': 'Mixto', 'fecha': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T').first, 'hora': '22:00', 'monto': 8900.0},
  ];

  String _filterDate = '';
  String _filterMethod = 'Todos';

  String get filterDate => _filterDate;
  String get filterMethod => _filterMethod;

  List<Map<String, dynamic>> get cortesFiltrados {
    return _cortes.where((c) {
      final matchDate = _filterDate.isEmpty || c['fecha'] == _filterDate;
      final matchMethod = _filterMethod == 'Todos' || c['metodo'] == _filterMethod;
      return matchDate && matchMethod;
    }).toList();
  }

  double get totalEfectivo => cortesFiltrados.where((c) => c['metodo'] == 'Efectivo').fold(0.0, (sum, c) => sum + (c['monto'] as double));
  double get totalTarjeta => cortesFiltrados.where((c) => c['metodo'] == 'Tarjeta').fold(0.0, (sum, c) => sum + (c['monto'] as double));
  double get totalMixto => cortesFiltrados.where((c) => c['metodo'] == 'Mixto').fold(0.0, (sum, c) => sum + (c['monto'] as double));
  double get totalFiltrado => cortesFiltrados.fold(0.0, (sum, c) => sum + (c['monto'] as double));

  void setFilterDate(String date) {
    _filterDate = date;
    notifyListeners();
  }

  void setFilterMethod(String method) {
    _filterMethod = method;
    notifyListeners();
  }
}
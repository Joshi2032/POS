import 'package:flutter/material.dart';

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================
class Gasto {
  final String id;
  final String date;
  final String concept;
  final String category;
  final String method;
  final double amount;
  final String notes;

  Gasto({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });

  Gasto copyWith({
    String? id,
    String? date,
    String? concept,
    String? category,
    String? method,
    double? amount,
    String? notes,
  }) {
    return Gasto(
      id: id ?? this.id,
      date: date ?? this.date,
      concept: concept ?? this.concept,
      category: category ?? this.category,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }
}

class GastoForm {
  String date;
  String concept;
  String category;
  String method;
  double amount;
  String notes;

  GastoForm({
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });
}

// ==========================================
// 2. GESTOR DE ESTADO (CEREBRO DEL MÓDULO)
// ==========================================
class GastosProvider extends ChangeNotifier {
  final int pageSize = 10;

  // Variables privadas de estado
  List<Gasto> _gastos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todos';
  int _currentPage = 1;

  // Getters para que la UI pueda leer los datos
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;

  GastosProvider() {
    _initData();
  }

  void _initData() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _gastos = [
      Gasto(id: 'G-0001', date: todayStr, concept: 'Compra de carne y verdura', category: 'Insumos', method: 'Efectivo', amount: 2450.50, notes: 'Proveedor local central'),
      Gasto(id: 'G-0002', date: todayStr, concept: 'Pago de luz CFE', category: 'Servicios', method: 'Transferencia', amount: 4890.00, notes: 'Recibo Bimestral'),
      Gasto(id: 'G-0003', date: todayStr, concept: 'Renta del local comercial', category: 'Renta', method: 'Transferencia', amount: 12000.00, notes: 'Mes en curso'),
      Gasto(id: 'G-0004', date: todayStr, concept: 'Reparación de freidora', category: 'Mantenimiento', method: 'Tarjeta', amount: 850.00, notes: 'Cambio de termopar'),
    ];
  }

  // --- LÓGICA COMPUTADA (Matemáticas y Filtros) ---
  List<Gasto> get filteredGastos {
    final s = _searchTerm.trim().toLowerCase();
    final category = _selectedCategory;
    
    return _gastos.where((g) {
      final matchesSearch = s.isEmpty ||
          g.concept.toLowerCase().contains(s) ||
          g.category.toLowerCase().contains(s) ||
          g.method.toLowerCase().contains(s);

      final matchesCategory = category == 'Todos' || g.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Gasto> get paginatedGastos {
    final list = filteredGastos;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    final end = (start + pageSize) > list.length ? list.length : (start + pageSize);
    return list.sublist(start, end);
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return _gastos.fold(0.0, (sum, g) {
      final d = DateTime.tryParse(g.date);
      if (d != null && d.month == now.month && d.year == now.year) {
        return sum + g.amount;
      }
      return sum;
    });
  }

  double get totalAccumulated => _gastos.fold(0.0, (sum, g) => sum + g.amount);
  int get totalPages => (filteredGastos.length / pageSize).ceil();
  int get totalGastosLength => _gastos.length;

  // --- ACCIONES (Mutaciones que avisan a la UI) ---
  void onSearch(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void seleccionarCategoria(String categoria) {
    _selectedCategory = categoria;
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int newPage) {
    _currentPage = newPage;
    notifyListeners();
  }

  void crearGasto(GastoForm formState) {
    final next = _gastos.length + 1;
    final nuevoGasto = Gasto(
      id: 'G-${next.toString().padLeft(4, '0')}',
      date: formState.date,
      concept: formState.concept,
      category: formState.category,
      method: formState.method,
      amount: formState.amount,
      notes: formState.notes,
    );
    _gastos.insert(0, nuevoGasto);
    notifyListeners();
  }

  void actualizarGasto(String id, GastoForm formState) {
    final idx = _gastos.indexWhere((x) => x.id == id);
    if (idx != -1) {
      _gastos[idx] = _gastos[idx].copyWith(
        date: formState.date,
        concept: formState.concept,
        category: formState.category,
        method: formState.method,
        amount: formState.amount,
        notes: formState.notes,
      );
      notifyListeners();
    }
  }

  void eliminarGasto(String id) {
    _gastos.removeWhere((x) => x.id == id);
    notifyListeners();
  }
}
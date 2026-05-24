import 'package:flutter/material.dart';
import '../models/gasto.dart';
import '../repositories/gasto_repository.dart';

class GastosProvider extends ChangeNotifier {
  final GastoRepository _repository;
  final int pageSize = 10;

  List<Gasto> _gastos = [];
  String _searchTerm = '';
  String _selectedCategory = 'Todos';
  int _currentPage = 1;

  GastosProvider(this._repository) {
    cargarGastos();
  }

  // Getters
  List<Gasto> get gastos => _gastos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;

  // --- MÉTODOS CRUD ---
  Future<void> cargarGastos() async {
    _gastos = await _repository.getAll();
    notifyListeners();
  }

  Future<void> crearGasto(GastoForm formState) async {
    final nuevoGasto = Gasto(
      date: formState.date,
      concept: formState.concept,
      category: formState.category,
      method: formState.method,
      amount: formState.amount,
      notes: formState.notes,
    );
    await _repository.create(nuevoGasto);
    await cargarGastos();
  }

  Future<void> actualizarGasto(String id, GastoForm formState) async {
    final gastoActualizado = Gasto(
      date: formState.date,
      concept: formState.concept,
      category: formState.category,
      method: formState.method,
      amount: formState.amount,
      notes: formState.notes,
    );
    await _repository.update(id, gastoActualizado);
    await cargarGastos();
  }

  Future<void> eliminarGasto(String id) async {
    await _repository.delete(id);
    await cargarGastos();
  }

  // --- FILTROS Y COMPUTADOS ---
  List<Gasto> get filteredGastos {
    final s = _searchTerm.trim().toLowerCase();
    final category = _selectedCategory;
    
    return _gastos.where((g) {
      final matchesSearch = s.isEmpty ||
          g.concept.toLowerCase().contains(s) ||
          g.category.toLowerCase().contains(s) ||
          (g.method?.toLowerCase().contains(s) ?? false);

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
}
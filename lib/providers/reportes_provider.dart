import 'package:flutter/material.dart';

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================
class VentaReporte {
  final String id;
  final String date;
  final String concept;
  final String category;
  final double amount;
  final String paymentMethod;

  VentaReporte({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.amount,
    required this.paymentMethod,
  });
}

// ==========================================
// 2. GESTOR DE ESTADO (CEREBRO DEL MÓDULO)
// ==========================================
class ReportesProvider extends ChangeNotifier {
  final int pageSize = 10;
  final List<String> periodos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];
  final List<String> categoriasFiltro = ['Todos', 'Alimentos', 'Bebidas', 'Combos', 'Otros'];

  // Variables de estado
  List<VentaReporte> _historialVentas = [];
  String _selectedPeriodo = 'Este Mes';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  int _currentPage = 1;

  // Getters para la UI
  String get selectedPeriodo => _selectedPeriodo;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;

  ReportesProvider() {
    _initData();
  }

  void _initData() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _historialVentas = [
      VentaReporte(id: 'V-001', date: todayStr, concept: 'Paquete Familiar + Bebidas', category: 'Combos', amount: 450.00, paymentMethod: 'Tarjeta'),
      VentaReporte(id: 'V-002', date: todayStr, concept: 'Orden de Tacos de Asada (3)', category: 'Alimentos', amount: 105.00, paymentMethod: 'Efectivo'),
      VentaReporte(id: 'V-003', date: todayStr, concept: 'Mezcal Artesanal Copa', category: 'Bebidas', amount: 75.00, paymentMethod: 'Efectivo'),
      VentaReporte(id: 'V-004', date: todayStr, concept: 'Hamburguesa Zapata Especial', category: 'Alimentos', amount: 120.00, paymentMethod: 'Transferencia'),
      VentaReporte(id: 'V-005', date: todayStr, concept: 'Agua de Jamaica Litro', category: 'Bebidas', amount: 40.00, paymentMethod: 'Tarjeta'),
    ];
  }

  // --- LÓGICA COMPUTADA (Matemáticas y Filtros) ---
  List<VentaReporte> get filteredVentas {
    final query = _searchTerm.trim().toLowerCase();
    final cat = _selectedCategory;
    
    return _historialVentas.where((v) {
      final matchesSearch = query.isEmpty ||
          v.concept.toLowerCase().contains(query) ||
          v.id.toLowerCase().contains(query) ||
          v.paymentMethod.toLowerCase().contains(query);

      final matchesCategory = cat == 'Todos' || v.category == cat;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<VentaReporte> get paginatedVentas {
    final list = filteredVentas;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    final end = (start + pageSize) > list.length ? list.length : (start + pageSize);
    return list.sublist(start, end);
  }

  int get totalPages => (filteredVentas.length / pageSize).ceil();

  // MÉTRICAS FINANCIERAS
  double get totalIngresos => filteredVentas.fold(0.0, (sum, v) => sum + v.amount);
  int get totalTransacciones => filteredVentas.length;
  double get ticketPromedio => totalTransacciones > 0 ? totalIngresos / totalTransacciones : 0.0;

  double get ingresosEfectivo => filteredVentas
      .where((v) => v.paymentMethod == 'Efectivo')
      .fold(0.0, (sum, v) => sum + v.amount);

  double get ingresosTarjeta => filteredVentas
      .where((v) => v.paymentMethod == 'Tarjeta' || v.paymentMethod == 'Transferencia')
      .fold(0.0, (sum, v) => sum + v.amount);

  double get porcentajeEfectivo => totalIngresos > 0 ? ingresosEfectivo / totalIngresos : 0;
  double get porcentajeTarjeta => totalIngresos > 0 ? ingresosTarjeta / totalIngresos : 0;


  // --- ACCIONES MUTADORAS ---
  void onSearch(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void cambiarPeriodo(String periodo) {
    _selectedPeriodo = periodo;
    _currentPage = 1;
    // Aquí podrías disparar una petición al servidor para traer los datos de ese periodo
    notifyListeners();
  }

  void cambiarCategoria(String categoria) {
    _selectedCategory = categoria;
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int newPage) {
    _currentPage = newPage;
    notifyListeners();
  }
}
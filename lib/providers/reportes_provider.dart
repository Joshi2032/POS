import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';

// ==========================================
// 1. MODELOS DE DATOS (Mantenemos tu firma exacta)
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
// 2. GESTOR DE ESTADO CONECTADO A SUPABASE
// ==========================================
class ReportesProvider extends ChangeNotifier {
  final OrdenRepository _ordenRepository;
  final int pageSize = 10;
  final List<String> periodos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];
  final List<String> categoriasFiltro = ['Todos', 'Alimentos', 'Bebidas', 'Combos', 'Otros'];

  // Variables de control de interfaz asíncrona
  bool _isLoading = false;
  String? _errorMessage;

  // Variables de estado
  List<VentaReporte> _historialVentas = [];
  String _selectedPeriodo = 'Este Mes';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  int _currentPage = 1;

  // Getters para la UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriodo => _selectedPeriodo;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;

  // Recibimos el repositorio core de órdenes en el constructor
  ReportesProvider(this._ordenRepository) {
    cargarReporteDeVentas();
  }

  // --- OBTENCIÓN ASÍNCRONA DESDE SUPABASE ---
  Future<void> cargarReporteDeVentas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic repo = _ordenRepository;
      
      // Consultamos dinámicamente según los métodos disponibles en tu repositorio
      List<dynamic> rawOrders = [];
      try {
        rawOrders = await repo.getAll();
      } catch (_) {
        try {
          rawOrders = await repo.obtenerTodos();
        } catch (_) {
          rawOrders = [];
        }
      }

      final ahora = DateTime.now();
      final hoyStr = ahora.toIso8601String().substring(0, 10);
      final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final inicioSemana = DateTime(lunesDeEstaSemana.year, lunesDeEstaSemana.month, lunesDeEstaSemana.day);
      final mesActualStr = ahora.toIso8601String().substring(0, 7);

      List<VentaReporte> ventasProcesadas = [];

      for (var orden in rawOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
          
          final String idOrd = (rawJson['id'] ?? rawJson['codigo'] ?? '').toString();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String metodoPago = rawJson['payment_method'] ?? rawJson['metodo_pago'] ?? 'Efectivo';

          // Extraemos los artículos para generar el concepto textual correlativo
          final items = rawJson['items'] ?? rawJson['detalles'] ?? [];
          String conceptoConstruido = '';
          String categoriaPrincipal = 'Otros';

          if (items is List && items.isNotEmpty) {
            final listaNombres = items.map((i) => (i['product_name'] ?? i['nombre'] ?? '').toString()).toList();
            conceptoConstruido = listaNombres.join(', ');
            
            // Evaluamos la categoría del primer artículo para clasificar la venta
            final String rawCat = (items.first['category'] ?? items.first['categoria'] ?? '').toString().toLowerCase();
            if (rawCat.contains('alim') || rawCat.contains('parri') || rawCat.contains('comid')) {
              categoriaPrincipal = 'Alimentos';
            } else if (rawCat.contains('beb') || rawCat.contains('toma')) {
              categoriaPrincipal = 'Bebidas';
            } else if (rawCat.contains('comb') || rawCat.contains('paq')) {
              categoriaPrincipal = 'Combos';
            }
          } else {
            conceptoConstruido = 'Consumo General';
          }

          final fechaOrd = DateTime.parse(dateStr);

          // Filtrado temporal en base al selector de periodos
          bool pasaFiltroTiempo = false;
          if (_selectedPeriodo == 'Hoy') {
            pasaFiltroTiempo = dateStr.startsWith(hoyStr);
          } else if (_selectedPeriodo == 'Esta Semana') {
            pasaFiltroTiempo = fechaOrd.isAfter(inicioSemana.subtract(const Duration(seconds: 1)));
          } else if (_selectedPeriodo == 'Este Mes') {
            pasaFiltroTiempo = dateStr.startsWith(mesActualStr);
          } else {
            pasaFiltroTiempo = true; // Histórico
          }

          if (pasaFiltroTiempo) {
            ventasProcesadas.add(
              VentaReporte(
                id: idOrd.length > 6 ? idOrd.substring(idOrd.length - 6) : idOrd,
                date: dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr,
                concept: conceptoConstruido,
                category: categoriaPrincipal,
                amount: totalValue,
                paymentMethod: metodoPago,
              ),
            );
          }
        } catch (_) {}
      }

      _historialVentas = ventasProcesadas;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error procesando reportes de ventas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LÓGICA COMPUTADA (Filtros y Matemáticas intactas de tu diseño) ---
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

  // Métricas de visualización y KPIs en tarjetas
  double get totalIngresos => filteredVentas.fold(0.0, (sum, v) => sum + v.amount);
  int get totalTransacciones => filteredVentas.length;
  double get ticketPromedio => totalTransacciones > 0 ? totalIngresos / totalTransacciones : 0.0;

  double get ingresosEfectivo => filteredVentas
      .where((v) => v.paymentMethod.toLowerCase() == 'efectivo')
      .fold(0.0, (sum, v) => sum + v.amount);

  double get ingresosTarjeta => filteredVentas
      .where((v) => v.paymentMethod.toLowerCase() == 'tarjeta' || 
                    v.paymentMethod.toLowerCase() == 'transferencia' || 
                    v.paymentMethod.toLowerCase() == 'crédito')
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
    if (_selectedPeriodo == periodo) return;
    _selectedPeriodo = periodo;
    _currentPage = 1;
    // Volvemos a procesar de forma automática aplicando los nuevos filtros temporales
    cargarReporteDeVentas();
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
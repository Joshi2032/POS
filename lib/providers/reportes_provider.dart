import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';
import '../models/restaurant_order.dart';
import '../models/order_item.dart';

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

class ProductoRendimiento {
  final String nombre;
  final String categoria;
  int unidadesVendidas;
  double montoTotal;

  ProductoRendimiento({
    required this.nombre,
    required this.categoria,
    required this.unidadesVendidas,
    required this.montoTotal,
  });
}

class ReportesProvider extends ChangeNotifier {
  final OrdenRepository _ordenRepository;
  final int pageSize = 10;
  final List<String> periodos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];

  // Antes era una lista fija ('Alimentos'/'Bebidas'/'Combos'/'Otros') que no
  // tenía por qué coincidir con las categorías reales que el negocio define
  // en Productos > Categoría. Ahora se arma dinámicamente con las
  // categorías realmente presentes en las ventas cargadas.
  List<String> get categoriasFiltro {
    final categoriasReales = _historialVentas
        .map((v) => v.category)
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Todos', ...categoriasReales];
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<VentaReporte> _historialVentas = [];
  List<ProductoRendimiento> _productosRendimiento = [];
  String _selectedPeriodo = 'Este Mes';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  int _currentPage = 1;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriodo => _selectedPeriodo;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  List<ProductoRendimiento> get productosRendimiento => _productosRendimiento;

  ReportesProvider(this._ordenRepository) {
    cargarReporteDeVentas();
  }

  // Usa la categoría REAL asignada al producto en el catálogo
  // (Productos > Categoría). Solo si el producto ya no existe o no tiene
  // categoría asignada (categoryName == null) se recurre a un respaldo por
  // palabras clave, para no dejar el reporte sin ninguna categoría.
  String _resolverCategoria(OrderItem item) {
    final categoriaReal = item.categoryName?.trim();
    if (categoriaReal != null && categoriaReal.isNotEmpty) {
      return categoriaReal;
    }

    final rawName = item.productName.toLowerCase();
    if (rawName.contains('arrachera') ||
        rawName.contains('t-bone') ||
        rawName.contains('plato') ||
        rawName.contains('corte')) {
      return 'Alimentos';
    } else if (rawName.contains('cerveza') ||
        rawName.contains('refresco') ||
        rawName.contains('agua')) {
      return 'Bebidas';
    } else if (rawName.contains('combo') || rawName.contains('paquete')) {
      return 'Combos';
    }
    return 'Sin categoría';
  }

  Future<void> cargarReporteDeVentas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<RestaurantOrder> ordenes = [];

      try {
        ordenes = await _ordenRepository.getAll();
        debugPrint('✅ REPORTES: Órdenes obtenidas: ${ordenes.length}');
      } catch (e) {
        debugPrint('❌ REPORTES: Error obteniendo órdenes: $e');
        ordenes = [];
      }

      if (ordenes.isEmpty) {
        debugPrint('⚠️ REPORTES: No hay órdenes disponibles');
        _historialVentas = [];
        _productosRendimiento = [];
      } else {
        final ahora = DateTime.now();
        final hoyStr = ahora.toIso8601String().substring(0, 10);
        final lunesDeEstaSemana =
            ahora.subtract(Duration(days: ahora.weekday - 1));
        final inicioSemana = DateTime(lunesDeEstaSemana.year,
            lunesDeEstaSemana.month, lunesDeEstaSemana.day);
        final mesActualStr = ahora.toIso8601String().substring(0, 7);

        List<VentaReporte> ventasProcesadas = [];
        final Map<String, ProductoRendimiento> mapaProductosFiltro = {};

        debugPrint(
            '🔍 REPORTES: Procesando órdenes para período: $_selectedPeriodo');

        for (var orden in ordenes) {
          try {
            final String idOrd = orden.id;
            final String dateStr = orden.time;
            final double totalValue = orden.totalAmount;

            debugPrint(
                '📦 REPORTES: Orden $idOrd, items: ${orden.items.length}, total: $totalValue, fecha: $dateStr');

            // Construir concepto desde los nombres de productos
            String conceptoConstruido = '';
            String categoriaPrincipal = 'Sin categoría';

            if (orden.items.isNotEmpty) {
              final listaNombres =
                  orden.items.map((item) => item.productName).toList();
              conceptoConstruido = listaNombres.join(', ');

              // Categoría "dominante" de la orden: la del producto con
              // mayor importe dentro de la orden, usando la categoría REAL
              // del catálogo (con respaldo por palabras clave solo si el
              // producto no tiene categoría asignada), en vez de adivinar
              // por palabras clave sobre el nombre concatenado de todos los
              // productos de la orden.
              OrderItem? itemDominante;
              for (final item in orden.items) {
                if (itemDominante == null || item.total > itemDominante.total) {
                  itemDominante = item;
                }
              }
              categoriaPrincipal = _resolverCategoria(itemDominante!);
            } else {
              conceptoConstruido = 'Consumo General';
            }

            if (dateStr.isNotEmpty) {
              DateTime fechaOrd;
              try {
                fechaOrd = DateTime.parse(dateStr);
              } catch (_) {
                fechaOrd = DateTime.now();
              }

              bool pasaFiltroTiempo = false;
              String datePrefix = dateStr.substring(0, 10);

              if (_selectedPeriodo == 'Hoy') {
                pasaFiltroTiempo = datePrefix == hoyStr;
              } else if (_selectedPeriodo == 'Esta Semana') {
                pasaFiltroTiempo = fechaOrd
                    .isAfter(inicioSemana.subtract(const Duration(seconds: 1)));
              } else if (_selectedPeriodo == 'Este Mes') {
                pasaFiltroTiempo = datePrefix.startsWith(mesActualStr);
              } else {
                pasaFiltroTiempo = true;
              }

              if (pasaFiltroTiempo) {
                ventasProcesadas.add(VentaReporte(
                  id: idOrd.length > 6
                      ? idOrd.substring(idOrd.length - 6)
                      : idOrd,
                  date: datePrefix,
                  concept: conceptoConstruido,
                  category: categoriaPrincipal,
                  amount: totalValue,
                  paymentMethod: 'Efectivo',
                ));

                // ✅ PROCESAR RENDIMIENTO DE PRODUCTOS
                for (var item in orden.items) {
                  final nombreProd = item.productName;
                  final int cantidad = item.quantity;
                  final double precioSubtotal = item.total;

                  debugPrint(
                      '📊 REPORTES: Producto=$nombreProd, Cant=$cantidad, Precio=$precioSubtotal');

                  if (mapaProductosFiltro.containsKey(nombreProd)) {
                    mapaProductosFiltro[nombreProd]!.unidadesVendidas +=
                        cantidad;
                    mapaProductosFiltro[nombreProd]!.montoTotal +=
                        precioSubtotal;
                  } else {
                    mapaProductosFiltro[nombreProd] = ProductoRendimiento(
                      nombre: nombreProd,
                      categoria: _resolverCategoria(item),
                      unidadesVendidas: cantidad,
                      montoTotal: precioSubtotal,
                    );
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('❌ REPORTES: Error procesando orden: $e');
          }
        }

        _historialVentas = ventasProcesadas;
        _productosRendimiento = mapaProductosFiltro.values.toList();
        _productosRendimiento
            .sort((a, b) => b.montoTotal.compareTo(a.montoTotal));

        // Como las categorías del filtro ahora son dinámicas (vienen de los
        // datos reales), si la categoría seleccionada ya no existe tras
        // recargar (cambió el período, o esa categoría no tuvo ventas),
        // volvemos a "Todos" en vez de dejar un filtro inválido que
        // mostraría una lista vacía sin explicación.
        if (_selectedCategory != 'Todos' &&
            !categoriasFiltro.contains(_selectedCategory)) {
          _selectedCategory = 'Todos';
        }

        debugPrint(
            '✅ REPORTES: Procesadas ${ventasProcesadas.length} ventas y ${_productosRendimiento.length} productos únicos');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ REPORTES: Error general: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<VentaReporte> get filteredVentas {
    final query = _searchTerm.trim().toLowerCase();
    final cat = _selectedCategory;
    return _historialVentas.where((v) {
      final matchesSearch = query.isEmpty ||
          v.concept.toLowerCase().contains(query) ||
          v.id.toLowerCase().contains(query);
      final matchesCategory = cat == 'Todos' || v.category == cat;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<VentaReporte> get paginatedVentas {
    final list = filteredVentas;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + pageSize).clamp(0, list.length));
  }

  int get totalPages => (filteredVentas.length / pageSize).ceil();
  double get totalIngresos =>
      filteredVentas.fold(0.0, (sum, v) => sum + v.amount);
  int get totalTransacciones => filteredVentas.length;
  double get ticketPromedio =>
      totalTransacciones > 0 ? totalIngresos / totalTransacciones : 0.0;

  double get ingresosEfectivo => filteredVentas
      .where((v) => v.paymentMethod == 'Efectivo')
      .fold(0.0, (sum, v) => sum + v.amount);
  double get ingresosTarjeta => filteredVentas
      .where((v) => v.paymentMethod != 'Efectivo')
      .fold(0.0, (sum, v) => sum + v.amount);

  double get porcentajeEfectivo =>
      totalIngresos > 0 ? ingresosEfectivo / totalIngresos : 0;
  double get porcentajeTarjeta =>
      totalIngresos > 0 ? ingresosTarjeta / totalIngresos : 0;

  void onSearch(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void cambiarPeriodo(String periodo) {
    _selectedPeriodo = periodo;
    _currentPage = 1;
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

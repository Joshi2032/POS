import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';
import '../models/restaurant_order.dart';
import '../models/order_item.dart';
import '../utils/categoria_utils.dart';
import '../utils/mexico_time.dart';

class VentaReporte {
  final String id;
  final String date;
  final String concept;
  final String category;
  final double amount;
  final String paymentMethod;
  /// Monto real vendido por categoría DENTRO de esta orden (ej. una orden
  /// con un corte de $200 y una cerveza de $30 trae {'Alimentos': 200,
  /// 'Bebidas': 30}). Se usa para que filtrar por categoría sume solo lo
  /// que realmente corresponde a esa categoría, en vez de atribuir el total
  /// completo de la orden a una sola "categoría dominante".
  final Map<String, double> montosPorCategoria;

  VentaReporte({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.montosPorCategoria,
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
  // categorías realmente presentes en las ventas cargadas. Se enumeran
  // desde montosPorCategoria (no solo la categoría dominante de cada
  // orden), para no ocultar del filtro una categoría que nunca es la
  // dominante pero sí tiene ventas reales dentro de alguna orden mixta.
  List<String> get categoriasFiltro {
    final categoriasReales = _historialVentas
        .expand((v) => v.montosPorCategoria.keys)
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
    return resolverCategoriaConFallback(item.categoryName, item.productName);
  }

  // Traduce el método de pago real de la orden (BD: cash/card/transfer) al
  // mismo texto que usa la UI en Caja. Antes se ignoraba por completo y
  // toda venta se reportaba como 'Efectivo' sin importar cómo se pagó.
  String _resolverMetodoPago(String? metodoDb) {
    switch (metodoDb?.toLowerCase().trim()) {
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      default:
        return 'Efectivo';
    }
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
        // Todo el análisis de fechas se hace sobre el día-calendario de
        // MÉXICO (UTC-6 fijo), igual que dashboard_provider.dart: antes se
        // comparaba el string crudo de created_at (UTC) contra "hoy" del
        // dispositivo, así que una venta de la tarde/noche caía en UTC del
        // día siguiente y se contaba en el período equivocado.
        final hoyMexico = hoyEnMexico();
        final lunesDeEstaSemana =
            hoyMexico.subtract(Duration(days: hoyMexico.weekday - 1));
        final inicioSemana = lunesDeEstaSemana;
        final mesActualStr =
            '${hoyMexico.year.toString().padLeft(4, '0')}-${hoyMexico.month.toString().padLeft(2, '0')}';

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
            final Map<String, double> montosPorCategoria = {};

            if (orden.items.isNotEmpty) {
              final listaNombres =
                  orden.items.map((item) => item.productName).toList();
              conceptoConstruido = listaNombres.join(', ');

              // Categoría "dominante" de la orden: la del producto con
              // mayor importe dentro de la orden. Solo se usa como ETIQUETA
              // para el historial ("Todos"); los totales por categoría
              // (abajo) se calculan sumando lo que realmente corresponde a
              // cada categoría dentro de la orden, para no atribuirle el
              // total completo a una sola categoría cuando la orden mezcla
              // productos de varias.
              OrderItem? itemDominante;
              for (final item in orden.items) {
                if (itemDominante == null || item.total > itemDominante.total) {
                  itemDominante = item;
                }
                final cat = _resolverCategoria(item);
                montosPorCategoria[cat] =
                    (montosPorCategoria[cat] ?? 0) + item.total;
              }
              categoriaPrincipal = _resolverCategoria(itemDominante!);
            } else {
              conceptoConstruido = 'Consumo General';
            }

            if (dateStr.isNotEmpty) {
              final fechaOrdMexico = diaMexicoDesde(dateStr);

              bool pasaFiltroTiempo = false;

              if (fechaOrdMexico != null) {
                if (_selectedPeriodo == 'Hoy') {
                  pasaFiltroTiempo = fechaOrdMexico == hoyMexico;
                } else if (_selectedPeriodo == 'Esta Semana') {
                  pasaFiltroTiempo = !fechaOrdMexico.isBefore(inicioSemana);
                } else if (_selectedPeriodo == 'Este Mes') {
                  final strOrd =
                      '${fechaOrdMexico.year.toString().padLeft(4, '0')}-${fechaOrdMexico.month.toString().padLeft(2, '0')}';
                  pasaFiltroTiempo = strOrd == mesActualStr;
                } else {
                  pasaFiltroTiempo = true;
                }
              }

              if (pasaFiltroTiempo) {
                final datePrefix = fechaOrdMexico!.toIso8601String().substring(0, 10);
                ventasProcesadas.add(VentaReporte(
                  id: idOrd.length > 6
                      ? idOrd.substring(idOrd.length - 6)
                      : idOrd,
                  date: datePrefix,
                  concept: conceptoConstruido,
                  category: categoriaPrincipal,
                  amount: totalValue,
                  paymentMethod: _resolverMetodoPago(orden.paymentMethod),
                  montosPorCategoria: montosPorCategoria,
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

    // Al filtrar por una categoría específica, se incluye cualquier orden
    // que tenga ALGO de esa categoría (no solo cuya categoría dominante
    // coincida), y el monto mostrado/sumado es solo la porción real de esa
    // categoría dentro de la orden — así totalIngresos no atribuye de más
    // ni de menos cuando una orden mezcla categorías.
    final base = cat == 'Todos'
        ? _historialVentas
        : _historialVentas
            .where((v) => (v.montosPorCategoria[cat] ?? 0) > 0)
            .map((v) => VentaReporte(
                  id: v.id,
                  date: v.date,
                  concept: v.concept,
                  category: cat,
                  amount: v.montosPorCategoria[cat]!,
                  paymentMethod: v.paymentMethod,
                  montosPorCategoria: v.montosPorCategoria,
                ))
            .toList();

    return base.where((v) {
      final matchesSearch = query.isEmpty ||
          v.concept.toLowerCase().contains(query) ||
          v.id.toLowerCase().contains(query);
      return matchesSearch;
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mexico_time.dart';
import '../utils/embed_utils.dart';
import '../utils/categoria_utils.dart';

// Modelo relacional para estructurar el rendimiento de productos vendidos
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

class DashboardProvider extends ChangeNotifier {
  // Mantenemos la firma del constructor para no romper tu main.dart
  DashboardProvider(
    dynamic repoOrdenes,
    dynamic repoGastos,
    dynamic repoPayments,
  ) {
    cargarMetricasGlobales();
  }

  // Cliente directo de Supabase para consultas analíticas sin pérdida de datos
  final SupabaseClient _client = Supabase.instance.client;

  void _logDashboardError(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    debugPrint('DASHBOARD_PROVIDER: $context: $error');

    if (stackTrace != null) {
      debugPrintStack(
        label: 'DASHBOARD_PROVIDER STACK: $context',
        stackTrace: stackTrace,
      );
    }
  }

  // --- ESTADOS INTERNOS ---
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'semana';

  // Guardaremos los datos crudos (JSON real de la BD)
  List<dynamic> _allOrders = [];
  List<dynamic> _allExpenses = [];
  List<dynamic> _allSupplierPayments = [];

  // Tarjetas analíticas superiores
  double _ventasHoy = 0.0;
  double _ventasAyer = 0.0;
  int _ordenesActivas = 0;
  double _ingresoFiltroTotal = 0.0;
  double _utilidadFiltroTotal = 0.0;
  double _ingresoPeriodoAnteriorTotal = 0.0;
  double _utilidadPeriodoAnteriorTotal = 0.0;

  // Listas estructuradas para las gráficas
  List<String> _currentLabels = [];
  List<double> _currentIngresos = [];
  List<double> _currentGastos = [];
  List<double> _currentUtilidad = [];

  List<ProductoRendimiento> _currentProductos = [];

  // --- GETTERS COMPATIBLES CON LA INTERFAZ ---
  double get ventasHoy => _ventasHoy;
  int get ordenesActivas => _ordenesActivas;
  double get ingresoFiltroTotal => _ingresoFiltroTotal;
  double get utilidadFiltroTotal => _utilidadFiltroTotal;

  // Cambio porcentual REAL contra el período anterior (antes las tarjetas
  // del dashboard mostraban "+12.5%"/"+8.2%"/"+15.3%" fijos en el código,
  // sin ninguna relación con los datos reales).
  double get ventasHoyCambioPct => _cambioPorcentual(_ventasHoy, _ventasAyer);
  double get ingresoFiltroCambioPct =>
      _cambioPorcentual(_ingresoFiltroTotal, _ingresoPeriodoAnteriorTotal);
  double get utilidadFiltroCambioPct =>
      _cambioPorcentual(_utilidadFiltroTotal, _utilidadPeriodoAnteriorTotal);

  double _cambioPorcentual(double actual, double anterior) {
    if (anterior == 0) {
      return actual == 0 ? 0.0 : 100.0;
    }
    return ((actual - anterior) / anterior.abs()) * 100;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  List<String> get currentLabels => _currentLabels;
  List<double> get currentIngresos => _currentIngresos;
  List<double> get currentGastos => _currentGastos;
  List<double> get currentUtilidad => _currentUtilidad;

  List<ProductoRendimiento> get currentProductos => _currentProductos;

  String get labelFiltro {
    if (_filterType == 'mes') return 'Mensual';
    if (_filterType == 'año') return 'Anual';
    return 'Semanal';
  }

  void setFilterType(String type) {
    if (_filterType == type) return;
    _filterType = type;
    _procesarOperacionesFinancieras();
    notifyListeners();
  }

  // --- CONSULTA ASÍNCRONA DIRECTA A SUPABASE ---
  Future<void> cargarMetricasGlobales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Las 3 consultas son independientes entre sí, así que corren en
      // paralelo en vez de una tras otra (antes tardaba la suma de las 3
      // consultas; ahora tarda lo que tarde la más lenta de las 3).
      final resultados = await Future.wait<List<dynamic>>([
        _cargarOrdersConItems(),
        _cargarExpensesSeguro(),
        _cargarSupplierPaymentsSeguro(),
      ]);

      _allOrders = resultados[0];
      _allExpenses = resultados[1];
      _allSupplierPayments = resultados[2];

      try {
        debugPrint('✅ DASHBOARD: órdenes obtenidas: ${_allOrders.length}');
        if (_allOrders.isNotEmpty) {
          final sample = _allOrders.take(3).map((o) => o['status']).toList();
          debugPrint('✅ DASHBOARD: sample statuses: $sample');
        }
      } catch (e, stackTrace) {
        _logDashboardError(
          'Error imprimiendo debug inicial de órdenes',
          e,
          stackTrace,
        );
      }

      _procesarOperacionesFinancieras();
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _logDashboardError(
        'Error analítico general al cargar métricas globales',
        e,
        stackTrace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Extrae 'categories.name' del embed anidado
  // 'order_items(*, products(categories(name)))'.
  String? _extraerCategoriaReal(Map<String, dynamic> item) {
    return asEmbedMap(asEmbedMap(item['products'])?['categories'])?['name']
        ?.toString();
  }

  Future<List<dynamic>> _cargarOrdersConItems() async {
    // Se pide también la categoría REAL del producto (vía su categoría
    // asignada en el catálogo) para clasificar el rendimiento de productos,
    // en vez de adivinarla por palabras clave en el nombre (que fallaba
    // silenciosamente a "General" para cualquier producto que no contuviera
    // literalmente "arrachera"/"cerveza"/"combo", etc.).
    return await _client
        .from('orders')
        .select('*, order_items(*, products(categories(name)))');
  }

  // Se degradan a lista vacía si fallan, en vez de tumbar toda la carga del
  // dashboard (mismo comportamiento que antes, ahora extraído para poder
  // correr las 3 consultas en paralelo con Future.wait).
  Future<List<dynamic>> _cargarExpensesSeguro() async {
    try {
      return await _client.from('expenses').select('*');
    } catch (e, stackTrace) {
      _logDashboardError(
        'No se pudieron cargar expenses. Se continuará con lista vacía',
        e,
        stackTrace,
      );
      return [];
    }
  }

  Future<List<dynamic>> _cargarSupplierPaymentsSeguro() async {
    try {
      return await _client.from('supplier_payments').select('*');
    } catch (e, stackTrace) {
      _logDashboardError(
        'No se pudieron cargar supplier_payments. Se continuará con lista vacía',
        e,
        stackTrace,
      );
      return [];
    }
  }

  // --- MOTOR ANALÍTICO Y CRUCE DE TABLAS ---
  void _procesarOperacionesFinancieras() {
    // Todo el análisis de fechas se hace sobre el día-calendario de MÉXICO
    // (UTC-6 fijo), nunca sobre el timestamp UTC crudo que guarda Supabase
    // ni sobre la zona horaria del dispositivo. Antes se comparaba
    // directamente el string de created_at (UTC) contra "hoy" del
    // dispositivo: una venta de la tarde/noche en México cae en UTC del día
    // siguiente, así que se contaba en el día/semana/mes equivocado.
    final hoyMexico = hoyEnMexico();
    final ayerMexico = hoyMexico.subtract(const Duration(days: 1));

    _ventasHoy = 0.0;
    _ventasAyer = 0.0;
    _ordenesActivas = 0;

    final Map<String, ProductoRendimiento> mapaProductosFiltro = {};

    final inicioSemana = hoyMexico.subtract(
      Duration(days: hoyMexico.weekday - 1),
    );

    final mesActualStr =
        '${hoyMexico.year.toString().padLeft(4, '0')}-${hoyMexico.month.toString().padLeft(2, '0')}';
    final anioActualStr = hoyMexico.year.toString();

    bool cumpleFiltroFecha(DateTime fechaMexico) {
      if (_filterType == 'semana') {
        return !fechaMexico.isBefore(inicioSemana) &&
            fechaMexico.difference(inicioSemana).inDays < 7;
      } else if (_filterType == 'mes') {
        final str =
            '${fechaMexico.year.toString().padLeft(4, '0')}-${fechaMexico.month.toString().padLeft(2, '0')}';
        return str == mesActualStr;
      } else {
        return fechaMexico.year.toString() == anioActualStr;
      }
    }

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS
    for (final rawJson in _allOrders) {
      try {
        final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        final String estado =
            (rawJson['status'] ?? '').toString().toLowerCase();

        // Solo sumamos dinero de órdenes que ya están pagadas (paid)
        if (estado == 'paid') {
          final fechaMexico = diaMexicoDesde(rawJson['created_at']);
          if (fechaMexico != null && fechaMexico == hoyMexico) {
            _ventasHoy += totalValue;
          }
          if (fechaMexico != null && fechaMexico == ayerMexico) {
            _ventasAyer += totalValue;
          }
        }

        // Ya no hay flujo de cocina: "activa" es cualquier orden que no se
        // ha pagado ni cancelado todavía.
        if (estado != 'paid' && estado != 'cancelled') {
          _ordenesActivas++;
        }
      } catch (e, stackTrace) {
        _logDashboardError(
          'Error procesando orden para ventasHoy/ordenesActivas',
          e,
          stackTrace,
        );
      }
    }

    // 2. AGRUPAMIENTO TEMPORAL DE VECTOR DE GRÁFICAS
    if (_filterType == 'semana') {
      _currentLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      _currentIngresos = List.generate(7, (_) => 0.0);
      _currentGastos = List.generate(7, (_) => 0.0);

      for (final rawJson in _allOrders) {
        try {
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (estado == 'paid') {
            final fechaOrd = diaMexicoDesde(rawJson['created_at']);
            if (fechaOrd != null && !fechaOrd.isBefore(inicioSemana)) {
              final diasDiferencia = fechaOrd.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentIngresos[diasDiferencia] += totalValue;
              }
            }
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando ingresos semanales desde orders',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allExpenses) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fechaGst =
              diaMexicoDesde(rawJson['expense_date'] ?? rawJson['created_at']);
          if (fechaGst != null && !fechaGst.isBefore(inicioSemana)) {
            final diasDiferencia = fechaGst.difference(inicioSemana).inDays;
            if (diasDiferencia >= 0 && diasDiferencia < 7) {
              _currentGastos[diasDiferencia] += amountValue;
            }
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando gastos semanales desde expenses',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allSupplierPayments) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fechaPag = diaMexicoDesde(rawJson['created_at']);
          if (fechaPag != null && !fechaPag.isBefore(inicioSemana)) {
            final diasDiferencia = fechaPag.difference(inicioSemana).inDays;
            if (diasDiferencia >= 0 && diasDiferencia < 7) {
              _currentGastos[diasDiferencia] += amountValue;
            }
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando pagos semanales desde supplier_payments',
            e,
            stackTrace,
          );
        }
      }
    } else if (_filterType == 'mes') {
      _currentLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (final rawJson in _allOrders) {
        try {
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (estado == 'paid') {
            final fecha = diaMexicoDesde(rawJson['created_at']);
            final str = fecha == null
                ? null
                : '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}';
            if (fecha != null && str == mesActualStr) {
              final indiceSemana = ((fecha.day - 1) / 7).floor().clamp(0, 3);
              _currentIngresos[indiceSemana] += totalValue;
            }
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando ingresos mensuales desde orders',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allExpenses) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fecha =
              diaMexicoDesde(rawJson['expense_date'] ?? rawJson['created_at']);
          final str = fecha == null
              ? null
              : '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}';
          if (fecha != null && str == mesActualStr) {
            final indiceSemana = ((fecha.day - 1) / 7).floor().clamp(0, 3);
            _currentGastos[indiceSemana] += amountValue;
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando gastos mensuales desde expenses',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allSupplierPayments) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fecha = diaMexicoDesde(rawJson['created_at']);
          final str = fecha == null
              ? null
              : '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}';
          if (fecha != null && str == mesActualStr) {
            final indiceSemana = ((fecha.day - 1) / 7).floor().clamp(0, 3);
            _currentGastos[indiceSemana] += amountValue;
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando pagos mensuales desde supplier_payments',
            e,
            stackTrace,
          );
        }
      }
    } else {
      _currentLabels = ['Trim 1', 'Trim 2', 'Trim 3', 'Trim 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (final rawJson in _allOrders) {
        try {
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (estado == 'paid') {
            final fecha = diaMexicoDesde(rawJson['created_at']);
            if (fecha != null && fecha.year.toString() == anioActualStr) {
              final indiceTrimestre = ((fecha.month - 1) / 3).floor().clamp(0, 3);
              _currentIngresos[indiceTrimestre] += totalValue;
            }
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando ingresos anuales desde orders',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allExpenses) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fecha =
              diaMexicoDesde(rawJson['expense_date'] ?? rawJson['created_at']);
          if (fecha != null && fecha.year.toString() == anioActualStr) {
            final indiceTrimestre = ((fecha.month - 1) / 3).floor().clamp(0, 3);
            _currentGastos[indiceTrimestre] += amountValue;
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando gastos anuales desde expenses',
            e,
            stackTrace,
          );
        }
      }

      for (final rawJson in _allSupplierPayments) {
        try {
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          final fecha = diaMexicoDesde(rawJson['created_at']);
          if (fecha != null && fecha.year.toString() == anioActualStr) {
            final indiceTrimestre = ((fecha.month - 1) / 3).floor().clamp(0, 3);
            _currentGastos[indiceTrimestre] += amountValue;
          }
        } catch (e, stackTrace) {
          _logDashboardError(
            'Error agrupando pagos anuales desde supplier_payments',
            e,
            stackTrace,
          );
        }
      }
    }

    // 3. EXTRACCIÓN REAL DE PRODUCTOS
    for (final rawJson in _allOrders) {
      try {
        final String estado =
            (rawJson['status'] ?? '').toString().toLowerCase();

        // Solo contar productos de órdenes que ya fueron pagadas
        if (estado == 'paid') {
          final fechaOrd = diaMexicoDesde(rawJson['created_at']);

          if (fechaOrd != null && cumpleFiltroFecha(fechaOrd)) {
            // Leemos los order_items obtenidos gracias a la consulta '.select("*, order_items(*)")'
            final items = rawJson['order_items'] ?? [];

            if (items is List) {
              for (final item in items) {
                final nombreProd =
                    (item['product_name'] ?? 'Producto Desconocido').toString();

                // Usamos la categoría REAL asignada al producto en el
                // catálogo (Productos > Categoría); si el producto ya no
                // existe/fue borrado (sin join disponible), caemos a un
                // respaldo por palabras clave (mismo helper que usa
                // reportes_provider.dart, para que ambas pantallas muestren
                // la misma categoría también en ese caso límite).
                final String categoriaProd = resolverCategoriaConFallback(
                  _extraerCategoriaReal(item),
                  nombreProd,
                );

                final int cantidad = ((item['quantity'] ?? 1) as num).toInt();

                final double precioSubtotal =
                    ((item['total_price'] ?? item['unit_price'] ?? 0.0) as num)
                        .toDouble();

                if (mapaProductosFiltro.containsKey(nombreProd)) {
                  mapaProductosFiltro[nombreProd]!.unidadesVendidas +=
                      cantidad;
                  mapaProductosFiltro[nombreProd]!.montoTotal +=
                      precioSubtotal;
                } else {
                  mapaProductosFiltro[nombreProd] = ProductoRendimiento(
                    nombre: nombreProd,
                    categoria: categoriaProd,
                    unidadesVendidas: cantidad,
                    montoTotal: precioSubtotal,
                  );
                }
              }
            }
          }
        }
      } catch (e, stackTrace) {
        _logDashboardError(
          'Error procesando rendimiento de productos',
          e,
          stackTrace,
        );
      }
    }

    _currentProductos = mapaProductosFiltro.values.toList();
    _currentProductos.sort((a, b) => b.montoTotal.compareTo(a.montoTotal));

    // 4. GENERACIÓN DE VECTORES DE UTILIDAD Y TOTALES FINALES
    _currentUtilidad = List.generate(_currentIngresos.length, (_) => 0.0);
    _ingresoFiltroTotal = 0.0;
    double totalGastosFiltro = 0.0;

    for (int i = 0; i < _currentIngresos.length; i++) {
      _currentUtilidad[i] = _currentIngresos[i] - _currentGastos[i];
      _ingresoFiltroTotal += _currentIngresos[i];
      totalGastosFiltro += _currentGastos[i];
    }

    _utilidadFiltroTotal = _ingresoFiltroTotal - totalGastosFiltro;

    _calcularTotalesPeriodoAnterior(hoyMexico);

    try {
      debugPrint(
        '✅ DASHBOARD: ventasHoy=${_ventasHoy.toStringAsFixed(2)}, '
        'ordenesActivas=$_ordenesActivas, '
        'ingresoFiltro=${_ingresoFiltroTotal.toStringAsFixed(2)}',
      );
    } catch (e, stackTrace) {
      _logDashboardError(
        'Error imprimiendo debug final de métricas',
        e,
        stackTrace,
      );
    }
  }

  // Calcula el ingreso y la utilidad del período INMEDIATO ANTERIOR al
  // seleccionado (semana pasada / mes pasado / año pasado), para poder
  // mostrar un % de cambio real en las tarjetas del dashboard en vez del
  // valor fijo que había antes. Recibe "hoy" ya normalizado al día-calendario
  // de México (ver hoyEnMexico()), y compara contra fechas normalizadas de la
  // misma forma vía diaMexicoDesde().
  void _calcularTotalesPeriodoAnterior(DateTime hoyMexico) {
    late DateTime inicioAnterior;
    late DateTime finAnteriorExclusivo;

    if (_filterType == 'semana') {
      final lunesDeEstaSemana = hoyMexico.subtract(
        Duration(days: hoyMexico.weekday - 1),
      );
      inicioAnterior = lunesDeEstaSemana.subtract(const Duration(days: 7));
      finAnteriorExclusivo = lunesDeEstaSemana;
    } else if (_filterType == 'mes') {
      inicioAnterior = DateTime(hoyMexico.year, hoyMexico.month - 1, 1);
      finAnteriorExclusivo = DateTime(hoyMexico.year, hoyMexico.month, 1);
    } else {
      inicioAnterior = DateTime(hoyMexico.year - 1, 1, 1);
      finAnteriorExclusivo = DateTime(hoyMexico.year, 1, 1);
    }

    double ingresoAnterior = 0.0;
    double gastosAnterior = 0.0;

    bool enRango(DateTime fecha) =>
        !fecha.isBefore(inicioAnterior) && fecha.isBefore(finAnteriorExclusivo);

    for (final rawJson in _allOrders) {
      try {
        final estado = (rawJson['status'] ?? '').toString().toLowerCase();
        if (estado != 'paid') continue;

        final fecha = diaMexicoDesde(rawJson['created_at']);
        if (fecha != null && enRango(fecha)) {
          ingresoAnterior += (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {
        // Se ignoran filas individuales con fecha inválida, igual que en
        // el resto de esta clase.
      }
    }

    for (final rawJson in _allExpenses) {
      try {
        final fecha =
            diaMexicoDesde(rawJson['expense_date'] ?? rawJson['created_at']);
        if (fecha != null && enRango(fecha)) {
          gastosAnterior += (rawJson['amount'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    for (final rawJson in _allSupplierPayments) {
      try {
        final fecha = diaMexicoDesde(rawJson['created_at']);
        if (fecha != null && enRango(fecha)) {
          gastosAnterior += (rawJson['amount'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    _ingresoPeriodoAnteriorTotal = ingresoAnterior;
    _utilidadPeriodoAnteriorTotal = ingresoAnterior - gastosAnterior;
  }
}
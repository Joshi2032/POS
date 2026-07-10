import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // 'order_items(*, products(categories(name)))'. PostgREST puede devolver
  // los embeds como Map (relación 1:1) o como List (por seguridad, si
  // llegara a tratarse como 1:N), así que se manejan ambos casos.
  String? _extraerCategoriaReal(Map<String, dynamic> item) {
    final productosEmbed = item['products'];

    Map<String, dynamic>? productoMap;
    if (productosEmbed is Map<String, dynamic>) {
      productoMap = productosEmbed;
    } else if (productosEmbed is List && productosEmbed.isNotEmpty) {
      final primero = productosEmbed.first;
      if (primero is Map<String, dynamic>) productoMap = primero;
    }

    if (productoMap == null) return null;

    final categoriasEmbed = productoMap['categories'];
    if (categoriasEmbed is Map<String, dynamic>) {
      return categoriasEmbed['name']?.toString();
    } else if (categoriasEmbed is List && categoriasEmbed.isNotEmpty) {
      final primero = categoriasEmbed.first;
      if (primero is Map<String, dynamic>) {
        return primero['name']?.toString();
      }
    }

    return null;
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
    final ahora = DateTime.now();

    // Mismo offset fijo de México (UTC-6) que ya se usa en caja_repository.dart,
    // provider_payment.dart y reservaciones_provider.dart: "hoy"/"ayer" se
    // calculan con este offset para que Ventas Hoy no dependa de la zona
    // horaria del dispositivo ni se desfase cerca de medianoche.
    final ahoraMexico = DateTime.now().toUtc().add(const Duration(hours: -6));
    final hoyStr = ahoraMexico.toIso8601String().substring(0, 10);
    final ayerStr = ahoraMexico
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    _ventasHoy = 0.0;
    _ventasAyer = 0.0;
    _ordenesActivas = 0;

    final Map<String, ProductoRendimiento> mapaProductosFiltro = {};

    bool cumpleFiltroFecha(
      DateTime fechaObjeto,
      DateTime inicioSemana,
      String mesStr,
      String anioStr,
    ) {
      if (_filterType == 'semana') {
        return fechaObjeto
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1))) &&
            fechaObjeto.difference(inicioSemana).inDays < 7;
      } else if (_filterType == 'mes') {
        return fechaObjeto.toIso8601String().startsWith(mesStr);
      } else {
        return fechaObjeto.toIso8601String().startsWith(anioStr);
      }
    }

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS
    for (final rawJson in _allOrders) {
      try {
        final String dateStr =
            rawJson['created_at']?.toString().substring(0, 10) ?? '';
        final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        final String estado =
            (rawJson['status'] ?? '').toString().toLowerCase();

        // Solo sumamos dinero de órdenes que ya están pagadas (paid)
        if (dateStr.startsWith(hoyStr) && estado == 'paid') {
          _ventasHoy += totalValue;
        }

        if (dateStr.startsWith(ayerStr) && estado == 'paid') {
          _ventasAyer += totalValue;
        }

        if (estado == 'pending' || estado == 'preparing' || estado == 'ready') {
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

    final lunesDeEstaSemana = ahora.subtract(
      Duration(days: ahora.weekday - 1),
    );

    final inicioSemana = DateTime(
      lunesDeEstaSemana.year,
      lunesDeEstaSemana.month,
      lunesDeEstaSemana.day,
    );

    final mesActualStr = ahora.toIso8601String().substring(0, 7);
    final anioActualStr = ahora.year.toString();

    // 2. AGRUPAMIENTO TEMPORAL DE VECTOR DE GRÁFICAS
    if (_filterType == 'semana') {
      _currentLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      _currentIngresos = List.generate(7, (_) => 0.0);
      _currentGastos = List.generate(7, (_) => 0.0);

      for (final rawJson in _allOrders) {
        try {
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (dateStr.isNotEmpty && estado == 'paid') {
            final fechaOrd = DateTime.parse(dateStr);
            if (fechaOrd
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
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
          final String dateStr =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.isNotEmpty) {
            final fechaGst = DateTime.parse(dateStr);
            if (fechaGst
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
              final diasDiferencia = fechaGst.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentGastos[diasDiferencia] += amountValue;
              }
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
          final String dateStr = rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.isNotEmpty) {
            final fechaPag = DateTime.parse(dateStr);
            if (fechaPag
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
              final diasDiferencia = fechaPag.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentGastos[diasDiferencia] += amountValue;
              }
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
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (dateStr.startsWith(mesActualStr) && estado == 'paid') {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
            _currentIngresos[indiceSemana] += totalValue;
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
          final String dateStr =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(mesActualStr)) {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
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
          final String dateStr = rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(mesActualStr)) {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
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
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (dateStr.startsWith(anioActualStr) && estado == 'paid') {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
            _currentIngresos[indiceTrimestre] += totalValue;
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
          final String dateStr =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(anioActualStr)) {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
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
          final String dateStr = rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(anioActualStr)) {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
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
        final String dateStr = rawJson['created_at'] ?? '';
        final String estado =
            (rawJson['status'] ?? '').toString().toLowerCase();

        // Solo contar productos de órdenes que ya fueron pagadas
        if (dateStr.isNotEmpty && estado == 'paid') {
          final fechaOrd = DateTime.parse(dateStr);

          if (cumpleFiltroFecha(
            fechaOrd,
            inicioSemana,
            mesActualStr,
            anioActualStr,
          )) {
            // Leemos los order_items obtenidos gracias a la consulta '.select("*, order_items(*)")'
            final items = rawJson['order_items'] ?? [];

            if (items is List) {
              for (final item in items) {
                final nombreProd =
                    (item['product_name'] ?? 'Producto Desconocido').toString();

                // Usamos la categoría REAL asignada al producto en el
                // catálogo (Productos > Categoría) en vez de adivinarla por
                // palabras clave en el nombre, que fallaba en silencio a
                // "General" para cualquier producto sin esas palabras
                // exactas en el nombre.
                String? categoriaProd = _extraerCategoriaReal(item);

                // Si el producto ya no existe/fue borrado (sin join
                // disponible), caemos al heurístico anterior como respaldo
                // en vez de dejarlo sin categoría.
                if (categoriaProd == null || categoriaProd.trim().isEmpty) {
                  final rawName = nombreProd.toLowerCase();

                  if (rawName.contains('arrachera') ||
                      rawName.contains('t-bone') ||
                      rawName.contains('corte')) {
                    categoriaProd = 'Parrilla';
                  } else if (rawName.contains('cerveza') ||
                      rawName.contains('agua') ||
                      rawName.contains('refresco')) {
                    categoriaProd = 'Bebidas';
                  } else if (rawName.contains('combo')) {
                    categoriaProd = 'Combos';
                  } else {
                    categoriaProd = 'General';
                  }
                }

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

    _calcularTotalesPeriodoAnterior(ahora);

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
  // valor fijo que había antes.
  void _calcularTotalesPeriodoAnterior(DateTime ahora) {
    late DateTime inicioAnterior;
    late DateTime finAnteriorExclusivo;

    if (_filterType == 'semana') {
      final lunesDeEstaSemana = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      ).subtract(Duration(days: ahora.weekday - 1));
      inicioAnterior = lunesDeEstaSemana.subtract(const Duration(days: 7));
      finAnteriorExclusivo = lunesDeEstaSemana;
    } else if (_filterType == 'mes') {
      inicioAnterior = DateTime(ahora.year, ahora.month - 1, 1);
      finAnteriorExclusivo = DateTime(ahora.year, ahora.month, 1);
    } else {
      inicioAnterior = DateTime(ahora.year - 1, 1, 1);
      finAnteriorExclusivo = DateTime(ahora.year, 1, 1);
    }

    double ingresoAnterior = 0.0;
    double gastosAnterior = 0.0;

    bool enRango(DateTime fecha) =>
        !fecha.isBefore(inicioAnterior) && fecha.isBefore(finAnteriorExclusivo);

    for (final rawJson in _allOrders) {
      try {
        final dateStr = rawJson['created_at']?.toString() ?? '';
        final estado = (rawJson['status'] ?? '').toString().toLowerCase();
        if (dateStr.isEmpty || estado != 'paid') continue;

        final fecha = DateTime.parse(dateStr);
        if (enRango(fecha)) {
          ingresoAnterior += (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {
        // Se ignoran filas individuales con fecha inválida, igual que en
        // el resto de esta clase.
      }
    }

    for (final rawJson in _allExpenses) {
      try {
        final dateStr =
            (rawJson['expense_date'] ?? rawJson['created_at'] ?? '')
                .toString();
        if (dateStr.isEmpty) continue;

        final fecha = DateTime.parse(dateStr);
        if (enRango(fecha)) {
          gastosAnterior += (rawJson['amount'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    for (final rawJson in _allSupplierPayments) {
      try {
        final dateStr = (rawJson['created_at'] ?? '').toString();
        if (dateStr.isEmpty) continue;

        final fecha = DateTime.parse(dateStr);
        if (enRango(fecha)) {
          gastosAnterior += (rawJson['amount'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }

    _ingresoPeriodoAnteriorTotal = ingresoAnterior;
    _utilidadPeriodoAnteriorTotal = ingresoAnterior - gastosAnterior;
  }
}
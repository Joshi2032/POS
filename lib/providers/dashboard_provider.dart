import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';
import '../repositories/gasto_repository.dart';
import '../repositories/payment_repository.dart';
import '../models/provider_payment.dart';

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
  final OrdenRepository _ordenRepository;
  final GastoRepository _gastoRepository;
  final PaymentRepository _paymentRepository;

  DashboardProvider(
    this._ordenRepository,
    this._gastoRepository,
    this._paymentRepository,
  ) {
    cargarMetricasGlobales();
  }

  // --- ESTADOS INTERNOS ---
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'semana';

  List<dynamic> _allOrders = [];
  List<dynamic> _allExpenses = [];
  List<ProviderPayment> _allSupplierPayments = [];

  // Tarjetas analíticas superiores
  double _ventasHoy = 0.0;
  int _ordenesActivas = 0;
  double _ingresoFiltroTotal = 0.0;
  double _utilidadFiltroTotal = 0.0;

  // Listas estructuradas para las gráficas de líneas y barras
  List<String> _currentLabels = [];
  List<double> _currentIngresos = [];
  List<double> _currentGastos = [];
  List<double> _currentUtilidad = [];

  // Lista vinculada de rendimiento de productos extraídos de Supabase
  List<ProductoRendimiento> _currentProductos = [];

  // --- GETTERS COMPATIBLES CON LA INTERFAZ ---
  double get ventasHoy => _ventasHoy;
  int get ordenesActivas => _ordenesActivas;
  double get ingresoFiltroTotal => _ingresoFiltroTotal;
  double get utilidadFiltroTotal => _utilidadFiltroTotal;

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

  // --- HELPER: convierte fecha de Supabase (UTC) a fecha local como string YYYY-MM-DD ---
  String _toLocalDateStr(String rawDateStr) {
    try {
      return DateTime.parse(rawDateStr).toLocal().toIso8601String().substring(0, 10);
    } catch (_) {
      return '';
    }
  }

  // --- HELPER: parsea fecha de Supabase y convierte a hora local ---
  DateTime? _parseLocalDate(String rawDateStr) {
    try {
      return DateTime.parse(rawDateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  // --- SELECTOR DE FILTRO ---
  void setFilterType(String type) {
    if (_filterType == type) return;
    _filterType = type;
    _procesarOperacionesFinancieras();
    notifyListeners();
  }

  // --- CONSULTA ASÍNCRONA ---
  Future<void> cargarMetricasGlobales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic repoOrdenes = _ordenRepository;
      final dynamic repoGastos = _gastoRepository;

      final ordersFuture =
          (repoOrdenes.runtimeType.toString().contains('OrdenRepository'))
              ? _clientFetch(repoOrdenes)
              : Future.value([]);

      final expensesFuture =
          (repoGastos.runtimeType.toString().contains('GastoRepository'))
              ? _clientFetch(repoGastos)
              : Future.value([]);

      final resultados = await Future.wait([
        ordersFuture,
        expensesFuture,
        _paymentRepository.getAll(),
      ]);

      _allOrders = resultados[0];
      _allExpenses = resultados[1];
      _allSupplierPayments = resultados[2] as List<ProviderPayment>;

      _procesarOperacionesFinancieras();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error analítico en Dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> _clientFetch(dynamic repository) async {
    try {
      return await repository.getAll();
    } catch (_) {
      try {
        return await repository.obtenerTodos();
      } catch (_) {
        return [];
      }
    }
  }

  // --- MOTOR ANALÍTICO Y CRUCE DE TABLAS ---
  void _procesarOperacionesFinancieras() {
    // Toda la lógica trabaja en HORA LOCAL para coincidir con las fechas
    // que el usuario ve en pantalla. Supabase guarda en UTC, por eso
    // usamos .toLocal() en cada DateTime.parse().
    final ahora = DateTime.now(); // hora local del dispositivo

    // Fecha de hoy en formato YYYY-MM-DD (hora local)
    final hoyStr =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

    _ventasHoy = 0.0;
    _ordenesActivas = 0;

    final Map<String, ProductoRendimiento> mapaProductosFiltro = {};

    // Inicio del lunes de la semana actual (hora local, a medianoche)
    final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioSemana = DateTime(
        lunesDeEstaSemana.year, lunesDeEstaSemana.month, lunesDeEstaSemana.day);

    // Strings de mes y año para comparar (hora local)
    final mesActualStr =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
    final anioActualStr = ahora.year.toString();

    bool cumpleFiltroFecha(DateTime fechaLocal) {
      if (_filterType == 'semana') {
        final diasDiferencia = fechaLocal.difference(inicioSemana).inDays;
        return diasDiferencia >= 0 && diasDiferencia < 7;
      } else if (_filterType == 'mes') {
        final fechaStr =
            '${fechaLocal.year}-${fechaLocal.month.toString().padLeft(2, '0')}';
        return fechaStr == mesActualStr;
      } else {
        return fechaLocal.year.toString() == anioActualStr;
      }
    }

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS
    for (var orden in _allOrders) {
      try {
        final rawJson =
            (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
        final String rawCreatedAt = rawJson['created_at']?.toString() ?? '';
        final String dateStr = _toLocalDateStr(rawCreatedAt); // ← hora local
        final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        final String estado = (rawJson['status'] ?? '').toString().toLowerCase();

        if (dateStr == hoyStr && estado == 'paid') {
          _ventasHoy += totalValue;
        }

        if (estado == 'pending' || estado == 'preparing' || estado == 'ready') {
          _ordenesActivas++;
        }
      } catch (_) {}
    }

    // 2. AGRUPAMIENTO TEMPORAL DE VECTOR DE GRÁFICAS
    if (_filterType == 'semana') {
      _currentLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      _currentIngresos = List.generate(7, (_) => 0.0);
      _currentGastos = List.generate(7, (_) => 0.0);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map'))
              ? orden
              : orden.toJson();
          final String rawCreatedAt = rawJson['created_at']?.toString() ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (rawCreatedAt.isNotEmpty && estado == 'paid') {
            final fechaLocal = _parseLocalDate(rawCreatedAt); // ← hora local
            if (fechaLocal != null) {
              final diasDiferencia =
                  fechaLocal.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentIngresos[diasDiferencia] += totalValue;
              }
            }
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map'))
              ? gasto
              : gasto.toJson();
          final String rawDate =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (rawDate.isNotEmpty) {
            final fechaLocal = _parseLocalDate(rawDate); // ← hora local
            if (fechaLocal != null) {
              final diasDiferencia =
                  fechaLocal.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentGastos[diasDiferencia] += amountValue;
              }
            }
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        try {
          if (pagoProv.date.isNotEmpty) {
            final fechaLocal = _parseLocalDate(pagoProv.date); // ← hora local
            if (fechaLocal != null) {
              final diasDiferencia =
                  fechaLocal.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentGastos[diasDiferencia] += pagoProv.amount;
              }
            }
          }
        } catch (_) {}
      }
    } else if (_filterType == 'mes') {
      _currentLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map'))
              ? orden
              : orden.toJson();
          final String rawCreatedAt = rawJson['created_at']?.toString() ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (rawCreatedAt.isNotEmpty && estado == 'paid') {
            final fechaLocal = _parseLocalDate(rawCreatedAt); // ← hora local
            if (fechaLocal != null) {
              final fechaMesStr =
                  '${fechaLocal.year}-${fechaLocal.month.toString().padLeft(2, '0')}';
              if (fechaMesStr == mesActualStr) {
                final indiceSemana =
                    ((fechaLocal.day - 1) / 7).floor().clamp(0, 3);
                _currentIngresos[indiceSemana] += totalValue;
              }
            }
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map'))
              ? gasto
              : gasto.toJson();
          final String rawDate =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (rawDate.isNotEmpty) {
            final fechaLocal = _parseLocalDate(rawDate); // ← hora local
            if (fechaLocal != null) {
              final fechaMesStr =
                  '${fechaLocal.year}-${fechaLocal.month.toString().padLeft(2, '0')}';
              if (fechaMesStr == mesActualStr) {
                final indiceSemana =
                    ((fechaLocal.day - 1) / 7).floor().clamp(0, 3);
                _currentGastos[indiceSemana] += amountValue;
              }
            }
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        if (pagoProv.date.isNotEmpty) {
          final fechaLocal = _parseLocalDate(pagoProv.date); // ← hora local
          if (fechaLocal != null) {
            final fechaMesStr =
                '${fechaLocal.year}-${fechaLocal.month.toString().padLeft(2, '0')}';
            if (fechaMesStr == mesActualStr) {
              final indiceSemana =
                  ((fechaLocal.day - 1) / 7).floor().clamp(0, 3);
              _currentGastos[indiceSemana] += pagoProv.amount;
            }
          }
        }
      }
    } else {
      // Anual → agrupado por trimestre
      _currentLabels = ['Trim 1', 'Trim 2', 'Trim 3', 'Trim 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map'))
              ? orden
              : orden.toJson();
          final String rawCreatedAt = rawJson['created_at']?.toString() ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;
          final String estado =
              (rawJson['status'] ?? '').toString().toLowerCase();

          if (rawCreatedAt.isNotEmpty && estado == 'paid') {
            final fechaLocal = _parseLocalDate(rawCreatedAt); // ← hora local
            if (fechaLocal != null &&
                fechaLocal.year.toString() == anioActualStr) {
              final indiceTrimestre =
                  ((fechaLocal.month - 1) / 3).floor().clamp(0, 3);
              _currentIngresos[indiceTrimestre] += totalValue;
            }
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map'))
              ? gasto
              : gasto.toJson();
          final String rawDate =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (rawDate.isNotEmpty) {
            final fechaLocal = _parseLocalDate(rawDate); // ← hora local
            if (fechaLocal != null &&
                fechaLocal.year.toString() == anioActualStr) {
              final indiceTrimestre =
                  ((fechaLocal.month - 1) / 3).floor().clamp(0, 3);
              _currentGastos[indiceTrimestre] += amountValue;
            }
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        if (pagoProv.date.isNotEmpty) {
          final fechaLocal = _parseLocalDate(pagoProv.date); // ← hora local
          if (fechaLocal != null &&
              fechaLocal.year.toString() == anioActualStr) {
            final indiceTrimestre =
                ((fechaLocal.month - 1) / 3).floor().clamp(0, 3);
            _currentGastos[indiceTrimestre] += pagoProv.amount;
          }
        }
      }
    }

    // 3. EXTRACCIÓN REAL DE SUB-TABLAS DE PRODUCTOS DESDE SUPABASE
    for (var orden in _allOrders) {
      try {
        final rawJson =
            (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
        final String rawCreatedAt = rawJson['created_at']?.toString() ?? '';
        final String estado = (rawJson['status'] ?? '').toString().toLowerCase();

        // Solo contar productos de órdenes que ya fueron pagadas
        if (rawCreatedAt.isNotEmpty && estado == 'paid') {
          final fechaLocal = _parseLocalDate(rawCreatedAt); // ← hora local
          if (fechaLocal != null && cumpleFiltroFecha(fechaLocal)) {
            // Buscamos 'order_items' (el array que manda Supabase con el JOIN)
            final items = rawJson['order_items'] ?? rawJson['items'] ?? [];
            if (items is List) {
              for (var item in items) {
                final nombreProd =
                    (item['product_name'] ?? 'Producto Desconocido').toString();
                final categoriaProd =
                    (item['category'] ?? 'General').toString();
                final int cantidad =
                    ((item['quantity'] ?? 1) as num).toInt();
                final double precioSubtotal = ((item['total_price'] ??
                            item['unit_price'] ??
                            item['total'] ??
                            0.0) as num)
                        .toDouble();

                if (mapaProductosFiltro.containsKey(nombreProd)) {
                  mapaProductosFiltro[nombreProd]!.unidadesVendidas += cantidad;
                  mapaProductosFiltro[nombreProd]!.montoTotal += precioSubtotal;
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
      } catch (_) {}
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
  }
}
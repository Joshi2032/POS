import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';
import '../repositories/gasto_repository.dart';
import '../repositories/payment_repository.dart';
import '../models/provider_payment.dart';
import '../models/restaurant_order.dart';

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

  List<RestaurantOrder> _allOrders = [];
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
      _allOrders = await _ordenRepository.getAll();
      _allExpenses = await _gastoRepository.getAll();
      _allSupplierPayments = await _paymentRepository.getAll();

      _procesarOperacionesFinancieras();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error analítico en Dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MOTOR ANALÍTICO Y CRUCE DE TABLAS ---
  void _procesarOperacionesFinancieras() {
    final ahora = DateTime.now();
    final hoyStr = ahora.toIso8601String().substring(0, 10);

    _ventasHoy = 0.0;
    _ordenesActivas = 0;

    final Map<String, ProductoRendimiento> mapaProductosFiltro = {};

    bool cumpleFiltroFecha(DateTime fechaOrd, DateTime inicioSemana,
        String mesStr, String anioStr) {
      if (_filterType == 'semana') {
        return fechaOrd
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1))) &&
            fechaOrd.difference(inicioSemana).inDays < 7;
      } else if (_filterType == 'mes') {
        return fechaOrd.toIso8601String().startsWith(mesStr);
      } else {
        return fechaOrd.toIso8601String().startsWith(anioStr);
      }
    }

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS
    for (var orden in _allOrders) {
      try {
        final rawJson = (orden.runtimeType.toString().contains('Map'))
            ? orden
            : orden.toJson();
        // Mapeo exacto a Supabase: created_at
        final String dateStr =
            rawJson['created_at']?.toString().substring(0, 10) ?? '';
        final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        final String estado =
            (rawJson['status'] ?? '').toString().toLowerCase();

        if (dateStr.startsWith(hoyStr)) {
          _ventasHoy += totalValue;
        }

        // Mapeo exacto a Supabase check constraints
        if (estado == 'pending' || estado == 'preparing' || estado == 'ready') {
          _ordenesActivas++;
        }
      } catch (_) {}
    }

    final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioSemana = DateTime(
        lunesDeEstaSemana.year, lunesDeEstaSemana.month, lunesDeEstaSemana.day);
    final mesActualStr = ahora.toIso8601String().substring(0, 7);
    final anioActualStr = ahora.year.toString();

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
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.isNotEmpty) {
            final fechaOrd = DateTime.parse(dateStr);
            if (fechaOrd
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
              final diasDiferencia = fechaOrd.difference(inicioSemana).inDays;
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
          // Mapeo exacto a Supabase: expense_date
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
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        try {
          if (pagoProv.date.isNotEmpty) {
            final fechaPag = DateTime.parse(pagoProv.date);
            if (fechaPag
                .isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
              final diasDiferencia = fechaPag.difference(inicioSemana).inDays;
              if (diasDiferencia >= 0 && diasDiferencia < 7) {
                _currentGastos[diasDiferencia] += pagoProv.amount;
              }
            }
          }
        } catch (_) {}
      }
    } else if (_filterType == 'mes') {
      _currentLabels = ['01', '02', '03', '04'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map'))
              ? orden
              : orden.toJson();
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(mesActualStr)) {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
            _currentIngresos[indiceSemana] += totalValue;
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map'))
              ? gasto
              : gasto.toJson();
          final String dateStr =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(mesActualStr)) {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
            _currentGastos[indiceSemana] += amountValue;
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        if (pagoProv.date.startsWith(mesActualStr)) {
          final dia = int.tryParse(pagoProv.date.substring(8, 10)) ?? 1;
          final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
          _currentGastos[indiceSemana] += pagoProv.amount;
        }
      }
    } else {
      _currentLabels = ['Trim 1', 'Trim 2', 'Trim 3', 'Trim 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map'))
              ? orden
              : orden.toJson();
          final String dateStr = rawJson['created_at'] ?? '';
          final double totalValue =
              (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(anioActualStr)) {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
            _currentIngresos[indiceTrimestre] += totalValue;
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map'))
              ? gasto
              : gasto.toJson();
          final String dateStr =
              rawJson['expense_date'] ?? rawJson['created_at'] ?? '';
          final double amountValue =
              (rawJson['amount'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(anioActualStr)) {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
            _currentGastos[indiceTrimestre] += amountValue;
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        if (pagoProv.date.startsWith(anioActualStr)) {
          final mes = int.tryParse(pagoProv.date.substring(5, 7)) ?? 1;
          final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
          _currentGastos[indiceTrimestre] += pagoProv.amount;
        }
      }
    }

    // 3. EXTRACCIÓN Y CONSOLIDACIÓN DE SUB-TABLAS DE DETALLES DESDE SUPABASE
    for (var orden in _allOrders) {
      try {
        final rawJson = (orden.runtimeType.toString().contains('Map'))
            ? orden
            : orden.toJson();
        final String dateStr = rawJson['created_at'] ?? '';

        if (dateStr.isNotEmpty) {
          final fechaOrd = DateTime.parse(dateStr);

          if (cumpleFiltroFecha(
              fechaOrd, inicioSemana, mesActualStr, anioActualStr)) {
            // Mapeo exacto a Supabase: order_items
            final items = rawJson['order_items'] ?? rawJson['items'] ?? [];
            if (items is List) {
              for (var item in items) {
                final nombreProd =
                    (item['product_name'] ?? 'Producto General').toString();
                // Si tienes un join con categories, se extrae; si no, asume Varios.
                final categoriaProd = (item['categories'] != null
                        ? item['categories']['name']
                        : 'Varios')
                    .toString();
                final int cantidad = ((item['quantity'] ?? 1) as num).toInt();
                final double precioSubtotal =
                    ((item['total_price'] ?? item['unit_price'] ?? 0.0) as num)
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

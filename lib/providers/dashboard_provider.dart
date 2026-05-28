import 'package:flutter/material.dart';
import '../repositories/orden_repository.dart';
import '../repositories/gasto_repository.dart';
import '../repositories/payment_repository.dart';
import '../models/provider_payment.dart';

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

  // Variables dinámicas para las tarjetas superiores
  double _ventasHoy = 0.0;
  int _ordenesActivas = 0;
  double _ingresoFiltroTotal = 0.0;
  double _utilidadFiltroTotal = 0.0;

  // Listas estructuradas que alimentan las gráficas
  List<String> _currentLabels = [];
  List<double> _currentIngresos = [];
  List<double> _currentGastos = [];
  List<double> _currentUtilidad = [];

  // --- GETTERS PARA LOS RECUADROS SUPERIORES (DINÁMICOS) ---
  double get ventasHoy => _ventasHoy;
  int get ordenesActivas => _ordenesActivas;
  double get ingresoFiltroTotal => _ingresoFiltroTotal;
  double get utilidadFiltroTotal => _utilidadFiltroTotal;

  // --- GETTERS GENERALES Y DE GRÁFICAS ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  List<String> get currentLabels => _currentLabels;
  List<double> get currentIngresos => _currentIngresos;
  List<double> get currentGastos => _currentGastos;
  List<double> get currentUtilidad => _currentUtilidad;

  // Getter auxiliar para cambiar el texto de los títulos en la UI
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

  // --- CONSULTA ASÍNCRONA DESDE SUPABASE ---
  Future<void> cargarMetricasGlobales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dynamic repoOrdenes = _ordenRepository;
      final dynamic repoGastos = _gastoRepository;

      final ordersFuture = (repoOrdenes.runtimeType.toString().contains('OrdenRepository'))
          ? _clientFetch(repoOrdenes)
          : Future.value([]);
          
      final expensesFuture = (repoGastos.runtimeType.toString().contains('GastoRepository'))
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

  // --- MOTOR MATEMÁTICO ANALÍTICO DE INTERFACES ---
  void _procesarOperacionesFinancieras() {
    final ahora = DateTime.now();
    final hoyStr = ahora.toIso8601String().substring(0, 10); 

    // Reinicio de las métricas fijas del día
    _ventasHoy = 0.0;
    _ordenesActivas = 0;

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS
    for (var orden in _allOrders) {
      try {
        final rawJson = (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
        final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
        final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;
        final String estado = (rawJson['status'] ?? rawJson['estado'] ?? '').toString().toLowerCase();

        if (dateStr.startsWith(hoyStr)) {
          _ventasHoy += totalValue;
        }

        if (estado == 'en cocina' || estado == 'pendiente' || estado == 'activa' || estado == '4') {
          _ordenesActivas++;
        }
      } catch (_) {}
    }

    // 2. AGRUPAMIENTO Y CARGA DE VECTORES DE GRÁFICAS
    if (_filterType == 'semana') {
      _currentLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      _currentIngresos = List.generate(7, (_) => 0.0);
      _currentGastos = List.generate(7, (_) => 0.0);

      final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final inicioSemana = DateTime(lunesDeEstaSemana.year, lunesDeEstaSemana.month, lunesDeEstaSemana.day);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          final fechaOrd = DateTime.parse(dateStr);
          if (fechaOrd.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
            final diasDiferencia = fechaOrd.difference(inicioSemana).inDays;
            if (diasDiferencia >= 0 && diasDiferencia < 7) {
              _currentIngresos[diasDiferencia] += totalValue;
            }
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map')) ? gasto : gasto.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double amountValue = (rawJson['amount'] as num?)?.toDouble() ?? (rawJson['monto'] as num?)?.toDouble() ?? 0.0;

          final fechaGst = DateTime.parse(dateStr);
          if (fechaGst.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
            final diasDiferencia = fechaGst.difference(inicioSemana).inDays;
            if (diasDiferencia >= 0 && diasDiferencia < 7) {
              _currentGastos[diasDiferencia] += amountValue;
            }
          }
        } catch (_) {}
      }

      for (var pagoProv in _allSupplierPayments) {
        try {
          final fechaPag = DateTime.parse(pagoProv.date);
          if (fechaPag.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
            final diasDiferencia = fechaPag.difference(inicioSemana).inDays;
            if (diasDiferencia >= 0 && diasDiferencia < 7) {
              _currentGastos[diasDiferencia] += pagoProv.amount;
            }
          }
        } catch (_) {}
      }

    } else if (_filterType == 'mes') {
      _currentLabels = ['01', '02', '03', '04'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);

      final mesActualStr = ahora.toIso8601String().substring(0, 7);

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(mesActualStr)) {
            final dia = int.tryParse(dateStr.substring(8, 10)) ?? 1;
            final indiceSemana = ((dia - 1) / 7).floor().clamp(0, 3);
            _currentIngresos[indiceSemana] += totalValue;
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map')) ? gasto : gasto.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double amountValue = (rawJson['amount'] as num?)?.toDouble() ?? (rawJson['monto'] as num?)?.toDouble() ?? 0.0;

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

      final anioActualStr = ahora.year.toString(); 

      for (var orden in _allOrders) {
        try {
          final rawJson = (orden.runtimeType.toString().contains('Map')) ? orden : orden.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double totalValue = (rawJson['total'] as num?)?.toDouble() ?? 0.0;

          if (dateStr.startsWith(anioActualStr)) {
            final mes = int.tryParse(dateStr.substring(5, 7)) ?? 1;
            final indiceTrimestre = ((mes - 1) / 3).floor().clamp(0, 3);
            _currentIngresos[indiceTrimestre] += totalValue;
          }
        } catch (_) {}
      }

      for (var gasto in _allExpenses) {
        try {
          final rawJson = (gasto.runtimeType.toString().contains('Map')) ? gasto : gasto.toJson();
          final String dateStr = rawJson['date'] ?? rawJson['fecha'] ?? '';
          final double amountValue = (rawJson['amount'] as num?)?.toDouble() ?? (rawJson['monto'] as num?)?.toDouble() ?? 0.0;

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

    // 3. GENERACIÓN DE VECTORES DE UTILIDAD Y TOTALES ACUMULADOS POR FILTRO
    _currentUtilidad = List.generate(_currentIngresos.length, (_) => 0.0);
    _ingresoFiltroTotal = 0.0;
    double totalGastosFiltro = 0.0;

    for (int i = 0; i < _currentIngresos.length; i++) {
      _currentUtilidad[i] = _currentIngresos[i] - _currentGastos[i];
      _ingresoFiltroTotal += _currentIngresos[i];
      totalGastosFiltro += _currentGastos[i];
    }

    // El resultado final de los recuadros se acopla dinámicamente al acumulado total de la gráfica activa
    _utilidadFiltroTotal = _ingresoFiltroTotal - totalGastosFiltro;
  }
}
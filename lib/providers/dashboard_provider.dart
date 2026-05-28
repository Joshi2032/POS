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

  // Variables para las tarjetas de métricas superiores
  double _ventasHoy = 0.0;
  int _ordenesActivas = 0;
  double _ingresoSemanalTotal = 0.0;
  double _utilidadSemanalTotal = 0.0;

  // Listas estructuradas que alimentan las gráficas
  List<String> _currentLabels = [];
  List<double> _currentIngresos = [];
  List<double> _currentGastos = [];
  List<double> _currentUtilidad = [];

  // --- GETTERS PARA LOS RECUADROS SUPERIORES ---
  double get ventasHoy => _ventasHoy;
  int get ordenesActivas => _ordenesActivas;
  double get ingresoSemanalTotal => _ingresoSemanalTotal;
  double get utilidadSemanalTotal => _utilidadSemanalTotal;

  // --- GETTERS GENERALES Y DE GRÁFICAS ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  List<String> get currentLabels => _currentLabels;
  List<double> get currentIngresos => _currentIngresos;
  List<double> get currentGastos => _currentGastos;
  List<double> get currentUtilidad => _currentUtilidad;

  // --- SELECTOR DE FILTRO ---
  void setFilterType(String type) {
    if (_filterType == type) return; 
    _filterType = type;
    
    // Recalcula los rangos basándose en la nueva opción seleccionada
    _procesarOperacionesFinancieras();
    
    // Alerta a la UI para redibujar los gráficos de inmediato
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

    // Reinicio de las métricas de las tarjetas
    _ventasHoy = 0.0;
    _ordenesActivas = 0;
    _ingresoSemanalTotal = 0.0;
    _utilidadSemanalTotal = 0.0;

    final lunesDeEstaSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioSemana = DateTime(lunesDeEstaSemana.year, lunesDeEstaSemana.month, lunesDeEstaSemana.day);

    // 1. CÁLCULO DE VENTAS DE HOY Y ÓRDENES ACTIVAS (Independiente del Dropdown)
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

    // 2. AGRUPAMIENTO ESPECÍFICO PARA LAS GRÁFICAS SEGÚN LA TEMPORALIDAD
    if (_filterType == 'semana') {
      _currentLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      _currentIngresos = List.generate(7, (_) => 0.0);
      _currentGastos = List.generate(7, (_) => 0.0);
      _currentUtilidad = List.generate(7, (_) => 0.0);

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

      _ingresoSemanalTotal = _currentIngresos.fold(0, (sum, item) => sum + item);
      double gastosSemanales = _currentGastos.fold(0, (sum, item) => sum + item);
      _utilidadSemanalTotal = _ingresoSemanalTotal - gastosSemanales;

    } else if (_filterType == 'mes') {
      // CORREGIDO: Etiquetas numéricas de dos dígitos estrictas (01, 02, 03, 04)
      _currentLabels = ['01', '02', '03', '04'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);
      _currentUtilidad = List.generate(4, (_) => 0.0);

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

      _calcularTotalesSemanalesFijos(inicioSemana);

    } else {
      _currentLabels = ['Trim 1', 'Trim 2', 'Trim 3', 'Trim 4'];
      _currentIngresos = List.generate(4, (_) => 0.0);
      _currentGastos = List.generate(4, (_) => 0.0);
      _currentUtilidad = List.generate(4, (_) => 0.0);

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

      _calcularTotalesSemanalesFijos(inicioSemana);
    }

    // Calcular las barras de utilidad final
    for (int i = 0; i < _currentIngresos.length; i++) {
      _currentUtilidad[i] = _currentIngresos[i] - _currentGastos[i];
    }
  }

  void _calcularTotalesSemanalesFijos(DateTime inicioSemana) {
    double ingSem = 0.0;
    double gstSem = 0.0;

    for (var o in _allOrders) {
      try {
        final raw = (o.runtimeType.toString().contains('Map')) ? o : o.toJson();
        final f = DateTime.parse(raw['date'] ?? raw['fecha'] ?? '');
        if (f.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
          if (f.difference(inicioSemana).inDays < 7) ingSem += (raw['total'] as num).toDouble();
        }
      } catch (_) {}
    }

    for (var g in _allExpenses) {
      try {
        final raw = (g.runtimeType.toString().contains('Map')) ? g : g.toJson();
        final f = DateTime.parse(raw['date'] ?? raw['fecha'] ?? '');
        if (f.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
          if (f.difference(inicioSemana).inDays < 7) {
            gstSem += (raw['amount'] as num?)?.toDouble() ?? (raw['monto'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (_) {}
    }

    for (var p in _allSupplierPayments) {
      final f = DateTime.parse(p.date);
      if (f.isAfter(inicioSemana.subtract(const Duration(seconds: 1)))) {
        if (f.difference(inicioSemana).inDays < 7) gstSem += p.amount;
      }
    }

    _ingresoSemanalTotal = ingSem;
    _utilidadSemanalTotal = ingSem - gstSem;
  }
}
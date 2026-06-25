import 'package:flutter/material.dart';

import '../models/nomina_pago.dart';
import '../repositories/nomina_pago_repository.dart';

class NominasProvider extends ChangeNotifier {
  NominasProvider(this._repository) {
    cargarNominas();
  }

  final NominaPagoRepository _repository;

  final int pageSize = 10;

  final List<String> tipos = [
    'Todos',
    'Salario',
    'Adelanto',
    'Bono',
    'Deducción',
  ];

  List<NominaPago> _nominas = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _search = '';
  String _selectedType = 'Todos';
  int _currentPage = 1;

  // ── GETTERS ────────────────────────────────────────────────

  String get search => _search;
  String get selectedType => _selectedType;
  int get currentPage => _currentPage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<NominaPago> get nominasFiltradas {
    final busqueda = _search.trim().toLowerCase();

    return _nominas.where((nomina) {
      final coincideBusqueda =
          busqueda.isEmpty ||
          nomina.empleado.toLowerCase().contains(busqueda) ||
          nomina.tipo.toLowerCase().contains(busqueda) ||
          nomina.metodo.toLowerCase().contains(busqueda);

      final coincideTipo =
          _selectedType == 'Todos' ||
          nomina.tipo.toLowerCase() ==
              _selectedType.toLowerCase();

      return coincideBusqueda && coincideTipo;
    }).toList();
  }

  List<NominaPago> get paginatedNominas {
    final registros = nominasFiltradas;
    final inicio = (_currentPage - 1) * pageSize;

    if (inicio >= registros.length) {
      return [];
    }

    return registros
        .skip(inicio)
        .take(pageSize)
        .toList();
  }

  int get totalPages {
    final paginas =
        (nominasFiltradas.length / pageSize).ceil();

    return paginas < 1 ? 1 : paginas;
  }

  double get totalMensual {
    final ahora = DateTime.now();

    return _nominas.where((nomina) {
      final fecha = DateTime.tryParse(nomina.fecha);

      return fecha != null &&
          fecha.year == ahora.year &&
          fecha.month == ahora.month;
    }).fold<double>(0, (total, nomina) {
      final tipo = nomina.tipo.trim().toLowerCase();

      final esDeduccion =
          tipo == 'deducción' ||
          tipo == 'deduccion';

      return esDeduccion
          ? total - nomina.monto
          : total + nomina.monto;
    });
  }

  // ── CARGA DE DATOS ─────────────────────────────────────────

  Future<void> cargarNominas() async {
    _setLoading(true);
    _clearError();

    try {
      _nominas = await _repository.getAll();
      _ajustarPaginaActual();
    } catch (e) {
      _errorMessage =
          'No se pudieron cargar los pagos: $e';

      debugPrint(
        'Error al cargar nóminas: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ── FILTROS Y PAGINACIÓN ───────────────────────────────────

  void setSearch(String value) {
    _search = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setType(String value) {
    _selectedType = value;
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int page) {
    if (page < 1 || page > totalPages) {
      return;
    }

    _currentPage = page;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────

  Future<bool> agregarNomina(
    NominaPago nomina,
  ) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.create(nomina);
      await _recargarLista();

      return true;
    } catch (e) {
      _errorMessage =
          'No se pudo registrar el pago: $e';

      debugPrint(
        'Error agregando nómina: $e',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarNomina(
    dynamic id,
    NominaPago nomina,
  ) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.update(
        id.toString(),
        nomina,
      );

      await _recargarLista();

      return true;
    } catch (e) {
      _errorMessage =
          'No se pudo actualizar el pago: $e';

      debugPrint(
        'Error actualizando nómina: $e',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarNomina(
    dynamic id,
  ) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.delete(
        id.toString(),
      );

      await _recargarLista();

      return true;
    } catch (e) {
      _errorMessage =
          'No se pudo eliminar el pago: $e';

      debugPrint(
        'Error eliminando nómina: $e',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── AUXILIARES ─────────────────────────────────────────────

  Future<void> _recargarLista() async {
    _nominas = await _repository.getAll();
    _ajustarPaginaActual();
  }

  void _ajustarPaginaActual() {
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    if (_currentPage < 1) {
      _currentPage = 1;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
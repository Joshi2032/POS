import 'package:flutter/material.dart';

import '../models/mesa.dart';
import '../repositories/mesa_repository.dart';

class MesasProvider extends ChangeNotifier {
  final MesaRepository _repository;

  MesasProvider(this._repository) {
    cargarMesas();
  }

  List<Mesa> _mesas = [];
  String _filtroSeleccionado = 'Todas';

  bool _isLoading = false;
  String? _errorMessage;

  List<Mesa> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String get filtroSeleccionado => _filtroSeleccionado;

  List<String> get filtros => [
        'Todas',
        'Disponibles',
        'Ocupadas',
        'Por Cobrar',
      ];

  List<String> get areas {
    final areasEncontradas = _mesas
        .map((mesa) => mesa.area.trim())
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();

    areasEncontradas.sort();

    return ['Todas', ...areasEncontradas];
  }

  int get libres {
    return _mesas.where((mesa) {
      final estado = mesa.estado.trim().toLowerCase();

      return estado == 'libre' || estado == 'disponible';
    }).length;
  }

  int get ocupadas {
    return _mesas.where((mesa) {
      return mesa.estado.trim().toLowerCase() == 'ocupada';
    }).length;
  }

  int get porCobrar {
    return _mesas.where((mesa) {
      final estado = mesa.estado.trim().toLowerCase();

      return estado == 'por cobrar' || estado == 'cuenta';
    }).length;
  }

  Future<void> cargarMesas() async {
    _setLoading(true);
    _clearError();

    try {
      _mesas = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMesa(Mesa mesa) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.create(mesa);
      _mesas = await _repository.getAll();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMesa(
    dynamic id,
    Mesa mesa,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final convertedId = id.toString();

      await _repository.update(
        convertedId,
        mesa,
      );

      _mesas = await _repository.getAll();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMesa(dynamic id) async {
    _setLoading(true);
    _clearError();

    try {
      final convertedId = id.toString();

      await _repository.delete(convertedId);
      _mesas = await _repository.getAll();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeMesa(dynamic id) {
    return deleteMesa(id);
  }

  Future<bool> cambiarEstadoMesa(
    String id,
    String nuevoEstado,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      var index = _mesas.indexWhere(
        (mesa) => mesa.id.toString() == id.toString(),
      );

      if (index == -1) {
        _mesas = await _repository.getAll();

        index = _mesas.indexWhere(
          (mesa) => mesa.id.toString() == id.toString(),
        );
      }

      if (index == -1) {
        throw Exception(
          'No se encontró la mesa con id: $id',
        );
      }

      final mesaActual = _mesas[index];

      final mesaActualizada = Mesa(
        id: mesaActual.id,
        nombre: mesaActual.nombre,
        capacidad: mesaActual.capacidad,
        area: mesaActual.area,
        estado: nuevoEstado,
      );

      await _repository.update(
        mesaActual.id.toString(),
        mesaActualizada,
      );

      _mesas = await _repository.getAll();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          'Error al cambiar estado de la mesa: $e';

      debugPrint(_errorMessage);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setFiltro(String filtro) {
    _filtroSeleccionado = filtro;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    setFiltro(status);
  }

  List<Mesa> get mesasFiltradas {
    if (_filtroSeleccionado == 'Todas') {
      return _mesas;
    }

    return _mesas.where((mesa) {
      final estado =
          mesa.estado.trim().toLowerCase();

      if (_filtroSeleccionado == 'Disponibles') {
        return estado == 'libre' ||
            estado == 'disponible';
      }

      if (_filtroSeleccionado == 'Ocupadas') {
        return estado == 'ocupada';
      }

      if (_filtroSeleccionado == 'Por Cobrar') {
        return estado == 'por cobrar' ||
            estado == 'cuenta';
      }

      return mesa.area.trim().toLowerCase() ==
          _filtroSeleccionado.trim().toLowerCase();
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}


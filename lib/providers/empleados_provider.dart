import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../repositories/empleado_repository.dart';

class EmpleadosProvider extends ChangeNotifier {
  final EmpleadoRepository _repository;

  EmpleadosProvider(this._repository) {
    cargarEmpleados();
  }

  List<Empleado> _empleados = [];
  String _searchTerm = '';
  String _selectedRol = 'Todos';
  bool _isLoading = false;
  String? _errorMessage;

  List<Empleado> get empleados => _empleados;
  String get searchTerm => _searchTerm;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get selectedRol => _selectedRol;
  
  List<String> get roles => ['Todos', 'Mesero', 'Cajero', 'Cocinero', 'Gerente', 'Admin'];

  Future<void> cargarEmpleados() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _empleados = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> agregarEmpleado(Empleado empleado) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.create(empleado);
      await cargarEmpleados();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarEmpleado(String id, Empleado empleado) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.update(id, empleado);
      await cargarEmpleados();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarEmpleado(String id) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.delete(id);
      await cargarEmpleados();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedRol(String rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }
List<Empleado> get empleadosFiltrados {
  return _empleados.where((e) {
    final String fullName =
        '${e.firstName} ${e.lastName}'.toLowerCase();

    final String position = e.position.toLowerCase();
    final String email = e.email.toLowerCase();
    final String query = _searchTerm.trim().toLowerCase();

    final matchesSearch =
        fullName.contains(query) ||
        position.contains(query) ||
        email.contains(query);

    final matchesRole =
        _selectedRol == 'Todos' ||
        e.position == _selectedRol;

    return matchesSearch && matchesRole;
  }).toList();
}
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
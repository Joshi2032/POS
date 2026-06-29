import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../repositories/empleado_repository.dart';

class EmpleadosProvider extends ChangeNotifier {
  final EmpleadoRepository _repository;

  EmpleadosProvider(this._repository) {
    cargarEmpleados();
    cargarAreasDisponibles();
  }

  List<Empleado> _empleados = [];
  List<String> _areasDisponibles = [];

  String _searchTerm = '';
  String _selectedRol = 'Todos';
  bool _isLoading = false;
  String? _errorMessage;

  List<Empleado> get empleados => _empleados;
  List<String> get areasDisponibles => _areasDisponibles;

  String get searchTerm => _searchTerm;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get selectedRol => _selectedRol;

  List<String> get roles => [
        'Todos',
        'Mesero',
        'Cajero',
        'Cocinero',
        'Gerente',
        'Admin',
      ];

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

  Future<void> cargarAreasDisponibles() async {
    try {
      _areasDisponibles = await _repository.getAvailableTableAreas();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<String>> obtenerAreasEmpleado(
    String employeeId,
  ) async {
    try {
      return await _repository.getAreasByEmployeeId(
        employeeId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> agregarEmpleado(
    Empleado empleado, {
    List<String> areasAsignadas = const [],
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final creado = await _repository.create(empleado);

      if (creado.position == 'Mesero') {
        await _repository.setAreasForEmployee(
          employeeId: creado.id,
          areas: areasAsignadas,
        );
      }

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

  Future<bool> actualizarEmpleado(
    String id,
    Empleado empleado, {
    List<String> areasAsignadas = const [],
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.update(id, empleado);

      await _repository.setAreasForEmployee(
        employeeId: id,
        areas: empleado.position == 'Mesero' ? areasAsignadas : [],
      );

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
      final String fullName = '${e.firstName} ${e.lastName}'.toLowerCase();

      final String position = e.position.toLowerCase();
      final String email = e.email.toLowerCase();
      final String query = _searchTerm.trim().toLowerCase();

      final matchesSearch = fullName.contains(query) ||
          position.contains(query) ||
          email.contains(query);

      final matchesRole = _selectedRol == 'Todos' || e.position == _selectedRol;

      return matchesSearch && matchesRole;
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> agregarEmpleadoConAcceso(
    Empleado empleado, {
    required String password,
    List<String> areasAsignadas = const [],
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.createEmployeeWithAuth(
        empleado: empleado,
        password: password,
        areas: areasAsignadas,
      );

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
}

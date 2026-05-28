import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../repositories/empleado_repository.dart';

class EmpleadosProvider extends ChangeNotifier {
  final EmpleadoRepository _repository;

  EmpleadosProvider(this._repository) {
    cargarEmpleados();
  }

  List<Empleado> _empleados = [];
  bool _isLoading = false;

  final List<String> roles = [
    'Todos',
    'Administrador',
    'Cocinero',
    'Mesero',
    'Cajero'
  ];

  String _searchTerm = '';
  String _selectedRol = 'Todos';

  List<Empleado> get empleados => _empleados;
  String get searchTerm => _searchTerm;
  String get selectedRol => _selectedRol;
  bool get isLoading => _isLoading;

  List<Empleado> get empleadosFiltrados {
    return _empleados.where((e) {
      final matchSearch = _searchTerm.isEmpty ||
          e.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          e.correo.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchRol = _selectedRol == 'Todos' || e.rol == _selectedRol;
      return matchSearch && matchRol;
    }).toList();
  }

  List<Empleado> get empleadosActivos => _empleados.where((e) => e.activo).toList();

  Future<void> cargarEmpleados() async {
    _isLoading = true;
    notifyListeners();
    try {
      _empleados = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setSelectedRol(String rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  Future<void> agregarEmpleado(Empleado empleado) async {
    try {
      await _repository.create(empleado);
      await cargarEmpleados();
    } catch (e) {
      debugPrint('Error agregando empleado: $e');
    }
  }

  Future<void> actualizarEmpleado(String id, Empleado empleado) async {
    try {
      await _repository.update(id, empleado);
      await cargarEmpleados();
    } catch (e) {
      debugPrint('Error actualizando empleado: $e');
    }
  }

  Future<void> eliminarEmpleado(String id) async {
    try {
      await _repository.delete(id);
      await cargarEmpleados();
    } catch (e) {
      debugPrint('Error eliminando empleado: $e');
    }
  }

  Future<void> toggleEmpleadoActivo(String id, bool activo) async {
    try {
      await _repository.toggleActivo(id, activo);
      await cargarEmpleados();
    } catch (e) {
      debugPrint('Error al cambiar estado de empleado: $e');
    }
  }
}
      
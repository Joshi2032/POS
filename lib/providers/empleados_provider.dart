import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../repositories/empleado_repository.dart';

class EmpleadosProvider extends ChangeNotifier {
  final EmpleadoRepository _repository;

  EmpleadosProvider(this._repository) {
    cargarEmpleados(); // Carga inicial al levantar el módulo
  }

  List<Empleado> _empleados = [];
  String _searchTerm = '';
  String _selectedRol = 'Todos'; // Cambiado de _selectedRole a _selectedRol para tu UI

  // --- ESTADOS DE CONTROL DE FLUJO Y ERRORES ---
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS COMPATIBLES CON TU VISTA ORIGINAL (empleados_page.dart) ---
  List<Empleado> get empleados => _empleados;
  String get searchTerm => _searchTerm;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getters exactos que pide tu interfaz visual
  String get selectedRol => _selectedRol;
  String get selectedRole => _selectedRol; // Mantener alias por seguridad

  // Lista estática o dinámica de roles que utiliza tu UI para pintar los dropdowns o pestañas
  List<String> get roles => ['Todos', 'Administrador', 'Mesero', 'Cocinero', 'Cajero'];

  // --- MÉTODOS CRUD CON GESTIÓN DE ERRORES ---
  Future<void> cargarEmpleados() async {
    _setLoading(true);
    _clearError();
    try {
      _empleados = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addEmpleado(Empleado empleado) async {
    _setLoading(true);
    _clearError();
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

  // Enlaces de nombre idénticos a los errores de tu UI (línea 139)
  Future<bool> agregarEmpleado(Empleado empleado) => addEmpleado(empleado);
  Future<bool> crearEmpleado(Empleado empleado) => addEmpleado(empleado);

  Future<bool> updateEmpleado(dynamic id, Empleado empleado) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, empleado);
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

  Future<bool> actualizarEmpleado(dynamic id, Empleado empleado) => updateEmpleado(id, empleado);

  Future<bool> deleteEmpleado(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
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

  Future<bool> eliminarEmpleado(dynamic id) => deleteEmpleado(id);
  Future<bool> removeEmpleado(dynamic id) => deleteEmpleado(id);

  // --- CONTROL DE FILTROS DE INTERFAZ REQUERIDOS (Líneas 197 y 212) ---
  void setSelectedRol(String rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    setSelectedRol(role);
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  // --- FILTRADOS DE COMPONENTES BASADOS EN EL ROL ORIGINAL DE TU MODELO ---
  List<Empleado> get empleadosFiltrados {
    return _empleados.where((e) {
      final String nombreLower = (e.nombre).toLowerCase();
      final String rolLower = (e.rol).toLowerCase(); 
      final String query = _searchTerm.toLowerCase();

      final matchesSearch = nombreLower.contains(query) || rolLower.contains(query);
      final matchesRole = _selectedRol == 'Todos' || e.rol == _selectedRol; 

      return matchesSearch && matchesRole;
    }).toList();
  }

  // --- MÉTODOS AUXILIARES ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
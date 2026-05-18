import 'package:flutter/material.dart';

class Empleado {
  final String nombre;
  final String rol;
  final String telefono;
  final bool activo;

  Empleado({
    required this.nombre,
    required this.rol,
    required this.telefono,
    this.activo = true,
  });

  Empleado copyWith({String? nombre, String? rol, String? telefono, bool? activo}) {
    return Empleado(
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
    );
  }
}

class EmpleadosProvider extends ChangeNotifier {
  final List<Empleado> _empleados = [
    Empleado(nombre: 'Carlos Mendoza', rol: 'Mesero', telefono: '3521234567'),
    Empleado(nombre: 'Ana Rodríguez', rol: 'Cocinero', telefono: '3527654321'),
    Empleado(nombre: 'Juan Pérez', rol: 'Administrador', telefono: '3529876543'),
    Empleado(nombre: 'Sofia Gómez', rol: 'Cajero', telefono: '3524567890', activo: false),
  ];

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

  List<Empleado> get empleadosFiltrados {
    return _empleados.where((e) {
      final matchesSearch = e.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          e.telefono.contains(_searchTerm);
      final matchesRol = _selectedRol == 'Todos' || e.rol == _selectedRol;
      return matchesSearch && matchesRol;
    }).toList();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setRol(String rol) {
    _selectedRol = rol;
    notifyListeners();
  }

  void addEmpleado(Empleado empleado) {
    _empleados.add(empleado);
    notifyListeners();
  }

  void updateEmpleado(int index, Empleado empleado) {
    _empleados[index] = empleado;
    notifyListeners();
  }

  void removeEmpleado(Empleado empleado) {
    _empleados.remove(empleado);
    notifyListeners();
  }
}
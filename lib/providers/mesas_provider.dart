import 'package:flutter/material.dart';

class Mesa {
  String nombre;
  int capacidad;
  String area;
  String estado; // 'Libre' | 'Ocupada'

  Mesa({
    required this.nombre,
    required this.capacidad,
    required this.area,
    required this.estado,
  });
}

class MesasProvider extends ChangeNotifier {
  final List<Mesa> _mesas = [
    Mesa(nombre: 'Mesa A1', capacidad: 4, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa A2', capacidad: 4, area: 'Área A', estado: 'Ocupada'),
    Mesa(nombre: 'Mesa A3', capacidad: 6, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa A4', capacidad: 4, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa B1', capacidad: 4, area: 'Área B', estado: 'Libre'),
    Mesa(nombre: 'Mesa B2', capacidad: 6, area: 'Área B', estado: 'Ocupada'),
    Mesa(nombre: 'Mesa B3', capacidad: 4, area: 'Área B', estado: 'Libre'),
  ];

  String _filtroSeleccionado = 'Todas';

  // Getters simples
  List<Mesa> get mesas => _mesas;
  String get filtroSeleccionado => _filtroSeleccionado;

  // Lógica computada transferida
  List<String> get areas => _mesas.map((m) => m.area).toSet().toList();
  List<String> get filtros => ['Todas', ...areas];

  List<Mesa> get mesasFiltradas {
    if (_filtroSeleccionado == 'Todas') return _mesas;
    return _mesas.where((m) => m.area == _filtroSeleccionado).toList();
  }

  int get libres => mesasFiltradas.where((m) => m.estado == 'Libre').length;
  int get ocupadas => mesasFiltradas.where((m) => m.estado == 'Ocupada').length;
  int get porCobrar => ocupadas;

  // Acciones
  void setFiltro(String filtro) {
    _filtroSeleccionado = filtro;
    notifyListeners();
  }

  void addMesa(Mesa mesa) {
    _mesas.add(mesa);
    notifyListeners();
  }

  void updateMesa(int index, Mesa mesaEditada) {
    _mesas[index].nombre = mesaEditada.nombre;
    _mesas[index].capacidad = mesaEditada.capacidad;
    _mesas[index].area = mesaEditada.area;
    notifyListeners();
  }

  void removeMesa(Mesa mesa) {
    _mesas.remove(mesa);
    notifyListeners();
  }
}
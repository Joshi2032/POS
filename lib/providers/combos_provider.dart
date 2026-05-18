import 'package:flutter/material.dart';

class Combo {
  final String nombre;
  final String descripcion;
  final double precio;
  final bool activo;

  Combo({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.activo = true,
  });
}

class CombosProvider extends ChangeNotifier {
  final List<Combo> _combos = [
    Combo(nombre: 'Combo Familiar Parrillero', descripcion: '1 T-Bone 500g, 1 Arrachera 300g, 2 Guarniciones y 1 Jarra de agua.', precio: 850.00),
    Combo(nombre: 'Combo Pareja', descripcion: '1 Costilla BBQ, 1 Pechuga Asada, 2 Bebidas y 1 Postre a elegir.', precio: 450.00),
    Combo(nombre: 'Combo Ejecutivo', descripcion: 'Arrachera 200g, ensalada de la casa y bebida.', precio: 220.00),
    Combo(nombre: 'Paquete Botanero', descripcion: 'Alitas, Papas al carbón, Queso fundido y 2 Cervezas.', precio: 380.00, activo: false),
  ];

  String _searchTerm = '';

  String get searchTerm => _searchTerm;
  List<Combo> get combos => _combos;

  List<Combo> get combosFiltrados {
    return _combos.where((c) {
      final matchNombre = c.nombre.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchDesc = c.descripcion.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchNombre || matchDesc;
    }).toList();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void addCombo(Combo combo) {
    _combos.add(combo);
    notifyListeners();
  }

  void updateCombo(int index, Combo combo) {
    _combos[index] = combo;
    notifyListeners();
  }

  void removeCombo(Combo combo) {
    _combos.remove(combo);
    notifyListeners();
  }
}
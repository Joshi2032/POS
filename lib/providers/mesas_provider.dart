// lib/providers/mesas_provider.dart
import 'package:flutter/material.dart';
import '../models/mesa.dart'; // Usamos tu modelo real
import '../repositories/mesa_repository.dart'; // Importamos el repo

class MesasProvider extends ChangeNotifier {
  final MesaRepository _repository;

  List<Mesa> _mesas = [];
  String _filtroSeleccionado = 'Todas';

  MesasProvider(this._repository) {
    cargarMesas();
  }

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

  // Acciones (Convertidas a asíncronas para Supabase)
  Future<void> cargarMesas() async {
    _mesas = await _repository.getAll();
    notifyListeners();
  }

  void setFiltro(String filtro) {
    _filtroSeleccionado = filtro;
    notifyListeners();
  }

  Future<void> addMesa(Mesa mesa) async {
    await _repository.create(mesa);
    await cargarMesas(); // Recarga la lista desde internet
  }

  Future<void> updateMesa(int index, Mesa mesaEditada) async {
    // Tomamos el ID de la mesa original usando el index para actualizarla
    final idMesa = _mesas[index].id;
    await _repository.update(idMesa, mesaEditada);
    await cargarMesas();
  }

  Future<void> removeMesa(Mesa mesa) async {
    await _repository.delete(mesa.id);
    await cargarMesas();
  }
}
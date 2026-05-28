import 'package:flutter/material.dart';
import '../models/mesa.dart';
import '../repositories/mesa_repository.dart';

class MesasProvider extends ChangeNotifier {
  final MesaRepository _repository;

  MesasProvider(this._repository) {
    cargarMesas(); // Carga inicial de datos
  }

  List<Mesa> _mesas = [];
  String _filtroSeleccionado = 'Todas'; 

  // --- ESTADOS DE CONTROL DE FLUJO Y ERRORES ---
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS COMPATIBLES CON TU VISTA (mesas_page.dart) ---
  List<Mesa> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String get filtroSeleccionado => _filtroSeleccionado;

  // Lista estática de filtros generales de la UI
  List<String> get filtros => ['Todas', 'Disponibles', 'Ocupadas', 'Por Cobrar'];

  // Áreas del restaurante calculadas dinámicamente desde el modelo real
  List<String> get areas {
    final deModelos = _mesas.map((m) => m.area).where((a) => a.isNotEmpty).toSet().toList();
    deModelos.sort();
    return ['Todas', ...deModelos];
  }

  // --- CONTADORES KPI CORREGIDOS UTILIZANDO TU PROPIEDAD 'estado' ---
  int get libres => _mesas.where((m) => m.estado.toLowerCase() == 'libre' || m.estado.toLowerCase() == 'disponible').length;
  int get ocupadas => _mesas.where((m) => m.estado.toLowerCase() == 'ocupada').length;
  int get porCobrar => _mesas.where((m) => m.estado.toLowerCase() == 'por cobrar' || m.estado.toLowerCase() == 'cuenta').length;

  // --- MÉTODOS CRUD ADAPTADOS CON INTERCEPCIÓN DE TIPOS ---
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
      await cargarMesas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMesa(dynamic id, Mesa mesa) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, mesa);
      await cargarMesas();
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
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarMesas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeMesa(dynamic id) => deleteMesa(id);

  // --- CONTROL DE FILTROS DE INTERFAZ ---
  void setFiltro(String filtro) {
    _filtroSeleccionado = filtro;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    setFiltro(status);
  }

  // --- FILTRADO DE COMPONENTES BASADO EN TU MODELO ORIGINAL ---
  List<Mesa> get mesasFiltradas {
    if (_filtroSeleccionado == 'Todas') {
      return _mesas;
    }
    
    return _mesas.where((m) {
      final estadoLower = m.estado.toLowerCase(); // Corregido para leer 'estado'
      if (_filtroSeleccionado == 'Disponibles') {
        return estadoLower == 'libre' || estadoLower == 'disponible';
      }
      if (_filtroSeleccionado == 'Ocupadas') {
        return estadoLower == 'ocupada';
      }
      if (_filtroSeleccionado == 'Por Cobrar') {
        return estadoLower == 'por cobrar' || estadoLower == 'cuenta';
      }
      
      // Filtro alterno por el nombre del área
      return m.area == _filtroSeleccionado;
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
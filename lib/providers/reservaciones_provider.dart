// lib/providers/reservaciones_provider.dart
import 'package:flutter/material.dart';
import '../models/reservacion.dart';
import '../repositories/reservacion_repository.dart';

class ReservacionesProvider extends ChangeNotifier {
  final ReservacionRepository _repository;

  final int pageSize = 10;
  final String todayIso = DateTime.now().toIso8601String().substring(0, 10);

  // Listas que vendrán desde Supabase
  List<Reservacion> _reservations = [];
  List<Reservacion> _todayReservations =
      []; // Mantiene las estadísticas de hoy exactas

  String _searchTerm = '';
  int _currentPage = 1;
  late String _selectedDate;
  String? _editingId;
  bool _showModal = false;
  String _modalError = '';

  Map<String, dynamic> _formValues = {};

  // Constructor inyectado
  ReservacionesProvider(this._repository) {
    _selectedDate = todayIso;
    _resetForm();
    _cargarDatos();
  }

  // ==== GETTERS ====
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  String get selectedDate => _selectedDate;
  String? get editingId => _editingId;
  bool get showModal => _showModal;
  String get modalError => _modalError;
  Map<String, dynamic> get formValues => _formValues;

  List<Reservacion> get filteredReservations {
    final search = _searchTerm.toLowerCase();
    return _reservations.where((res) {
      final matchesSearch =
          search.isEmpty || res.cliente.toLowerCase().contains(search);
      return matchesSearch;
    }).toList();
  }

  List<Reservacion> get paginatedReservations {
    final filtered = filteredReservations;
    final start = (_currentPage - 1) * pageSize;
    if (start >= filtered.length) return [];
    return filtered.skip(start).take(pageSize).toList();
  }

  int get totalPages =>
      (filteredReservations.length / pageSize).ceil().clamp(1, 999999);

  // Las métricas usan la lista estricta de hoy para que no se borren si cambias de fecha en el calendario
  int get totalToday => _todayReservations.length;
  int get confirmedToday => _todayReservations
      .where((r) => r.estado.toLowerCase() == 'confirmada')
      .length;
  int get guestsTodayCount => _todayReservations
      .where((r) => r.estado.toLowerCase() == 'confirmada')
      .fold(0, (sum, r) => sum + r.personas);

  // ==== MÉTODOS DE BASE DE DATOS (SUPABASE) ====

  Future<void> _cargarDatos() async {
    // 1. Cargamos las reservaciones de la fecha seleccionada en el calendario
    _reservations = await _repository.getReservacionesPorFecha(_selectedDate);

    // 2. Cargamos/Actualizamos las estadísticas exactas del día de hoy
    if (_selectedDate == todayIso) {
      _todayReservations = _reservations;
    } else {
      _todayReservations = await _repository.getReservacionesPorFecha(todayIso);
    }

    notifyListeners();
  }

  // ==== INTERFAZ Y MODALES ====

  void setSearchTerm(String val) {
    _searchTerm = val;
    _currentPage = 1;
    notifyListeners();
  }

  void setSelectedDate(String val) {
    _selectedDate = val;
    _currentPage = 1;
    _cargarDatos(); // Recargamos Supabase al cambiar de fecha
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void updateFormField(String key, dynamic value) {
    _formValues[key] = value;
    notifyListeners();
  }

  void _resetForm() {
    _formValues = {
      'cliente': '',
      'telefono': '',
      'personas': 2,
      'fecha': _selectedDate,
      'hora': '19:00',
      'mesa': 'General'
    };
  }

  void abrirModal() {
    _editingId = null;
    _modalError = '';
    _resetForm();
    _showModal = true;
    notifyListeners();
  }

  void abrirEditarModal(Reservacion res) {
    _editingId = res.id;
    _modalError = '';
    _formValues = {
      'cliente': res.cliente,
      'telefono': res.telefono,
      'personas': res.personas,
      'fecha': res.fecha,
      'hora': res.hora,
      'mesa': res.mesa
    };
    _showModal = true;
    notifyListeners();
  }

  void cerrarModal() {
    _showModal = false;
    _editingId = null;
    _modalError = '';
    notifyListeners();
  }

  // ==== ACCIONES C.R.U.D ====

  Future<bool> guardarReservacion() async {
    final cliente = (_formValues['cliente'] as String).trim();
    final telefono = (_formValues['telefono'] as String).trim();
    final personas = _formValues['personas'] as int;

    if (cliente.isEmpty || telefono.isEmpty || personas <= 0) {
      _modalError = 'Completa el cliente, teléfono y número de personas.';
      notifyListeners();
      return false;
    }

    try {
      if (_editingId != null) {
        // Encontrar la reservación original para mantener su estado
        final estadoActual =
            _reservations.firstWhere((r) => r.id == _editingId).estado;

        final resActualizada = Reservacion(
          id: _editingId!,
          cliente: cliente,
          telefono: telefono,
          personas: personas,
          fecha: _formValues['fecha'],
          hora: _formValues['hora'],
          estado: estadoActual,
          mesa: _formValues['mesa'],
        );
        await _repository.actualizarReservacion(_editingId!, resActualizada);
      } else {
        final nuevaRes = Reservacion(
          id: '', // Supabase generará el UUID
          cliente: cliente,
          telefono: telefono,
          personas: personas,
          fecha: _formValues['fecha'],
          hora: _formValues['hora'],
          estado: 'confirmada',
          mesa: _formValues['mesa'],
        );
        await _repository.crearReservacion(nuevaRes);
      }

      cerrarModal();
      await _cargarDatos(); // Refrescamos la lista
      return true;
    } catch (e) {
      _modalError = 'Error al guardar la reservación: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelarReservacion(String id) async {
    await _repository.cambiarEstado(id, 'cancelada');
    await _cargarDatos();
  }

  Future<void> eliminarReservacion(String id) async {
    await _repository.eliminarReservacion(id);
    await _cargarDatos();
  }
}

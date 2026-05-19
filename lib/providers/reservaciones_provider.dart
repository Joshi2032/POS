import 'package:flutter/material.dart';
import '../models/reservacion.dart';

class ReservacionesProvider extends ChangeNotifier {
  final int pageSize = 10;
  final String todayIso = DateTime.now().toIso8601String().substring(0, 10);

  // Semilla alineada al 100% con los campos exactos de tu modelo
  final List<Reservacion> _reservations = [
    Reservacion(
      id: 'RES-001',
      cliente: 'Juan García',
      telefono: '555-1001',
      personas: 4,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      hora: '19:00',
      mesa: 'Mesa 4',
      estado: 'confirmada',
    ),
    Reservacion(
      id: 'RES-002',
      cliente: 'María López',
      telefono: '555-1002',
      personas: 2,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      hora: '20:00',
      mesa: 'Mesa 2',
      estado: 'confirmada',
    ),
    Reservacion(
      id: 'RES-003',
      cliente: 'Carlos Rodríguez',
      telefono: '555-1003',
      personas: 6,
      fecha: DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10),
      hora: '19:30',
      mesa: 'Mesa 10',
      estado: 'confirmada',
    ),
    Reservacion(
      id: 'RES-004',
      cliente: 'Ana Martínez',
      telefono: '555-1004',
      personas: 3,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      hora: '18:00',
      mesa: 'Mesa 1',
      estado: 'completada',
    ),
    Reservacion(
      id: 'RES-005',
      cliente: 'Pedro Sánchez',
      telefono: '555-1005',
      personas: 5,
      fecha: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      hora: '20:00',
      mesa: 'Mesa 5',
      estado: 'cancelada',
    )
  ];

  String _searchTerm = '';
  int _currentPage = 1;
  late String _selectedDate;
  String? _editingId;
  bool _showModal = false;
  String _modalError = '';

  Map<String, dynamic> _formValues = {};

  ReservacionesProvider() {
    _selectedDate = todayIso;
    _resetForm();
  }

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
      final matchesDate = res.fecha == _selectedDate;
      final matchesSearch = search.isEmpty || res.cliente.toLowerCase().contains(search);
      return matchesDate && matchesSearch;
    }).toList();
  }

  List<Reservacion> get paginatedReservations {
    final filtered = filteredReservations;
    final start = (_currentPage - 1) * pageSize;
    if (start >= filtered.length) return [];
    return filtered.skip(start).take(pageSize).toList();
  }

  int get totalPages => (filteredReservations.length / pageSize).ceil().clamp(1, 999999);
  int get totalToday => _reservations.where((r) => r.fecha == todayIso).length;
  int get confirmedToday => _reservations.where((r) => r.fecha == todayIso && r.estado == 'confirmada').length;
  int get guestsTodayCount => _reservations
      .where((r) => r.fecha == todayIso && r.estado == 'confirmada')
      .fold(0, (sum, r) => sum + r.personas);

  void setSearchTerm(String val) {
    _searchTerm = val;
    _currentPage = 1;
    notifyListeners();
  }

  void setSelectedDate(String val) {
    _selectedDate = val;
    _currentPage = 1;
    notifyListeners();
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
      'fecha': todayIso,
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

  bool guardarReservacion() {
    final cliente = (_formValues['cliente'] as String).trim();
    final telefono = (_formValues['telefono'] as String).trim();
    final personas = _formValues['personas'] as int;

    if (cliente.isEmpty || telefono.isEmpty || personas <= 0) {
      _modalError = 'Completa el cliente, teléfono y número de personas.';
      notifyListeners();
      return false;
    }

    if (_editingId != null) {
      final index = _reservations.indexWhere((r) => r.id == _editingId);
      if (index != -1) {
        _reservations[index] = Reservacion(
          id: _editingId!,
          cliente: cliente,
          telefono: telefono,
          personas: personas,
          fecha: _formValues['fecha'],
          hora: _formValues['hora'],
          estado: _reservations[index].estado,
          mesa: _formValues['mesa'],
        );
      }
    } else {
      _reservations.insert(
        0,
        Reservacion(
          id: 'RES-${(_reservations.length + 1).toString().padLeft(3, '0')}',
          cliente: cliente,
          telefono: telefono,
          personas: personas,
          fecha: _formValues['fecha'],
          hora: _formValues['hora'],
          estado: 'confirmada',
          mesa: _formValues['mesa'],
        ),
      );
    }

    cerrarModal();
    notifyListeners();
    return true;
  }

  void cancelarReservacion(String id) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index] = Reservacion(
        id: _reservations[index].id,
        cliente: _reservations[index].cliente,
        telefono: _reservations[index].telefono,
        personas: _reservations[index].personas,
        fecha: _reservations[index].fecha,
        hora: _reservations[index].hora,
        estado: 'cancelada',
        mesa: _reservations[index].mesa,
      );
      notifyListeners();
    }
  }

  void eliminarReservacion(String id) {
    _reservations.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
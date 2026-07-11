import 'package:flutter/material.dart';
import '../models/reservacion.dart';
import '../repositories/reservacion_repository.dart';
import '../utils/mexico_time.dart';

class ReservacionesProvider extends ChangeNotifier {
  final ReservacionRepository _repository;

  final int pageSize = 10;

  // Se calcula fresco en cada acceso (no como un `final` fijado una sola vez
  // al arrancar) para que "hoy" no se quede obsoleto si la app se queda
  // abierta después de medianoche.
  String get todayIso => fechaHoyMexicoStr();

  // Listas de datos desde Supabase
  List<Reservacion> _reservations = [];
  List<Reservacion> _todayReservations = []; 

  String _searchTerm = '';
  int _currentPage = 1;
  late String _selectedDate;
  String? _editingId;
  bool _showModal = false;
  String _modalError = '';

  Map<String, dynamic> _formValues = {};

  // --- NUEVOS ESTADOS DE CONTROL DE RED Y ERRORES ---
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor inyectado
  ReservacionesProvider(this._repository) {
    _selectedDate = todayIso;
    _resetForm();
    cargarReservaciones(); // Reemplazamos la llamada directa por la pública segura
  }

  // ==== GETTERS COMPATIBLES AL 100% CON TU DISEÑO ORIGINAL ====
  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  String get selectedDate => _selectedDate;
  String? get editingId => _editingId;
  bool get showModal => _showModal;
  String get modalError => _modalError;
  Map<String, dynamic> get formValues => _formValues;

  // Getters para consultar los nuevos estados en la UI si lo necesitas
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

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

  int get totalToday => _todayReservations.length;
  
  int get confirmedToday => _todayReservations
      .where((r) => r.estado.toLowerCase() == 'confirmada')
      .length;
      
  int get guestsTodayCount => _todayReservations
      .where((r) => r.estado.toLowerCase() == 'confirmada')
      .fold(0, (sum, r) => sum + r.personas);

  // ==== MÉTODOS DE BASE DE DATOS (SUPABASE CON ROBUSTEZ DE ERRORES) ====

  Future<void> cargarReservaciones() async {
    _setLoading(true);
    _clearError();
    try {
      // 1. Cargamos las reservaciones de la fecha seleccionada en el calendario
      _reservations = await _repository.getReservacionesPorFecha(_selectedDate);

      // 2. Cargamos/Actualizamos las estadísticas exactas del día de hoy
      if (_selectedDate == todayIso) {
        _todayReservations = _reservations;
      } else {
        _todayReservations = await _repository.getReservacionesPorFecha(todayIso);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
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
    cargarReservaciones(); // Recargamos Supabase de forma segura al cambiar de fecha
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

  // ==== ACCIONES C.R.U.D CON CAPTURA INTEGRAL ====

  Future<bool> guardarReservacion() async {
    final cliente = (_formValues['cliente'] as String).trim();
    final telefono = (_formValues['telefono'] as String).trim();
    final personas = _formValues['personas'] as int;

    if (cliente.isEmpty || telefono.isEmpty || personas <= 0) {
      _modalError = 'Completa el cliente, teléfono y número de personas.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _modalError = '';
    try {
      if (_editingId != null) {
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
          id: '', 
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
      await cargarReservaciones(); // Refrescamos la lista de forma segura
      return true;
    } catch (e) {
      _modalError = 'Error al guardar la reservación: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelarReservacion(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.cambiarEstado(id, 'cancelada');
      await cargarReservaciones();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarReservacion(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.eliminarReservacion(id);
      await cargarReservaciones();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
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
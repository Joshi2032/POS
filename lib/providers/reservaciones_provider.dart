import 'package:flutter/material.dart';

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================
class Reservacion {
  final String id;
  final String customerName;
  final String date;
  final String time;
  final int guests;
  final String table;
  final String status; // 'Pendiente', 'Confirmada', 'Completada', 'Cancelada'
  final String notes;

  Reservacion({
    required this.id,
    required this.customerName,
    required this.date,
    required this.time,
    required this.guests,
    required this.table,
    required this.status,
    required this.notes,
  });

  Reservacion copyWith({
    String? customerName,
    String? date,
    String? time,
    int? guests,
    String? table,
    String? status,
    String? notes,
  }) {
    return Reservacion(
      id: id,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      time: time ?? this.time,
      guests: guests ?? this.guests,
      table: table ?? this.table,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class ReservacionForm {
  String customerName;
  String date;
  String time;
  int guests;
  String table;
  String status;
  String notes;

  ReservacionForm({
    required this.customerName,
    required this.date,
    required this.time,
    required this.guests,
    required this.table,
    required this.status,
    required this.notes,
  });
}

// ==========================================
// 2. GESTOR DE ESTADO (CEREBRO DEL MÓDULO)
// ==========================================
class ReservacionesProvider extends ChangeNotifier {
  final int pageSize = 10;

  // Variables de estado
  List<Reservacion> _reservaciones = [];
  String _searchTerm = '';
  String _selectedStatus = 'Todos';
  int _currentPage = 1;

  // Getters para la UI
  String get searchTerm => _searchTerm;
  String get selectedStatus => _selectedStatus;
  int get currentPage => _currentPage;
  int get totalReservacionesLength => _reservaciones.length;

  ReservacionesProvider() {
    _initData();
  }

  void _initData() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _reservaciones = [
      Reservacion(
          id: 'RES-001',
          customerName: 'Familia Martínez',
          date: todayStr,
          time: '14:30',
          guests: 6,
          table: 'Mesa 4',
          status: 'Confirmada',
          notes: 'Silla para bebé'),
      Reservacion(
          id: 'RES-002',
          customerName: 'Carlos Slim',
          date: todayStr,
          time: '20:00',
          guests: 2,
          table: 'Mesa Vip 1',
          status: 'Pendiente',
          notes: 'Aniversario'),
      Reservacion(
          id: 'RES-003',
          customerName: 'Empresa XYZ',
          date: todayStr,
          time: '15:00',
          guests: 12,
          table: 'Terraza 1, 2 y 3',
          status: 'Confirmada',
          notes: 'Facturar al final'),
      Reservacion(
          id: 'RES-004',
          customerName: 'Andrea López',
          date: todayStr,
          time: '19:00',
          guests: 4,
          table: 'Mesa 7',
          status: 'Cancelada',
          notes: ''),
    ];
  }

  // --- LÓGICA COMPUTADA (Filtros y paginación) ---
  List<Reservacion> get filteredReservaciones {
    final query = _searchTerm.trim().toLowerCase();
    final status = _selectedStatus;

    return _reservaciones.where((r) {
      final matchesSearch = query.isEmpty ||
          r.customerName.toLowerCase().contains(query) ||
          r.id.toLowerCase().contains(query) ||
          r.table.toLowerCase().contains(query);

      final matchesStatus = status == 'Todos' || r.status == status;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<Reservacion> get paginatedReservaciones {
    final list = filteredReservaciones;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    final end =
        (start + pageSize) > list.length ? list.length : (start + pageSize);
    return list.sublist(start, end);
  }

  int get totalPages => (filteredReservaciones.length / pageSize).ceil();

  int get pendientesCount =>
      _reservaciones.where((r) => r.status == 'Pendiente').length;
  int get confirmadasCount =>
      _reservaciones.where((r) => r.status == 'Confirmada').length;
  int get paraHoyCount {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _reservaciones
        .where((r) => r.date == todayStr && r.status != 'Cancelada')
        .length;
  }

  // --- ACCIONES MUTADORAS ---
  void onSearch(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void changePage(int newPage) {
    _currentPage = newPage;
    notifyListeners();
  }

  void crearReservacion(ReservacionForm formState) {
    final next = _reservaciones.length + 1;
    final nueva = Reservacion(
      id: 'RES-${next.toString().padLeft(3, '0')}',
      customerName: formState.customerName,
      date: formState.date,
      time: formState.time,
      guests: formState.guests,
      table: formState.table,
      status: formState.status,
      notes: formState.notes,
    );
    _reservaciones.insert(0, nueva);
    notifyListeners();
  }

  void actualizarReservacion(String id, ReservacionForm formState) {
    final idx = _reservaciones.indexWhere((x) => x.id == id);
    if (idx != -1) {
      _reservaciones[idx] = _reservaciones[idx].copyWith(
        customerName: formState.customerName,
        date: formState.date,
        time: formState.time,
        guests: formState.guests,
        table: formState.table,
        status: formState.status,
        notes: formState.notes,
      );
      notifyListeners();
    }
  }

  void cambiarEstado(String id, String nuevoEstado) {
    final idx = _reservaciones.indexWhere((x) => x.id == id);
    if (idx != -1) {
      _reservaciones[idx] = _reservaciones[idx].copyWith(status: nuevoEstado);
      notifyListeners();
    }
  }

  void eliminarReservacion(String id) {
    _reservaciones.removeWhere((x) => x.id == id);
    notifyListeners();
  }
}

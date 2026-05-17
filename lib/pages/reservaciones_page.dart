import 'package:flutter/material.dart';

// ==========================================
// MODELOS DE DATOS (Mapeo de reservaciones.models.ts)
// ==========================================
typedef ReservationStatus = String; // 'confirmada' | 'cancelada' | 'completada'

class Reservation {
  final String id;
  final String clientName;
  final String email;
  final String phone;
  final int partySize;
  final String date;
  final String time;
  final String? specialRequests;
  final ReservationStatus status;
  final String createdAt;
  final String? notes;

  Reservation({
    required this.id,
    required this.clientName,
    required this.email,
    required this.phone,
    required this.partySize,
    required this.date,
    required this.time,
    this.specialRequests,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  Reservation copyWith({
    String? clientName,
    String? email,
    String? phone,
    int? partySize,
    String? date,
    String? time,
    String? specialRequests,
    ReservationStatus? status,
    String? notes,
  }) {
    return Reservation(
      id: id, // Solucionado: Removido 'this.' innecesario
      clientName: clientName ?? this.clientName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      partySize: partySize ?? this.partySize,
      date: date ?? this.date,
      time: time ?? this.time,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      createdAt: createdAt, // Solucionado: Removido 'this.' innecesario
      notes: notes ?? this.notes,
    );
  }
}

class ReservationForm {
  String clientName;
  String email;
  String phone;
  int partySize;
  String date;
  String time;
  String specialRequests;
  String notes;

  ReservationForm({
    required this.clientName,
    required this.email,
    required this.phone,
    required this.partySize,
    required this.date,
    required this.time,
    required this.specialRequests,
    required this.notes,
  });
}

// ==========================================
// COMPONENTE PRINCIPAL
// ==========================================
class ReservacionesPage extends StatefulWidget {
  const ReservacionesPage({super.key});

  @override
  State<ReservacionesPage> createState() => _ReservacionesPageState();
}

class _ReservacionesPageState extends State<ReservacionesPage> {
  late final String todayIso;
  final int pageSize = 10;

  String searchTerm = '';
  int currentPage = 1;
  late String selectedDate;
  String? editingId;
  bool showModal = false;
  String modalError = '';

  List<Reservation> reservations = [];
  late ReservationForm newReservation;
  
  // Llave global asignada correctamente para la validación del formulario
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    todayIso = DateTime.now().toIso8601String().slice(0, 10);
    selectedDate = todayIso;
    
    reservations = [
      Reservation(id: 'RES-001', clientName: 'Juan García', email: 'juan@ejemplo.com', phone: '555-1001', partySize: 4, date: todayIso, time: '19:00', specialRequests: 'Mesa cerca de la ventana', status: 'confirmada', createdAt: todayIso, notes: 'Cumpleaños'),
      Reservation(id: 'RES-002', clientName: 'María López', email: 'maria@ejemplo.com', phone: '555-1002', partySize: 2, date: todayIso, time: '20:00', specialRequests: '', status: 'confirmada', createdAt: todayIso),
      Reservation(id: 'RES-003', clientName: 'Carlos Rodríguez', email: 'carlos@ejemplo.com', phone: '555-1003', partySize: 6, date: DateTime.now().add(const Duration(days: 1)).toIso8601String().slice(0, 10), time: '19:30', specialRequests: 'Sin mariscos (alergia)', status: 'confirmada', createdAt: todayIso),
      Reservation(id: 'RES-004', clientName: 'Ana Martínez', email: 'ana@ejemplo.com', phone: '555-1004', partySize: 3, date: todayIso, time: '18:00', specialRequests: 'Mesa alta', status: 'completada', createdAt: todayIso),
      Reservation(id: 'RES-005', clientName: 'Pedro Sánchez', email: 'pedro@ejemplo.com', phone: '555-1005', partySize: 5, date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().slice(0, 10), time: '20:00', specialRequests: '', status: 'cancelada', createdAt: todayIso, notes: 'Cancelada por el cliente'),
    ];

    _resetForm();
  }

  void _resetForm() {
    newReservation = ReservationForm(
      clientName: '',
      email: '',
      phone: '',
      partySize: 2,
      date: todayIso,
      time: '19:00',
      specialRequests: '',
      notes: '',
    );
  }

  // LÓGICA COMPUTADA
  List<Reservation> get filteredReservations {
    final search = searchTerm.toLowerCase();
    return reservations.where((res) {
      return res.date == selectedDate &&
          (search.isEmpty || res.clientName.toLowerCase().contains(search));
    }).toList();
  }

  List<Reservation> get paginatedReservations {
    final filtered = filteredReservations;
    final start = (currentPage - 1) * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    return filtered.sublist(start, end);
  }

  int get totalPages => (filteredReservations.length / pageSize).ceil();
  int get totalToday => reservations.where((r) => r.date == todayIso).length;
  int get confirmedToday => reservations.where((r) => r.date == todayIso && r.status == 'confirmada').length;
  int get guestsTodayCount => reservations
      .where((r) => r.date == todayIso && r.status == 'confirmada')
      .fold(0, (sum, r) => sum + r.partySize);

  // CONTROLADORES REACTIVOS
  void onSearchChange(String value) {
    setState(() {
      searchTerm = value;
      currentPage = 1;
    });
  }

  void onDateChange(String date) {
    setState(() {
      selectedDate = date;
      currentPage = 1;
    });
  }

  void abrirModal() {
    setState(() {
      editingId = null;
      modalError = '';
      _resetForm();
      showModal = true;
    });
  }

  void abrirEditarModal(Reservation reservation) {
    setState(() {
      editingId = reservation.id;
      modalError = '';
      newReservation = ReservationForm(
        clientName: reservation.clientName,
        email: reservation.email,
        phone: reservation.phone,
        partySize: reservation.partySize,
        date: reservation.date,
        time: reservation.time,
        specialRequests: reservation.specialRequests ?? '',
        notes: reservation.notes ?? '',
      );
      showModal = true;
    });
  }

  void cerrarModal() {
    setState(() {
      showModal = false;
      modalError = '';
      editingId = null;
    });
  }

  void guardarReservacion() {
    // Implementación del uso de _formKey para validación estructural
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final clientName = newReservation.clientName.trim();
    final email = newReservation.email.trim();
    final phone = newReservation.phone.trim();

    if (clientName.isEmpty || email.isEmpty || phone.isEmpty || newReservation.partySize <= 0) {
      setState(() {
        modalError = 'Completa nombre, email, teléfono y número de personas.';
      });
      return;
    }

    if (editingId != null) {
      _showConfirmDialog(
        'Actualizar Reservación',
        '¿Actualizar reservación de $clientName?',
        () => actualizarReservacion(clientName, email, phone, newReservation),
      );
    } else {
      _showConfirmDialog(
        'Nueva Reservación',
        '¿Confirmar reservación para $clientName (${newReservation.partySize} personas) el ${newReservation.date} a las ${newReservation.time}?',
        () => crearReservacion(clientName, email, phone, newReservation),
      );
    }
  }

  void crearReservacion(String clientName, String email, String phone, ReservationForm form) {
    setState(() {
      final nextIndex = reservations.length + 1;
      final idString = nextIndex.toString().padLeft(3, '0');

      final newRes = Reservation(
        id: 'RES-$idString',
        clientName: clientName,
        email: email,
        phone: phone,
        partySize: form.partySize,
        date: form.date,
        time: form.time,
        specialRequests: form.specialRequests,
        status: 'confirmada',
        createdAt: todayIso,
        notes: form.notes,
      );
      reservations.insert(0, newRes);
      _showToast('Reservación de $clientName creada exitosamente', Colors.green);
      cerrarModal();
    });
  }

  void actualizarReservacion(String clientName, String email, String phone, ReservationForm form) {
    if (editingId == null) return;
    setState(() {
      final index = reservations.findIndex((r) => r.id == editingId);
      if (index != -1) {
        reservations[index] = reservations[index].copyWith(
          clientName: clientName,
          email: email,
          phone: phone,
          partySize: form.partySize,
          date: form.date,
          time: form.time,
          specialRequests: form.specialRequests,
          notes: form.notes,
        );
        _showToast('Reservación actualizada', Colors.green);
        cerrarModal();
      }
    });
  }

  void cancelarReservacion(String id) {
    final reservation = reservations.firstWhere((r) => r.id == id);
    _showConfirmDialog(
      'Cancelar Reservación',
      '¿Cancelar reservación de ${reservation.clientName}? Esta acción no se puede deshacer.',
      () {
        setState(() {
          final index = reservations.findIndex((r) => r.id == id);
          if (index != -1) {
            reservations[index] = reservations[index].copyWith(
              status: 'cancelada',
              notes: 'Cancelada por staff',
            );
            _showToast('Reservación $id cancelada', Colors.orange);
          }
        });
      },
    );
  }

  void eliminarReservacion(String id) {
    final reservation = reservations.firstWhere((r) => r.id == id);
    _showConfirmDialog(
      'Eliminar Reservación',
      '¿Eliminar reservación de ${reservation.clientName}? Esta acción no se puede deshacer.',
      () {
        setState(() {
          reservations.removeWhere((r) => r.id == id);
          _showToast('$id eliminado', Colors.red);
        });
      },
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _showConfirmDialog(String title, String body, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    if (status == 'confirmada') return Colors.green;
    if (status == 'cancelada') return Colors.red;
    return Colors.blue;
  }

  String _getStatusLabel(ReservationStatus status) {
    if (status == 'confirmada') return 'Confirmada';
    if (status == 'cancelada') return 'Cancelada';
    return 'Completada';
  }

  // ==========================================
  // DISPOSITION DE INTERFAZ
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📅 ', style: TextStyle(fontSize: 26)),
                              Text('Reservaciones', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text('Gestiona reservaciones de mesas', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(selectedDate),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.parse(selectedDate),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                onDateChange(picked.toIso8601String().slice(0, 10));
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                            onPressed: abrirModal,
                            child: const Text('+ Nueva Reservación'),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  GridView.count(
                    crossAxisCount: isDesktop ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.5 : 3.5,
                    children: [
                      _buildStatCard('Reservaciones Hoy', '$totalToday', 'confirmadas: $confirmedToday', Colors.blueGrey.shade800),
                      _buildStatCard('Personas Hoy', '$guestsTodayCount', 'personas confirmadas', Colors.orange.shade800),
                      _buildStatCard('Fecha Seleccionada', selectedDate, '${filteredReservations.length} reservaciones', Colors.blueGrey.shade800),
                    ],
                  ),
                  const SizedBox(height: 25),

                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre del cliente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: onSearchChange,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${filteredReservations.length} registro(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (filteredReservations.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(40),
                      child: const Column(
                        children: [
                          Text('📭', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 10),
                          Text('No hay reservaciones para esta fecha', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paginatedReservations.length,
                    itemBuilder: (context, idx) {
                      final reservation = paginatedReservations[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(reservation.id, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(reservation.clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 10),
                                        Chip(
                                          label: Text(_getStatusLabel(reservation.status), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          backgroundColor: _getStatusColor(reservation.status),
                                          padding: EdgeInsets.zero,
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 15,
                                      children: [
                                        Text('👤 ${reservation.partySize} persona(s)', style: const TextStyle(color: Colors.blueGrey)),
                                        Text('🕒 ${reservation.time}', style: const TextStyle(color: Colors.blueGrey)),
                                        Text('📞 ${reservation.phone}', style: const TextStyle(color: Colors.blueGrey)),
                                      ],
                                    ),
                                    if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text.rich(TextSpan(children: [
                                        const TextSpan(text: 'Notas: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: reservation.specialRequests)
                                      ]))
                                    ]
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: reservation.status == 'completada' ? null : () => abrirEditarModal(reservation),
                                    child: const Text('✎ Editar'),
                                  ),
                                  TextButton(
                                    onPressed: reservation.status != 'confirmada' ? null : () => cancelarReservacion(reservation.id),
                                    child: const Text('🚫 Cancelar', style: TextStyle(color: Colors.orange)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => eliminarReservacion(reservation.id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: currentPage == 1 ? null : () => goToPage(currentPage - 1),
                        ),
                        Text('Página $currentPage de $totalPages', style: const TextStyle(fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: currentPage == totalPages ? null : () => goToPage(currentPage + 1),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (showModal) ...[
            GestureDetector(
              onTap: cerrarModal,
              child: Container(color: Colors.black45),
            ),
            Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey, // Enlazado correctamente aquí
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(editingId != null ? 'Editar Reservación' : 'Nueva Reservación', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.close), onPressed: cerrarModal),
                            ],
                          ),
                          if (modalError.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(modalError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                          const SizedBox(height: 15),
                          _buildModalFormFields(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              onPressed: guardarReservacion,
                              child: Text(editingId != null ? 'Actualizar Reservación' : 'Guardar Reservación'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtext, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtext, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildModalFormFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: newReservation.clientName,
          decoration: const InputDecoration(labelText: 'Nombre del Cliente', hintText: 'Juan García', border: OutlineInputBorder()),
          validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
          onChanged: (val) => newReservation.clientName = val,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: newReservation.email,
          decoration: const InputDecoration(labelText: 'Email', hintText: 'juan@ejemplo.com', border: OutlineInputBorder()),
          validator: (val) => val == null || val.trim().isEmpty ? 'El email es obligatorio' : null,
          onChanged: (val) => newReservation.email = val,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: newReservation.phone,
          decoration: const InputDecoration(labelText: 'Teléfono', hintText: '555-1234', border: OutlineInputBorder()),
          validator: (val) => val == null || val.trim().isEmpty ? 'El teléfono es obligatorio' : null,
          onChanged: (val) => newReservation.phone = val,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '${newReservation.partySize}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de Personas', border: OutlineInputBorder()),
                onChanged: (val) => newReservation.partySize = int.tryParse(val) ?? 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: newReservation.date,
                decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)', border: OutlineInputBorder()),
                onChanged: (val) => newReservation.date = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: newReservation.time,
          decoration: const InputDecoration(labelText: 'Hora (HH:MM)', border: OutlineInputBorder()),
          onChanged: (val) => newReservation.time = val,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: newReservation.specialRequests,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Solicitudes Especiales', border: OutlineInputBorder()),
          onChanged: (val) => newReservation.specialRequests = val,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: newReservation.notes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notas Internas', border: OutlineInputBorder()),
          onChanged: (val) => newReservation.notes = val,
        ),
      ],
    );
  }
}

extension StringSlice on String {
  String slice(int start, int end) => substring(start, end);
}

extension ListFindIndex<T> on List<T> {
  int findIndex(bool Function(T element) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }
}
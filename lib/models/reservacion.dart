// lib/models/reservacion.dart
class Reservacion {
  final String id;
  String cliente;
  String telefono;
  String fecha;
  String hora;
  int personas;
  String mesa;
  String estado;

  Reservacion({
    required this.id,
    required this.cliente,
    required this.telefono,
    required this.fecha,
    required this.hora,
    required this.personas,
    required this.mesa,
    this.estado = 'Pendiente',
  });

  // Mapeo: De Supabase (Inglés) a Flutter (Español)
  factory Reservacion.fromJson(Map<String, dynamic> json) {
    return Reservacion(
      id: json['id']?.toString() ?? '',
      cliente: json['client_name'] ?? '',
      telefono: json['phone'] ?? '',
      fecha: json['reservation_date'] ?? '',
      hora: json['reservation_time'] ?? '',
      personas: json['party_size'] ?? 1,
      mesa: json['table_id'] ?? 'General',
      estado: json['status'] ?? 'Pendiente',
    );
  }

  // Mapeo: De Flutter (Español) a Supabase (Inglés)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'client_name': cliente,
      'phone': telefono,
      'reservation_date': fecha,
      'reservation_time': hora,
      'party_size': personas,
      'status': estado,
      // Si la mesa dice "General", la guardamos como null en BD
      'table_id': mesa == 'General' ? null : mesa, 
    };

    // Si tiene un ID real de Supabase (UUID), lo mandamos. 
    // Ignoramos los "RES-00X" locales temporales.
    if (id.isNotEmpty && !id.startsWith('RES-')) {
      data['id'] = id;
    }

    return data;
  }
}
// lib/models/mesa.dart
class Mesa {
  final String id;
  String nombre;
  int capacidad;
  String area;
  String estado; // 'Libre' | 'Ocupada'

  Mesa({
    required this.id,
    required this.nombre,
    required this.capacidad,
    required this.area,
    this.estado = 'Libre',
  });

  // Mapeo: Supabase a Flutter
  factory Mesa.fromJson(Map<String, dynamic> json) {
    return Mesa(
      id: json['id']?.toString() ?? '',
      nombre: json['name'] ?? '',
      capacidad: json['capacity'] ?? 4,
      area: json['area'] ?? 'General',
      // Supabase suele guardar strings sin capitalizar, aseguramos la vista:
      estado: json['status'] == 'ocupada' ? 'Ocupada' : 'Libre',
    );
  }

  // Mapeo: Flutter a Supabase
  Map<String, dynamic> toJson() {
    final data = {
      'name': nombre,
      'capacity': capacidad,
      'area': area,
      'status': estado.toLowerCase(), // Guardamos en minúsculas en BD
    };
    
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }
}
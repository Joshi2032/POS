class Mesa {
  final String id;
  String nombre;
  int capacidad;
  String area;
  String estado; // UI: 'Libre' | 'Ocupada'

  Mesa({
    required this.id,
    required this.nombre,
    required this.capacidad,
    required this.area,
    this.estado = 'Libre',
  });

  factory Mesa.fromJson(Map<String, dynamic> json) {
    // Traducimos de BD (Inglés) a UI (Español)
    String statusDb = json['status']?.toString().toLowerCase() ?? 'free';
    String estadoUi = 'Libre';
    if (statusDb == 'occupied') estadoUi = 'Ocupada';

    return Mesa(
      id: json['id']?.toString() ?? '',
      nombre: json['name'] ?? '',
      capacidad: json['capacity'] ?? 4,
      area: json['area'] ?? 'General',
      estado: estadoUi,
    );
  }

  Map<String, dynamic> toJson() {
    // Traducimos de UI (Español) a BD (Inglés) para pasar el CHECK
    String statusDb = 'free';
    if (estado == 'Ocupada') statusDb = 'occupied';

    return {
      if (id.isNotEmpty) 'id': id,
      'name': nombre,
      'capacity': capacidad,
      'area': area,
      'status': statusDb, 
    };
  }
}
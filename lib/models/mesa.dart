class Mesa {
  final String id;
  String nombre;
  int capacidad;
  String area;
  String estado;

  Mesa({
    required this.id,
    required this.nombre,
    required this.capacidad,
    required this.area,
    this.estado = 'Libre',
  });

  factory Mesa.fromJson(Map<String, dynamic> json) {
    final statusDb =
        json['status']?.toString().trim().toLowerCase() ?? 'free';

    String estadoUi = 'Libre';

    if (statusDb == 'occupied') {
      estadoUi = 'Ocupada';
    } else if (statusDb == 'pending_payment') {
      estadoUi = 'Por cobrar';
    }

    return Mesa(
      id: json['id']?.toString() ?? '',
      nombre: json['name']?.toString() ?? '',
      capacidad: int.tryParse(
            json['capacity']?.toString() ?? '',
          ) ??
          4,
      area: json['area']?.toString() ?? 'General',
      estado: estadoUi,
    );
  }

  Map<String, dynamic> toJson() {
    final estadoNormalizado =
        estado.trim().toLowerCase();

    String statusDb = 'free';

    if (estadoNormalizado == 'ocupada') {
      statusDb = 'occupied';
    } else if (estadoNormalizado == 'por cobrar' ||
        estadoNormalizado == 'cuenta') {
      statusDb = 'pending_payment';
    }

    return {
      if (id.isNotEmpty) 'id': id,
      'name': nombre,
      'capacity': capacidad,
      'area': area,
      'status': statusDb,
    };
  }
}
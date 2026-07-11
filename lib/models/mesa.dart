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

    // Antes usaba int.tryParse() directo sobre el texto: si 'capacity'
    // llegaba como número decimal (ej. "4.0", si la columna fuera numeric
    // en vez de int), int.tryParse() devolvía null y caía silenciosamente
    // al valor por defecto de 4, ocultando la capacidad real de la mesa.
    final capacityRaw = json['capacity'];
    final int capacidadParseada = capacityRaw is num
        ? capacityRaw.round()
        : double.tryParse(capacityRaw?.toString() ?? '')?.round() ?? 4;

    return Mesa(
      id: json['id']?.toString() ?? '',
      nombre: json['name']?.toString() ?? '',
      capacidad: capacidadParseada,
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
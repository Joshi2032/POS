class MovimientoCaja {
  final String id;
  final String concepto; // BD: concept
  final String tipo;     // BD: type (Ingreso/Egreso)
  final double monto;    // BD: amount
  final String fecha;    // BD: date

  MovimientoCaja({
    required this.id,
    required this.concepto,
    required this.tipo,
    required this.monto,
    required this.fecha,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    // Si la fecha viene de Supabase con hora (ej. 2026-05-29T12:00:00), la cortamos a solo YYYY-MM-DD
    String rawDate = json['date']?.toString() ?? json['created_at']?.toString() ?? '';
    if (rawDate.contains('T')) rawDate = rawDate.split('T').first;

    return MovimientoCaja(
      id: json['id']?.toString() ?? '',
      concepto: json['concept'] ?? 'Movimiento',
      tipo: json['type'] ?? 'Egreso',
      monto: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fecha: rawDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'concept': concepto,
      'type': tipo,
      'amount': monto,
      'date': fecha.isNotEmpty ? fecha : DateTime.now().toIso8601String().split('T').first,
    };
  }

  MovimientoCaja copyWith({
    String? id,
    String? concepto,
    String? tipo,
    double? monto,
    String? fecha,
  }) {
    return MovimientoCaja(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
    );
  }
}
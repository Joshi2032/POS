class MovimientoCaja {
  final String id;
  String concepto;
  String tipo; // Ingreso | Egreso
  double monto;
  String fecha;

  MovimientoCaja({
    required this.id,
    required this.concepto,
    required this.tipo,
    required this.monto,
    required this.fecha,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    return MovimientoCaja(
      id: json['id'] as String,
      concepto: json['concept'] as String,
      tipo: json['type'] as String,
      monto: (json['amount'] as num).toDouble(),
      fecha: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concept': concepto,
      'type': tipo,
      'amount': monto,
      'date': fecha,
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

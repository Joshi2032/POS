class NominaPago {
  final String id;
  String fecha;
  String empleado;
  String tipo;
  String periodo;
  double monto;
  String metodo;
  String notas;

  NominaPago({
    required this.id,
    required this.fecha,
    required this.empleado,
    required this.tipo,
    required this.periodo,
    required this.monto,
    required this.metodo,
    required this.notas,
  });

  factory NominaPago.fromJson(Map<String, dynamic> json) {
    return NominaPago(
      id: json['id'] as String,
      fecha: json['date'] as String,
      empleado: json['employee_id'] as String,
      tipo: json['type'] as String,
      periodo: json['period'] as String,
      monto: (json['amount'] as num).toDouble(),
      metodo: json['payment_method'] as String,
      notas: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': fecha,
      'employee_id': empleado,
      'type': tipo,
      'period': periodo,
      'amount': monto,
      'payment_method': metodo,
      'notes': notas,
    };
  }

  NominaPago copyWith({
    String? id,
    String? fecha,
    String? empleado,
    String? tipo,
    String? periodo,
    double? monto,
    String? metodo,
    String? notas,
  }) {
    return NominaPago(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      empleado: empleado ?? this.empleado,
      tipo: tipo ?? this.tipo,
      periodo: periodo ?? this.periodo,
      monto: monto ?? this.monto,
      metodo: metodo ?? this.metodo,
      notas: notas ?? this.notas,
    );
  }
}

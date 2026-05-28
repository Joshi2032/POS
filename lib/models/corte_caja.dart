class CorteCaja {
  final String id;
  String fecha;
  String hora;
  String cajero;
  String metodo; // Efectivo | Tarjeta | Mixto
  double monto;

  CorteCaja({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.cajero,
    required this.metodo,
    required this.monto,
  });

  factory CorteCaja.fromJson(Map<String, dynamic> json) {
    return CorteCaja(
      id: json['id'] as String,
      fecha: json['date'] as String,
      hora: json['time'] as String,
      cajero: json['cashier'] as String,
      metodo: json['method'] as String,
      monto: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': fecha,
      'time': hora,
      'cashier': cajero,
      'method': metodo,
      'amount': monto,
    };
  }

  CorteCaja copyWith({
    String? id,
    String? fecha,
    String? hora,
    String? cajero,
    String? metodo,
    double? monto,
  }) {
    return CorteCaja(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      cajero: cajero ?? this.cajero,
      metodo: metodo ?? this.metodo,
      monto: monto ?? this.monto,
    );
  }
}

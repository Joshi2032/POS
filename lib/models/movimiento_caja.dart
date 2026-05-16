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
}

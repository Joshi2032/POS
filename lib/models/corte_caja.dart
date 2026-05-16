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
}

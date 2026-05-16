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
}

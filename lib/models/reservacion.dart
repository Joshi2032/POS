class Reservacion {
  final String id;
  String cliente;
  String telefono;
  String fecha;
  String hora;
  int personas;
  String mesa;
  String estado;

  Reservacion({
    required this.id,
    required this.cliente,
    required this.telefono,
    required this.fecha,
    required this.hora,
    required this.personas,
    required this.mesa,
    this.estado = 'Pendiente',
  });
}

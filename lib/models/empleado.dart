class Empleado {
  final String id;
  String nombre;
  String correo;
  String rol;
  bool activo;

  Empleado(
      {required this.id,
      required this.nombre,
      required this.correo,
      required this.rol,
      this.activo = true});
}

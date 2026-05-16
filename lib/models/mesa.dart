class Mesa {
  final String id;
  String nombre;
  int capacidad;
  String area;
  String estado; // 'Libre' | 'Ocupada'

  Mesa(
      {required this.id,
      required this.nombre,
      required this.capacidad,
      required this.area,
      this.estado = 'Libre'});
}

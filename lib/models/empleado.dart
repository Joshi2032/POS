class Empleado {
  final String id;
  String nombre;
  String correo;
  String rol;
  bool activo;

  Empleado({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.activo = true,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as String,
      nombre: json['name'] as String,
      correo: json['email'] as String,
      rol: json['role'] as String,
      activo: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nombre,
      'email': correo,
      'role': rol,
      'active': activo,
    };
  }

  Empleado copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? rol,
    bool? activo,
  }) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }
}

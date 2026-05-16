class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String unidad;

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.unidad,
  });

  Producto copyWith({
    String? nombre,
    String? categoria,
    double? precio,
    int? stock,
    String? unidad,
  }) {
    return Producto(
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      unidad: unidad ?? this.unidad,
    );
  }
}
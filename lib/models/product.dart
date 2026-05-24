class Producto {
  final String? id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String unidad;

  Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.unidad,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id']?.toString(),
      nombre: json['name'] ?? '',
      // Extraemos el nombre de la categoría si viene anidado en la respuesta de Supabase
      categoria: json['categories'] != null ? json['categories']['name'] : 'General',
      precio: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      unidad: json['unit'] ?? 'unidad',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nombre,
      'price': precio,
      'stock': stock,
      'unit': unidad,
    };
  }
}
// lib/models/producto.dart
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
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      unidad: json['unidad'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'unidad': unidad,
    };
  }
}
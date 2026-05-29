class Producto {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String unit;

  Producto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.unit,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? json['nombre'] ?? 'Sin nombre',
      description: json['description'] ?? json['descripcion'] ?? '',
      category: json['categories'] != null ? json['categories']['name'] : (json['category'] ?? 'General'),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'unidad',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'unit': unit,
    };
  }
}
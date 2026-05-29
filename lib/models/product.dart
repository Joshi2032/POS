class Producto {
  final String id;
  final String name;
  final String description;
  final String category; // Nombre para mostrar en la UI
  final String? categoryId; // UUID real para la Base de Datos
  final double price;
  final int stock;
  final String unit;

  Producto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId,
    required this.price,
    required this.stock,
    required this.unit,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      // Extraemos el nombre de la categoría del JOIN de Supabase
      category: json['categories'] != null
          ? json['categories']['name']
          : 'General',
      categoryId: json['category_id']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'unidad',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'unit': unit,
      // OMITIMOS 'category' porque esa columna no existe en 'products'
      'category_id': categoryId, 
    };
  }
}
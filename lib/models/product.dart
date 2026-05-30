class Producto {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? categoryId;
  final double price;
  final int stock;
  final String unit;
  
  // --- NUEVO CAMPO ---
  final String? recipeId;

  Producto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId,
    required this.price,
    required this.stock,
    required this.unit,
    this.recipeId, // --- NUEVO ---
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      category: json['categories'] != null ? json['categories']['name'] : 'General',
      categoryId: json['category_id']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'unidad',
      recipeId: json['recipe_id']?.toString(), // --- NUEVO ---
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
      'category_id': categoryId,
      'recipe_id': recipeId, // --- NUEVO ---
    };
  }
}
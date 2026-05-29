class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock; // UI: stock -> BD: quantity
  final double cost; // UI: cost -> BD: cost_per_unit
  final String provider; // UI: provider -> BD: supplier
  final String unit; // BD: unit
  final double minStock; // BD: min_stock
  final bool active; // BD: active

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.cost,
    required this.provider,
    this.unit = 'kg', // Valor por defecto
    this.minStock = 0,
    this.active = true,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Sin nombre',
      category: json['category'] ?? 'General',
      // Mapeo estricto a las columnas de Supabase
      stock: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      provider: json['supplier'] ?? 'Sin proveedor',
      unit: json['unit'] ?? 'kg',
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      // Traducción a los nombres de columnas reales en la BD
      'quantity': stock,
      'cost_per_unit': cost,
      'supplier': provider,
      'unit': unit,
      'min_stock': minStock,
      'active': active,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? stock,
    double? cost,
    String? provider,
    String? unit,
    double? minStock,
    bool? active,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      cost: cost ?? this.cost,
      provider: provider ?? this.provider,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      active: active ?? this.active,
    );
  }
}
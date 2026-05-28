class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock;
  final double cost;
  final String provider;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.cost,
    required this.provider,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      stock: (json['stock'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      provider: json['provider'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'stock': stock,
      'cost': cost,
      'provider': provider,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? stock,
    double? cost,
    String? provider,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      cost: cost ?? this.cost,
      provider: provider ?? this.provider,
    );
  }
}

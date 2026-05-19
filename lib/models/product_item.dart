class ProductItem {
  final int id;
  final String name;
  final String description;
  final String category;
  final double price;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
    };
  }
}

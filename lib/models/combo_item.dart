class ComboItem {
  final String id;
  String title;     // UI: title -> BD: name
  String subtitle;  // UI: subtitle -> BD: description
  double price;     // BD: price
  bool active;      // BD: active

  ComboItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.active = true,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? 'Combo',
      subtitle: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      // Solo enviamos a Supabase las columnas que realmente existen
      'name': title,
      'description': subtitle,
      'price': price,
      'active': active,
    };
  }

  ComboItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? price,
    bool? active,
  }) {
    return ComboItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      active: active ?? this.active,
    );
  }
}
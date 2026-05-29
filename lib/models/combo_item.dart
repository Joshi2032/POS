class ComboItem {
  final String id;
  String title;     // UI: title -> BD: name
  String subtitle;  // UI: subtitle -> BD: description
  List<String> tags; // Solo para la UI (No se guarda en BD)
  double price;     // BD: price
  double oldPrice;  // Solo para la UI
  String ahorro;    // Solo para la UI
  bool active;      // BD: active

  ComboItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tags = const [],
    required this.price,
    this.oldPrice = 0.0,
    this.ahorro = '',
    this.active = true,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? 'Combo',
      subtitle: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
      // Los datos visuales que no están en la BD se inicializan por defecto
      tags: [], 
      oldPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      ahorro: '', 
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
      // OMITIMOS tags, old_price y discount para evitar que Supabase rechace la petición
    };
  }

  ComboItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? tags,
    double? price,
    double? oldPrice,
    String? ahorro,
    bool? active,
  }) {
    return ComboItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      ahorro: ahorro ?? this.ahorro,
      active: active ?? this.active,
    );
  }
}
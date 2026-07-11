class ComboItem {
  final String id;
  String title;     // UI: title -> BD: name
  String subtitle;  // UI: subtitle -> BD: description
  double price;     // BD: price
  bool active;      // BD: active
  /// IDs de los productos ya vinculados a este combo (viene del embed
  /// 'combo_items(product_id, products(name))' que pide ComboRepository.getAll()).
  /// Solo para lectura/precarga en el formulario de edición; no se envía a
  /// Supabase directamente (combo_repository.update() lo maneja aparte).
  final List<String> productIds;

  ComboItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.active = true,
    this.productIds = const [],
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    final comboItemsEmbed = json['combo_items'];
    final productIds = comboItemsEmbed is List
        ? comboItemsEmbed
            .whereType<Map<String, dynamic>>()
            .map((item) => item['product_id']?.toString())
            .whereType<String>()
            .toList()
        : const <String>[];

    return ComboItem(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? 'Combo',
      subtitle: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
      productIds: productIds,
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
    List<String>? productIds,
  }) {
    return ComboItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      active: active ?? this.active,
      productIds: productIds ?? this.productIds,
    );
  }
}
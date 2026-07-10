class OrderItem {
  final String? productId;
  final String? comboId;
  final String productName;
  final int quantity;
  final double unitPrice; // BD: unit_price
  final double total;     // BD: total_price
  final String? notes;
  /// Categoría REAL asignada al producto en el catálogo (Productos >
  /// Categoría), resuelta vía el embed 'products(categories(name))' cuando
  /// el repository la solicita. Es null si el repository no pidió ese join
  /// o si el producto ya no existe/no tiene categoría asignada.
  final String? categoryName;

  OrderItem({
    this.productId,
    this.comboId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.notes,
    this.categoryName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id']?.toString(),
      comboId: json['combo_id']?.toString(),
      productName: json['product_name'] ?? 'Desconocido',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total_price'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      categoryName: _extraerCategoriaDelEmbed(json['products']),
    );
  }

  // PostgREST puede devolver el embed anidado 'products(categories(name))'
  // como Map (relación 1:1, lo normal) o como List (por seguridad si algún
  // día se tratara como 1:N), así que se manejan ambos casos.
  static String? _extraerCategoriaDelEmbed(dynamic productosEmbed) {
    Map<String, dynamic>? productoMap;
    if (productosEmbed is Map<String, dynamic>) {
      productoMap = productosEmbed;
    } else if (productosEmbed is List && productosEmbed.isNotEmpty) {
      final primero = productosEmbed.first;
      if (primero is Map<String, dynamic>) productoMap = primero;
    }

    if (productoMap == null) return null;

    final categoriasEmbed = productoMap['categories'];
    if (categoriasEmbed is Map<String, dynamic>) {
      return categoriasEmbed['name']?.toString();
    } else if (categoriasEmbed is List && categoriasEmbed.isNotEmpty) {
      final primero = categoriasEmbed.first;
      if (primero is Map<String, dynamic>) {
        return primero['name']?.toString();
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'combo_id': comboId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': total, // Traducción al nombre real de la BD
      'notes': notes,
    };
  }
}
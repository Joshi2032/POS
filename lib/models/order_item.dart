class OrderItem {
  final String? productId;
  final String? comboId;
  final String productName;
  final int quantity;
  final double unitPrice; // BD: unit_price
  final double total;     // BD: total_price
  final String? notes;

  OrderItem({
    this.productId,
    this.comboId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.notes,
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
    );
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
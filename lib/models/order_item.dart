class OrderItem {
  final String productName;
  final int quantity;
  final double total;
  final String? productId;
  final double? unitPrice;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.total,
    this.productId,
    this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'] as String? ?? json['productName'] as String,
      quantity: json['quantity'] as int,
      total: (json['total'] as num).toDouble(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString(),
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? (json['unitPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'total': total,
      'product_id': productId,
      'unit_price': unitPrice,
    };
  }
}

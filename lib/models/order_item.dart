class OrderItem {
  final String productName;
  final int quantity;
  final double total;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'total': total,
    };
  }
}

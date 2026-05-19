import 'product_item.dart';

class CartItem {
  final ProductItem product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  double get total => product.price * qty;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductItem.fromJson(json['product'] as Map<String, dynamic>),
      qty: json['qty'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'qty': qty,
    };
  }
}

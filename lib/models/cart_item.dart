import 'product.dart'; // Asegúrate que esta ruta sea correcta
class CartItem {
  final Producto product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  double get total => product.price * qty;
}

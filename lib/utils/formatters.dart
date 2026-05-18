class Formatters {
  // Convierte un double a formato moneda: $1,234.50
  static String money(double value) {
    return '\$${value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    )}';
  }

  // En el futuro puedes agregar formatters de fechas aquí
  // static String date(DateTime date) { ... }
}
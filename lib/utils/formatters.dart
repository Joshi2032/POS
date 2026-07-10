class Formatters {
  // Convierte un double a formato moneda: $1,234.50 (o -$1,234.50 si es negativo)
  static String money(double value) {
    final valorSeguro = (value.isNaN || value.isInfinite) ? 0.0 : value;
    final esNegativo = valorSeguro < 0;

    final formateado = valorSeguro.abs().toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return esNegativo ? '-\$$formateado' : '\$$formateado';
  }

  // En el futuro puedes agregar formatters de fechas aquí
  // static String date(DateTime date) { ... }
}
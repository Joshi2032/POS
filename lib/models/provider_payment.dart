class ProviderPayment {
  final String id;
  String provider;
  String category;
  String method;
  double amount;
  String date;
  String time;
  String cashier;

  ProviderPayment({
    required this.id,
    required this.provider,
    required this.category,
    required this.method,
    required this.amount,
    required this.date,
    required this.time,
    required this.cashier,
  });
}

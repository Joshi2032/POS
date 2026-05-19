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

  factory ProviderPayment.fromJson(Map<String, dynamic> json) {
    return ProviderPayment(
      id: json['id'] as String,
      provider: json['provider'] as String,
      category: json['category'] as String,
      method: json['method'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      time: json['time'] as String,
      cashier: json['cashier'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'category': category,
      'method': method,
      'amount': amount,
      'date': date,
      'time': time,
      'cashier': cashier,
    };
  }

  ProviderPayment copyWith({
    String? provider,
    String? category,
    String? method,
    double? amount,
    String? date,
    String? time,
    String? cashier,
  }) {
    return ProviderPayment(
      id: id,
      provider: provider ?? this.provider,
      category: category ?? this.category,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      cashier: cashier ?? this.cashier,
    );
  }
}

class CorteCaja {
  final String id;
  final String? cashierId; // UUID del cajero relacional
  final String status; // 'open' | 'closed'
  final double openingAmount; // opening_amount
  final double cashSales; // cash_sales
  final double cardSales; // card_sales
  final double transferSales; // transfer_sales
  final double supplierPaymentsTotal; // supplier_payments_total
  final double expectedCash; // expected_cash
  final double actualCash; // actual_cash
  final double difference; // difference
  final int totalOrders; // total_orders
  final String? notes;
  final String? cutAt;

  CorteCaja({
    required this.id,
    this.cashierId,
    this.status = 'closed',
    required this.openingAmount,
    required this.cashSales,
    required this.cardSales,
    required this.transferSales,
    required this.supplierPaymentsTotal,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.totalOrders,
    this.notes,
    this.cutAt,
  });

  factory CorteCaja.fromJson(Map<String, dynamic> json) {
    return CorteCaja(
      id: json['id']?.toString() ?? '',
      cashierId: json['cashier_id']?.toString(),
      status: json['status']?.toString() ?? 'closed',
      openingAmount: (json['opening_amount'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      cardSales: (json['card_sales'] as num?)?.toDouble() ?? 0.0,
      transferSales: (json['transfer_sales'] as num?)?.toDouble() ?? 0.0,
      supplierPaymentsTotal: (json['supplier_payments_total'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
      cutAt: json['cut_at']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'cashier_id': cashierId,
      'status': status,
      'opening_amount': openingAmount,
      'cash_sales': cashSales,
      'card_sales': cardSales,
      'transfer_sales': transferSales,
      'supplier_payments_total': supplierPaymentsTotal,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'difference': difference,
      'total_orders': totalOrders,
      'notes': notes,
      if (cutAt != null) 'cut_at': cutAt,
    };
  }

  CorteCaja copyWith({
    String? id,
    String? cashierId,
    String? status,
    double? openingAmount,
    double? cashSales,
    double? cardSales,
    double? transferSales,
    double? supplierPaymentsTotal,
    double? expectedCash,
    double? actualCash,
    double? difference,
    int? totalOrders,
    String? notes,
    String? cutAt,
  }) {
    return CorteCaja(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      status: status ?? this.status,
      openingAmount: openingAmount ?? this.openingAmount,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
      transferSales: transferSales ?? this.transferSales,
      supplierPaymentsTotal: supplierPaymentsTotal ?? this.supplierPaymentsTotal,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      totalOrders: totalOrders ?? this.totalOrders,
      notes: notes ?? this.notes,
      cutAt: cutAt ?? this.cutAt,
    );
  }
}
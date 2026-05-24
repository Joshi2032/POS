class Gasto {
  final String? id;
  final String date;
  final String concept;
  final String category;
  final double amount;
  // Nota: En tu tabla de Supabase actual no existe "method" ni "notes" en expenses.
  // Por ahora los dejaremos como opcionales a nivel de Flutter para no romper tu UI.
  final String? method;
  final String? notes;

  Gasto({
    this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.amount,
    this.method = 'Efectivo',
    this.notes = '',
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id']?.toString(),
      date: json['expense_date']?.toString() ?? '',
      concept: json['description'] ?? '',
      category: json['category'] ?? 'General',
      amount: (json['amount'] as num).toDouble(),
      // Como no están en la BD, ponemos valores por defecto
      method: 'Efectivo', 
      notes: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_date': date,
      'description': concept,
      'category': category,
      'amount': amount,
      // Si en el futuro añades las columnas method y notes a Supabase, descomenta esto:
      // 'method': method,
      // 'notes': notes,
    };
  }
}

class GastoForm {
  String date;
  String concept;
  String category;
  String method;
  double amount;
  String notes;

  GastoForm({
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });
}
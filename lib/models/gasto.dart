class Gasto {
  final String id;
  String date;
  String concept;
  String category;
  String method;
  double amount;
  String notes;

  Gasto({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });
}

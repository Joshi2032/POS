class ProviderPayment {
  final String id;
  
  // Variables para Supabase (Llaves Foráneas y BD)
  final String? supplierId; // UUID real del proveedor (Obligatorio para la BD)
  final String? notes;      // Notas adicionales permitidas en la BD
  final String? cashierId;  // UUID del cajero (auth.users)
  
  // Variables visuales para la Interfaz de Usuario (UI)
  String provider; // Nombre del proveedor
  String category; // En BD se llama 'concept'
  String method;   // 'Efectivo', 'Tarjeta', 'Transferencia'
  double amount;
  String date;
  String time;
  String cashier;  // Nombre del cajero

  ProviderPayment({
    required this.id,
    this.supplierId,
    this.notes,
    this.cashierId,
    required this.provider,
    required this.category,
    required this.method,
    required this.amount,
    required this.date,
    required this.time,
    required this.cashier,
  });

  factory ProviderPayment.fromJson(Map<String, dynamic> json) {
    // 1. Traductor BD (Inglés) -> UI (Español) para el método de pago
    String methodDb = json['method']?.toString() ?? 'cash';
    String methodUi = 'Efectivo';
    if (methodDb == 'card') methodUi = 'Tarjeta';
    if (methodDb == 'transfer') methodUi = 'Transferencia';

    // 2. Extraer fecha y hora automáticas de Supabase (created_at)
    String createdAt = json['created_at']?.toString() ?? '';
    String dateUi = '';
    String timeUi = '';
    if (createdAt.isNotEmpty && createdAt.contains('T')) {
      final parts = createdAt.split('T');
      dateUi = parts[0];
      timeUi = parts[1].substring(0, 5); // Formato HH:mm
    }

    return ProviderPayment(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString(),
      notes: json['notes']?.toString(),
      cashierId: json['cashier_id']?.toString(),
      
      // Si haces un JOIN a suppliers, extraemos el nombre, si no, texto genérico
      provider: json['suppliers'] != null ? json['suppliers']['name'] : (json['provider'] ?? 'Proveedor'),
      category: json['concept']?.toString() ?? json['category']?.toString() ?? 'General',
      method: methodUi,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      
      // Priorizamos las fechas generadas por la BD
      date: dateUi.isNotEmpty ? dateUi : (json['date']?.toString() ?? ''),
      time: timeUi.isNotEmpty ? timeUi : (json['time']?.toString() ?? ''),
      
      // Nombre de cajero (se actualizará visualmente cuando conectes Perfiles/Auth)
      cashier: json['cashier']?.toString() ?? 'Cajero',
    );
  }

  Map<String, dynamic> toJson() {
    // Traductor UI (Español) -> BD (Inglés) para pasar el CHECK de Supabase
    String methodDb = 'cash';
    if (method.toLowerCase().contains('tarjeta')) methodDb = 'card';
    if (method.toLowerCase().contains('transferencia')) methodDb = 'transfer';

    return {
      if (id.isNotEmpty) 'id': id,
      'supplier_id': supplierId, // Llave foránea vital
      'concept': category,       // En la UI lo llamas category, en BD es concept
      'amount': amount,
      'method': methodDb,        // Envía 'cash', 'card' o 'transfer'
      'notes': notes,
      // OMITIMOS cashier_id por ahora para que no explote la restricción de Auth.
      // Cuando tengas el login listo, lo puedes agregar aquí:
      // 'cashier_id': cashierId, 
    };
  }

  ProviderPayment copyWith({
    String? id,
    String? supplierId,
    String? notes,
    String? cashierId,
    String? provider,
    String? category,
    String? method,
    double? amount,
    String? date,
    String? time,
    String? cashier,
  }) {
    return ProviderPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      cashierId: cashierId ?? this.cashierId,
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
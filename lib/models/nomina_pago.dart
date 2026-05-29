class NominaPago {
  final String id;
  final String? empleadoId; // BD: employee_id (UUID)
  final String fecha; // BD: date
  final String tipo; // BD: type (Nómina, Bono, etc.)
  final String periodo; // BD: period
  final double monto; // BD: amount
  final String metodo; // BD: payment_method
  final String? notas; // BD: notes

  // Variable solo para UI (obtenida mediante un JOIN o asignada manualmente)
  final String empleadoNombre;
  String get empleado => empleadoNombre;
  NominaPago({
    required this.id,
    this.empleadoId,
    required this.fecha,
    required this.tipo,
    required this.periodo,
    required this.monto,
    required this.metodo,
    this.notas,
    required this.empleadoNombre,
  });

  factory NominaPago.fromJson(Map<String, dynamic> json) {
    // Traductor Inglés a Español para UI
    String methodDb = json['payment_method']?.toString() ?? 'cash';
    String methodUi = 'Efectivo';
    if (methodDb == 'card') methodUi = 'Tarjeta';
    if (methodDb == 'transfer') methodUi = 'Transferencia';

    // Extraemos nombre si viene del JOIN con employees
    String nombreEmp = 'Empleado Desconocido';
    if (json['employees'] != null && json['employees']['first_name'] != null) {
      nombreEmp =
          '${json['employees']['first_name']} ${json['employees']['last_name'] ?? ''}'
              .trim();
    } else if (json['empleadoNombre'] != null) {
      nombreEmp = json['empleadoNombre'];
    }

    String rawDate = json['date']?.toString() ?? '';
    if (rawDate.contains('T')) rawDate = rawDate.split('T').first;

    return NominaPago(
      id: json['id']?.toString() ?? '',
      empleadoId: json['employee_id']?.toString(),
      fecha: rawDate,
      tipo: json['type'] ?? 'Nómina',
      periodo: json['period'] ?? 'Semanal',
      monto: (json['amount'] as num?)?.toDouble() ?? 0.0,
      metodo: methodUi,
      notas: json['notes']?.toString(),
      empleadoNombre: nombreEmp,
    );
  }

  Map<String, dynamic> toJson() {
    // Traductor Español a Inglés para BD
    String methodDb = 'cash';
    if (metodo.toLowerCase().contains('tarjeta')) methodDb = 'card';
    if (metodo.toLowerCase().contains('transferencia')) methodDb = 'transfer';

    return {
      if (id.isNotEmpty) 'id': id,
      'employee_id': empleadoId,
      'date': fecha.isNotEmpty
          ? fecha
          : DateTime.now().toIso8601String().split('T').first,
      'type': tipo,
      'period': periodo,
      'amount': monto,
      'payment_method': methodDb,
      'notes': notas,
      // OMITIMOS 'empleadoNombre' porque no existe como columna en 'payroll'
    };
  }
}

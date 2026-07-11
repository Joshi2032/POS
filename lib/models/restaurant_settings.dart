class RestaurantSettings {
  final String nombreNegocio;
  final String rfc;
  final String direccion;
  final String telefono;
  final bool alertaStock;
  final bool resumenDiario;
  final bool nuevasOrdenes;
  final bool cierreAutomatico;
  final String pin;

  RestaurantSettings({
    required this.nombreNegocio,
    required this.rfc,
    required this.direccion,
    required this.telefono,
    required this.alertaStock,
    required this.resumenDiario,
    required this.nuevasOrdenes,
    required this.cierreAutomatico,
    required this.pin,
  });

  factory RestaurantSettings.fromJson(Map<String, dynamic> json) {
    return RestaurantSettings(
      nombreNegocio: json['nombre_negocio']?.toString() ?? '',
      rfc: json['rfc']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      alertaStock: json['alerta_stock'] as bool? ?? true,
      resumenDiario: json['resumen_diario'] as bool? ?? true,
      nuevasOrdenes: json['nuevas_ordenes'] as bool? ?? true,
      cierreAutomatico: json['cierre_automatico'] as bool? ?? true,
      pin: json['pin']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_negocio': nombreNegocio,
      'rfc': rfc,
      'direccion': direccion,
      'telefono': telefono,
      'alerta_stock': alertaStock,
      'resumen_diario': resumenDiario,
      'nuevas_ordenes': nuevasOrdenes,
      'cierre_automatico': cierreAutomatico,
      'pin': pin,
    };
  }
}

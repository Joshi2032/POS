// Utilidades centralizadas para trabajar con la hora/fecha de México
// (America/Mexico_City) sin depender de la zona horaria del dispositivo.
//
// México eliminó el horario de verano desde 2022 (excepto la franja
// fronteriza norte, que no aplica a este negocio), así que el offset
// respecto a UTC es fijo todo el año: UTC-6. Antes esta misma constante y
// lógica estaba copiada por separado en caja_repository.dart,
// provider_payment.dart, reservaciones_provider.dart, dashboard_provider.dart
// y caja_page.dart; quedó centralizada aquí para que un cambio futuro (ej. si
// algún día aplicara horario de verano) solo se haga en un lugar.

/// Offset fijo de México zona Centro respecto a UTC.
const Duration offsetMexicoCentro = Duration(hours: -6);

/// Fecha/hora actual, con sus campos (.year/.month/.day/.hour, etc.)
/// reflejando el reloj de pared de México. El objeto sigue siendo un
/// DateTime UTC internamente (no un instante real distinto), así que solo
/// debe usarse para LEER esos campos o para construir un día-calendario,
/// nunca para compararse directamente contra un timestamp UTC crudo.
DateTime ahoraComoWallClockMexico() {
  return DateTime.now().toUtc().add(offsetMexicoCentro);
}

/// Día calendario de HOY en México, como un DateTime "plano" a medianoche.
/// Solo debe compararse contra otros valores creados con [diaMexicoDesde] o
/// de esta misma forma.
DateTime hoyEnMexico() {
  final wallClock = ahoraComoWallClockMexico();
  return DateTime(wallClock.year, wallClock.month, wallClock.day);
}

/// Fecha de HOY en México en formato YYYY-MM-DD, para comparar contra
/// columnas `date` (como cash_movements.date) o contra el prefijo de un
/// timestamp ya convertido a string.
String fechaHoyMexicoStr() {
  final hoy = hoyEnMexico();
  final anio = hoy.year.toString().padLeft(4, '0');
  final mes = hoy.month.toString().padLeft(2, '0');
  final dia = hoy.day.toString().padLeft(2, '0');
  return '$anio-$mes-$dia';
}

/// Convierte un timestamp de Supabase (created_at/paid_at, timestamptz; o
/// una columna `date` simple como expense_date) al día-calendario de MÉXICO
/// que le corresponde, como un DateTime "plano" a medianoche. Solo debe
/// compararse contra otros valores creados de esta misma forma.
///
/// Así, una venta de las 11pm hora México (5am UTC del día siguiente) se
/// cuenta en el día de México que le corresponde, no en el día UTC crudo. Si
/// el valor es una fecha simple sin hora (columna `date`), se usa tal cual
/// sin aplicar ninguna conversión de zona horaria (ya representa un día
/// definido, sin ambigüedad de hora que convertir).
DateTime? diaMexicoDesde(dynamic timestamp) {
  if (timestamp == null) return null;
  final str = timestamp.toString();
  if (str.isEmpty) return null;
  try {
    if (!str.contains('T')) {
      final soloFecha = DateTime.parse(str);
      return DateTime(soloFecha.year, soloFecha.month, soloFecha.day);
    }

    final utc = DateTime.parse(str).toUtc();
    final mexico = utc.add(offsetMexicoCentro);
    return DateTime(mexico.year, mexico.month, mexico.day);
  } catch (_) {
    return null;
  }
}

/// Instante UTC real correspondiente al inicio (medianoche) del día indicado
/// en hora de México. Útil para construir rangos de consulta contra columnas
/// timestamptz (ej. `paid_at >= inicioUtc`). [diaMexico] debe ser un
/// DateTime "plano" ya normalizado (de [hoyEnMexico] o [diaMexicoDesde]).
DateTime inicioDeDiaMexicoEnUtc(DateTime diaMexico) {
  final comoUtc = DateTime.utc(diaMexico.year, diaMexico.month, diaMexico.day);
  return comoUtc.subtract(offsetMexicoCentro);
}

/// Limpia un payload antes de enviarlo a Supabase: solo elimina las llaves
/// cuyo valor es una cadena vacía en una columna de tipo uuid (reconocida
/// por terminar en '_id', como table_id/discount_id/supplier_id), porque
/// Postgres rechaza '' como uuid inválido (error 22P02).
///
/// A diferencia del filtro anterior (`value == null || value.toString().
/// trim().isEmpty`), este NO elimina valores null ni cadenas vacías en
/// columnas de texto normales (notas, descripción, etc.): esas sí deben
/// llegar a Supabase para poder borrar un campo opcional guardándolo en
/// blanco, en vez de que la llave desaparezca del payload y Supabase deje
/// intacto el valor anterior.
void limpiarCamposUuidVacios(Map<String, dynamic> data) {
  data.removeWhere((key, value) =>
      key.endsWith('_id') && value != null && value.toString().trim().isEmpty);
}

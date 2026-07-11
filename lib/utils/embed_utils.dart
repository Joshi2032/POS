/// PostgREST puede devolver un embed anidado (ej. 'products(categories(name))')
/// como Map (relación N:1, lo normal) o como List (por seguridad, si algún
/// día se tratara como 1:N). Normaliza cualquiera de las dos formas a un
/// solo Map, o null si no hay datos.
Map<String, dynamic>? asEmbedMap(dynamic embed) {
  if (embed is Map<String, dynamic>) return embed;
  if (embed is List && embed.isNotEmpty) {
    final primero = embed.first;
    if (primero is Map<String, dynamic>) return primero;
  }
  return null;
}

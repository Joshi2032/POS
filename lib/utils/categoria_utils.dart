/// Resuelve la categoría a mostrar para un producto vendido: usa la
/// categoría REAL asignada en el catálogo (Productos > Categoría) si está
/// disponible, y solo si el producto ya no existe o no tiene categoría
/// asignada recurre a un respaldo por palabras clave en el nombre, para no
/// dejar el reporte/dashboard sin ninguna categoría.
String resolverCategoriaConFallback(String? categoriaReal, String nombreProducto) {
  final limpio = categoriaReal?.trim();
  if (limpio != null && limpio.isNotEmpty) {
    return limpio;
  }

  final rawName = nombreProducto.toLowerCase();
  if (rawName.contains('arrachera') ||
      rawName.contains('t-bone') ||
      rawName.contains('plato') ||
      rawName.contains('corte')) {
    return 'Alimentos';
  } else if (rawName.contains('cerveza') ||
      rawName.contains('refresco') ||
      rawName.contains('agua')) {
    return 'Bebidas';
  } else if (rawName.contains('combo') || rawName.contains('paquete')) {
    return 'Combos';
  }
  return 'Sin categoría';
}

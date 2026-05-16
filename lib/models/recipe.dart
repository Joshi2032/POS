class RecipeSupply {
  String insumoId;
  String insumo;
  double cantidad;
  String unidad;
  String categoria;

  RecipeSupply(
      {required this.insumoId,
      required this.insumo,
      required this.cantidad,
      required this.unidad,
      required this.categoria});
}

class Recipe {
  final String id;
  String name;
  String category;
  int yieldPortions;
  int prepMinutes;
  String description;
  bool active;
  List<RecipeSupply> supplies;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.yieldPortions,
    required this.prepMinutes,
    required this.description,
    required this.active,
    required this.supplies,
  });
}

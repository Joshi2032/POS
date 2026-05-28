class RecipeSupply {
  String insumoId;
  String insumo;
  double cantidad;
  String unidad;
  String categoria;

  RecipeSupply({
    required this.insumoId,
    required this.insumo,
    required this.cantidad,
    required this.unidad,
    required this.categoria,
  });

  factory RecipeSupply.fromJson(Map<String, dynamic> json) {
    return RecipeSupply(
      insumoId: json['supply_id'] as String,
      insumo: json['supply_name'] as String,
      cantidad: (json['quantity'] as num).toDouble(),
      unidad: json['unit'] as String,
      categoria: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supply_id': insumoId,
      'supply_name': insumo,
      'quantity': cantidad,
      'unit': unidad,
      'category': categoria,
    };
  }
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

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<RecipeSupply> parsedSupplies = [];
    if (json['recipe_supplies'] != null) {
      parsedSupplies = (json['recipe_supplies'] as List<dynamic>)
          .map((s) => RecipeSupply.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      yieldPortions: json['yield_portions'] as int? ?? 1,
      prepMinutes: json['prep_minutes'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      supplies: parsedSupplies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'yield_portions': yieldPortions,
      'prep_minutes': prepMinutes,
      'description': description,
      'active': active,
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? category,
    int? yieldPortions,
    int? prepMinutes,
    String? description,
    bool? active,
    List<RecipeSupply>? supplies,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      yieldPortions: yieldPortions ?? this.yieldPortions,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      description: description ?? this.description,
      active: active ?? this.active,
      supplies: supplies ?? this.supplies,
    );
  }
}

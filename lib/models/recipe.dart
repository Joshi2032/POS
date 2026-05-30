class RecipeSupply {
  final String? id;
  final String? supplyId;
  final String supplyName;
  final double quantity;
  final String unit;

  RecipeSupply({
    this.id,
    this.supplyId,
    required this.supplyName,
    required this.quantity,
    required this.unit,
  });

  factory RecipeSupply.fromJson(Map<String, dynamic> json) {
    return RecipeSupply(
      id: json['id']?.toString(),
      supplyId: json['supply_id']?.toString(),
      supplyName: json['supply_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (supplyId != null) 'supply_id': supplyId,
      'supply_name': supplyName,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class Recipe {
  final String id;
  final String name;
  final String? category;
  final double yieldPortions;
  final int prepMinutes;
  final String? description;
  final bool active;
  final List<RecipeSupply> supplies;

  Recipe({
    required this.id,
    required this.name,
    this.category,
    this.yieldPortions = 1.0,
    this.prepMinutes = 0,
    this.description,
    this.active = true,
    this.supplies = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var suppliesList = <RecipeSupply>[];
    if (json['recipe_supplies'] != null) {
      suppliesList = (json['recipe_supplies'] as List)
          .map((i) => RecipeSupply.fromJson(i))
          .toList();
    }

    return Recipe(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? 'Sin nombre',
      category: json['category'],
      yieldPortions: (json['yield_portions'] as num?)?.toDouble() ?? 1.0,
      prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
      description: json['description'],
      active: json['active'] ?? true,
      supplies: suppliesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      'yield_portions': yieldPortions,
      'prep_minutes': prepMinutes,
      'description': description,
      'active': active,
    };
  }
}
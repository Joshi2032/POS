class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int stock;
  final double cost;
  final String provider;

  InventoryItem(
      {required this.id,
      required this.name,
      required this.category,
      required this.stock,
      required this.cost,
      required this.provider});
}

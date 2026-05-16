class ComboItem {
  final String id;
  String title;
  String subtitle;
  List<String> tags;
  double price;
  double oldPrice;
  String ahorro;

  ComboItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.price,
    required this.oldPrice,
    required this.ahorro,
  });
}

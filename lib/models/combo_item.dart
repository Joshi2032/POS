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

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      price: (json['price'] as num).toDouble(),
      oldPrice: (json['old_price'] as num).toDouble(),
      ahorro: json['discount'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'tags': tags,
      'price': price,
      'old_price': oldPrice,
      'discount': ahorro,
    };
  }

  ComboItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? tags,
    double? price,
    double? oldPrice,
    String? ahorro,
  }) {
    return ComboItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      ahorro: ahorro ?? this.ahorro,
    );
  }
}

// lib/features/catalog/data/category_model.dart
class WasteCategory {
  final int id;
  final String title;
  final String unit;
  final double pricePerUnit;

  WasteCategory({
    required this.id,
    required this.title,
    required this.unit,
    required this.pricePerUnit,
  });

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id'],
      title: json['title'],
      unit: json['unit'],
      pricePerUnit: double.parse(json['price_per_unit'].toString()),
    );
  }
}

// product.dart

import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String store;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double currentPrice;
  @HiveField(4)
  final double normalPrice;
  @HiveField(5)
  final String discountPercentage;
  @HiveField(6)
  final String category;
  @HiveField(7)
  final String subcategory;
  @HiveField(8)
  final String url;
  @HiveField(9)
  final String imageUrl;
  @HiveField(10)
  final List<String> searchKeywords;

  // Changed from String? to String because you stated it's never empty.
  // This makes it safer to use in the UI without null checks.
  @HiveField(11)
  final String availableFrom;

  @HiveField(12)
  final String? sonderkondition;

  Product({
    required this.id,
    required this.store,
    required this.name,
    required this.currentPrice,
    required this.normalPrice,
    required this.discountPercentage,
    required this.category,
    required this.subcategory,
    required this.url,
    required this.imageUrl,
    required this.searchKeywords,
    required this.availableFrom,
    this.sonderkondition,
  });

  factory Product.fromJson(String id, Map<String, dynamic> data) {
    final keywordsData = data['searchKeywords'] as List<dynamic>?;
    final keywords = keywordsData?.map((e) => e.toString()).toList() ?? [];

    // --- LOGIC FOR `sonderkondition` (Correct) ---
    // If the string is "Keine Sonderkondition", we convert it to null so the UI can hide it.
    String? sonderkonditionString = data['sonderkondition'] as String?;
    if (sonderkonditionString == 'Keine Sonderkondition') {
      sonderkonditionString = null;
    }

    return Product(
      id: id,
      store: (data['store'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? '').trim(),
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0.0,
      normalPrice: (data['normalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (data['discountPercentage'] as num?)?.toInt().toString() ?? '0',
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      url: data['url'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      searchKeywords: keywords,

      // --- LOGIC FOR `available_from` (Corrected) ---
      // Pass the string directly. Provide a default fallback in case the field is missing.
      availableFrom: data['available_from'] as String? ?? 'Jetzt verfügbar',

      // Assign the processed sonderkondition value
      sonderkondition: sonderkonditionString,
    );
  }

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product.fromJson(id, data);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store': store,
    'name': name,
    'currentPrice': currentPrice,
    'normalPrice': normalPrice,
    'discountPercentage': discountPercentage,
    'category': category,
    'subcategory': subcategory,
    'url': url,
    'imageUrl': imageUrl,
    'searchKeywords': searchKeywords,

    // `availableFrom` is a non-nullable string, so just pass it.
    'available_from': availableFrom,

    // When saving, restore the default string if the value is null.
    'sonderkondition': sonderkondition ?? 'Keine Sonderkondition',
  };
}
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

  // --- CHANGED: Storing this as a number is better for any future use.
  @HiveField(5)
  final int discountPercentage;

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
    required this.discountPercentage, // CHANGED: Now expects an int
    required this.category,
    required this.subcategory,
    required this.url,
    required this.imageUrl,
    required this.searchKeywords,
    required this.availableFrom,
    this.sonderkondition,
  });

  // --- ADDED: A robust getter to calculate the real discount rate.
  /// Calculates the discount rate as a decimal (e.g., 0.5 for 50%).
  /// This is the most reliable way to sort by discount.
  /// Returns 0.0 if there is no discount or if normalPrice is invalid.
  double get discountRate {
    // Prevent division by zero and handle cases with no discount.
    if (normalPrice <= 0 || normalPrice <= currentPrice) {
      return 0.0;
    }
    // Formula: (amount_saved) / original_price
    return (normalPrice - currentPrice) / normalPrice;
  }

  factory Product.fromJson(String id, Map<String, dynamic> data) {
    final keywordsData = data['searchKeywords'] as List<dynamic>?;
    final keywords = keywordsData?.map((e) => e.toString()).toList() ?? [];

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
      // --- CHANGED: Parse to int directly, without converting back to string.
      discountPercentage: (data['discountPercentage'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      url: data['url'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      searchKeywords: keywords,
      availableFrom: data['available_from'] as String? ?? 'Jetzt verfügbar',
      sonderkondition: sonderkonditionString,
    );
  }

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product.fromJson(id, data);
  }

  // lib/models/product.dart

// ... (all of your existing code from the top of the file down to toJson)

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
    'available_from': availableFrom,
    'sonderkondition': sonderkondition ?? 'Keine Sonderkondition',
  };

  // ===================================================
  // === PASTE THE NEW METHOD HERE                     ===
  // ===================================================
  /// Creates a "plain" copy of this Product without any Hive database connection.
  /// This makes it safe to send to a background isolate.
  Product toPlainObject() {
    return Product(
      id: id,
      store: store,
      name: name,
      currentPrice: currentPrice,
      normalPrice: normalPrice,
      discountPercentage: discountPercentage,
      category: category,
      subcategory: subcategory,
      url: url,
      imageUrl: imageUrl,
      // It's good practice to create a new list instance as well.
      searchKeywords: List<String>.from(searchKeywords),
      availableFrom: availableFrom,
      sonderkondition: sonderkondition,
    );
  }

} // <-- This is the final closing brace of your Product class
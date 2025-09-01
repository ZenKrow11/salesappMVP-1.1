// lib/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final int discountPercentage;
  @HiveField(6)
  final String category;
  @HiveField(7)
  final String subcategory;
  @HiveField(8)
  final String url;
  @HiveField(9)
  final String imageUrl;

  // --- CHANGED: Renamed from searchKeywords to match Firestore field 'name_tokens'
  @HiveField(10)
  final List<String> nameTokens;

  // --- CHANGED: availableFrom is now a proper, nullable DateTime object
  @HiveField(11)
  final DateTime? availableFrom;

  @HiveField(12)
  final String? sonderkondition;

  // --- ADDED: The new dealEnd field, also as a nullable DateTime
  @HiveField(13)
  final DateTime? dealEnd;

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
    required this.nameTokens, // --- CHANGED
    this.availableFrom,      // --- CHANGED
    this.sonderkondition,
    this.dealEnd,            // --- ADDED
  });

  // --- HELPER FUNCTION ---
  /// Safely converts a Firestore Timestamp or null into a DateTime object.
  static DateTime? _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null; // Return null if the data is missing or not a Timestamp
  }

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    // --- CHANGED: Reads from 'name_tokens' field now
    final tokensData = data['name_tokens'] as List<dynamic>?;
    final tokens = tokensData?.map((e) => e.toString()).toList() ?? [];

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
      discountPercentage: (data['discountPercentage'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      url: data['url'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      nameTokens: tokens, // --- CHANGED

      // --- CHANGED: Use the helper to correctly parse Timestamps
      availableFrom: _timestampToDateTime(data['availableFrom']),
      dealEnd: _timestampToDateTime(data['dealEnd']), // --- ADDED

      sonderkondition: sonderkonditionString,
    );
  }

  // Your other methods like discountRate, toJson, toPlainObject are mostly fine,
  // but let's update them for consistency.

  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
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
    'name_tokens': nameTokens,
    'availableFrom': availableFrom,
    'dealEnd': dealEnd,
    'sonderkondition': sonderkondition,
  };

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
      nameTokens: List<String>.from(nameTokens),
      availableFrom: availableFrom,
      sonderkondition: sonderkondition,
      dealEnd: dealEnd,
    );
  }
}
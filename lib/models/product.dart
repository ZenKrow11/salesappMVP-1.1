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
  @HiveField(10)
  final List<String> nameTokens;
  @HiveField(11)
  final DateTime? availableFrom;
  @HiveField(12)
  final String? sonderkondition;
  @HiveField(13)
  final DateTime? dealEnd;
  @HiveField(14)
  final bool isCustom;
  @HiveField(15)
  final bool isOnSale;

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
    required this.nameTokens,
    this.availableFrom,
    this.sonderkondition,
    this.dealEnd,
    this.isCustom = false,
    this.isOnSale = true,
  });

  static DateTime? _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  // In lib/models/product.dart

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    final tokensData = data['name_tokens'] as List<dynamic>?;
    final tokens = tokensData?.map((e) => e.toString()).toList() ?? [];

    String? sonderkonditionString = data['sonderkondition']?.toString();
    if (sonderkonditionString == 'Keine Sonderkondition' || sonderkonditionString == 'nan') {
      sonderkonditionString = null;
    }

    final categoryString = data['category']?.toString() ?? '';
    final subcategoryString = data['subcategory']?.toString() ?? '';

    return Product(
      id: id,
      store: (data['store']?.toString() ?? '').trim(),
      name: (data['name']?.toString() ?? '').trim(),
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0.0,
      normalPrice: (data['normalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (data['discountPercentage'] as num?)?.toInt() ?? 0,
      category: categoryString,
      subcategory: subcategoryString,
      url: data['url']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      nameTokens: tokens,
      availableFrom: _timestampToDateTime(data['availableFrom']),
      dealEnd: _timestampToDateTime(data['dealEnd']),
      sonderkondition: sonderkonditionString,
      isCustom: data['isCustom'] as bool? ?? false,
      isOnSale: data['isOnSale'] as bool? ?? true,
    );
  }

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
    'isCustom': isCustom,
    'isOnSale': isOnSale,
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
      isCustom: isCustom,
      isOnSale: isOnSale,
    );
  }
}
// lib/models/plain_product.dart

import 'categorizable.dart';

// NOTE: This class DOES NOT import Hive and DOES NOT extend HiveObject.
// It is a Plain Old Dart Object (PODO).
class PlainProduct implements Categorizable {
  final String id;
  final String store;
  final String name;
  final double currentPrice;
  final double normalPrice;
  final int discountPercentage;
  final String category;
  final String subcategory;
  final String url;
  final String imageUrl;
  final List<String> nameTokens;
  final DateTime? dealStart;
  final String? specialCondition;
  final DateTime? dealEnd;
  final bool isCustom;
  final bool isOnSale;

  PlainProduct({
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
    this.dealStart,
    this.specialCondition,
    this.dealEnd,
    this.isCustom = false,
    this.isOnSale = true,
  });

  // ✅ Factory constructor must be inside the class
  factory PlainProduct.fromProduct(dynamic product) {
    return PlainProduct(
      id: product.id,
      store: product.store,
      name: product.name,
      currentPrice: product.currentPrice,
      normalPrice: product.normalPrice,
      discountPercentage: product.discountPercentage,
      category: product.category,
      subcategory: product.subcategory,
      url: product.url,
      imageUrl: product.imageUrl,
      nameTokens: product.nameTokens ?? [],
      dealStart: product.dealStart,
      specialCondition: product.specialCondition,
      dealEnd: product.dealEnd,
      isCustom: product.isCustom ?? false,
      isOnSale: product.isOnSale ?? true,
    );
  }

  // A helper getter for sorting, same as in the original Product class.
  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
  }
}

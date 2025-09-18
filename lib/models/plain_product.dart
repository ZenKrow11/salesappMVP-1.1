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
  final String? sonderkondition;
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
    this.sonderkondition,
    this.dealEnd,
    this.isCustom = false,
    this.isOnSale = true,
  });

  // A helper getter for sorting, same as in the original Product class.
  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
  }
}
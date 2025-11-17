// lib/models/plain_product.dart

import 'categorizable.dart';

class PlainProduct implements Categorizable {
  final String id;
  final String store;
  final String name;
  final double currentPrice;
  final double normalPrice;
  final int discountPercentage;
  @override
  final String category;
  final String subcategory;
  final String url;
  final String imageUrl; // This is the property definition
  final List<String> nameTokens;
  final DateTime? dealStart;
  final String? specialCondition;
  final DateTime? dealEnd;
  final bool isCustom;
  final bool isOnSale;
  final int quantity;
  final String discountType;

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
    this.quantity = 1,
    this.discountType = 'Standard Discount',
  });

  /// Factory constructor to create a PlainProduct from a Hive-backed Product.
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
      // --- THIS IS THE CORRECTED LINE ---
      imageUrl: product.imageUrl,
      nameTokens: List<String>.from(product.nameTokens ?? []),
      dealStart: product.dealStart,
      specialCondition: product.specialCondition,
      dealEnd: product.dealEnd,
      isCustom: product.isCustom ?? false,
      isOnSale: product.isOnSale ?? true,
      quantity: product.quantity ?? 1,
      discountType: product.discountType ?? 'Standard Discount',
    );
  }

  /// A helper getter for sorting, same as in the original Product class.
  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
  }
}
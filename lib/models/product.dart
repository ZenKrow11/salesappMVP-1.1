// lib/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'plain_product.dart';
import 'categorizable.dart';

part 'product.g.dart';

/// Represents a product item, designed to be stored in both Firestore and local Hive cache.
@HiveType(typeId: 0)
class Product extends HiveObject implements Categorizable {
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
  final DateTime? dealStart;
  @HiveField(12)
  final String? specialCondition; // <-- RENAMED from sonderkondition
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
    this.dealStart,
    this.specialCondition, // <-- RENAMED from sonderkondition
    this.dealEnd,
    this.isCustom = false,
    this.isOnSale = true,
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    // UPDATED: Now reads from 'special_condition' which matches your Python script output
    String? specialConditionValue = _parseString(data['special_condition']);
    if (specialConditionValue.isEmpty || specialConditionValue.toLowerCase() == 'nan') {
      specialConditionValue = null;
    }

    return Product(
      id: id,
      store: _parseString(data['store']),
      name: _parseString(data['name']),
      currentPrice: _parseDouble(data['currentPrice']),
      normalPrice: _parseDouble(data['normalPrice']),
      discountPercentage: _parseInt(data['discountPercentage']),
      category: _parseString(data['category']),
      subcategory: _parseString(data['subcategory']),
      url: _parseString(data['url']),
      imageUrl: _parseString(data['imageUrl']),
      nameTokens: _parseStringList(data['name_tokens']),
      dealStart: _parseDate(data['dealStart']),
      dealEnd: _parseDate(data['dealEnd']),
      specialCondition: specialConditionValue, // <-- UPDATED to use the correct variable
      isCustom: _parseBool(data['isCustom'], defaultValue: false),
      isOnSale: _parseBool(data['isOnSale'], defaultValue: true),
    );
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
    'dealStart': dealStart != null ? Timestamp.fromDate(dealStart!) : null,
    'dealEnd': dealEnd != null ? Timestamp.fromDate(dealEnd!) : null,
    'special_condition': specialCondition, // <-- RENAMED to match database schema
    'isCustom': isCustom,
    'isOnSale': isOnSale,
  };

  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
  }

  /// Convert Hive-backed Product to a plain, sendable object for isolates.
  PlainProduct toPlainObject() {
    return PlainProduct(
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
      dealStart: dealStart,
      specialCondition: specialCondition, // <-- RENAMED
      dealEnd: dealEnd,
      isCustom: isCustom,
      isOnSale: isOnSale,
    );
  }
}

// Helper Functions (unchanged)
DateTime? _parseDate(dynamic data) {
  if (data is Timestamp) return data.toDate();
  return null;
}

String _parseString(dynamic data, {String defaultValue = ''}) {
  if (data is String) return data.trim();
  return data?.toString().trim() ?? defaultValue;
}

double _parseDouble(dynamic data, {double defaultValue = 0.0}) {
  if (data is num) return data.toDouble();
  return defaultValue;
}

int _parseInt(dynamic data, {int defaultValue = 0}) {
  if (data is num) return data.round();
  return defaultValue;
}

bool _parseBool(dynamic data, {bool defaultValue = false}) {
  if (data is bool) return data;
  return defaultValue;
}

List<String> _parseStringList(dynamic data) {
  if (data is List) {
    return data.map((item) => item.toString()).toList();
  }
  return [];
}
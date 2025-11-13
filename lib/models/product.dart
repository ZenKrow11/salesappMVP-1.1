// lib/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Required for @immutable
import 'package:hive/hive.dart';
import 'plain_product.dart';
import 'categorizable.dart';

part 'product.g.dart';

/// Represents a product item, designed for use with Firestore, Hive, and Riverpod.
///
/// Implements [Equatable] for proper object comparison, which is essential for
/// state management to detect when the UI needs to be updated.
@HiveType(typeId: 0)
class Product extends HiveObject with EquatableMixin implements Categorizable {
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
  @override
  final String category;
  @HiveField(7)
  @override
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
  final String? specialCondition;
  @HiveField(13)
  final DateTime? dealEnd;
  @HiveField(14)
  final bool isCustom;
  @HiveField(15)
  final bool isOnSale;
  @HiveField(16)
  final int quantity;

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
    this.specialCondition,
    this.dealEnd,
    this.isCustom = false,
    this.isOnSale = true,
    this.quantity = 1,
  });

  /// Factory constructor to create a Product from a Firestore document.
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
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
      specialCondition: specialConditionValue,
      isCustom: _parseBool(data['isCustom'], defaultValue: false),
      isOnSale: _parseBool(data['isOnSale'], defaultValue: true),
      quantity: _parseInt(data['quantity'], defaultValue: 1),
    );
  }

  /// Converts the Product instance to a JSON map for Firestore.
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
    'special_condition': specialCondition,
    'isCustom': isCustom,
    'isOnSale': isOnSale,
    'quantity': quantity,
  };

  /// Computed property for discount rate.
  double get discountRate {
    if (normalPrice <= 0 || normalPrice <= currentPrice) return 0.0;
    return (normalPrice - currentPrice) / normalPrice;
  }

  Product copyWith({
    String? id,
    String? store,
    String? name,
    double? currentPrice,
    double? normalPrice,
    int? discountPercentage,
    String? category,
    String? subcategory,
    String? url,
    String? imageUrl,
    List<String>? nameTokens,
    DateTime? dealStart,
    String? specialCondition,
    DateTime? dealEnd,
    bool? isCustom,
    bool? isOnSale,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      store: store ?? this.store,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      normalPrice: normalPrice ?? this.normalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      nameTokens: nameTokens ?? this.nameTokens,
      dealStart: dealStart ?? this.dealStart,
      specialCondition: specialCondition ?? this.specialCondition,
      dealEnd: dealEnd ?? this.dealEnd,
      isCustom: isCustom ?? this.isCustom,
      isOnSale: isOnSale ?? this.isOnSale,
      quantity: quantity ?? this.quantity,
    );
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
      specialCondition: specialCondition,
      dealEnd: dealEnd,
      isCustom: isCustom,
      isOnSale: isOnSale,
      quantity: quantity,
    );
  }

  @override
  List<Object?> get props => [
    id,
    store,
    name,
    currentPrice,
    normalPrice,
    discountPercentage,
    category,
    subcategory,
    url,
    imageUrl,
    nameTokens,
    dealStart,
    specialCondition,
    dealEnd,
    isCustom,
    isOnSale,
    quantity,
  ];
}

// Helper Functions
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
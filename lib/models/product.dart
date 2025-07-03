import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String store; // This will now be a clean, trimmed string

  // ... other fields remain the same
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
  });

  factory Product.fromJson(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      // V-- THE FIX IS HERE --V
      store: (data['store'] as String? ?? '').trim(),
      // ^----------------------^
      name: (data['name'] as String? ?? '').trim(), // Also good to trim names
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0.0,
      normalPrice: (data['normalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: data['discountPercentage']?.toString() ?? '0',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      url: data['url'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
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
  };
}
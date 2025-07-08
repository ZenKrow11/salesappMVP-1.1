import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'product.g.dart';

// Helper function for parsing German dates (This is correct and stays)
DateTime? _parseGermanDateString(String? dateString) {
  if (dateString == null || dateString.isEmpty || dateString.toLowerCase() == 'verfügbar') {
    return null;
  }
  try {
    String parsableString = dateString.toLowerCase();
    if (parsableString.contains(' - ')) {
      parsableString = parsableString.split(' - ')[0].trim();
    }
    if (parsableString.startsWith('ab ')) {
      parsableString = parsableString.substring(3).trim();
    }
    final currentYear = DateTime.now().year;
    parsableString = '$parsableString$currentYear';
    final formatter = DateFormat('d.M.yyyy');
    return formatter.parse(parsableString);
  } catch (e) {
    print('Could not parse date: "$dateString". Error: $e');
    return null;
  }
}

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
  final List<String> searchKeywords; // Correctly defined
  @HiveField(11)
  final DateTime? availableFrom;
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
    required this.searchKeywords, // In the constructor
    this.availableFrom,
    this.sonderkondition,
  });

  factory Product.fromJson(String id, Map<String, dynamic> data) {
    // --- THIS IS THE COMBINED, CORRECT LOGIC ---

    // 1. Correctly parse searchKeywords
    final keywordsData = data['searchKeywords'] as List<dynamic>?;
    final keywords = keywordsData?.map((e) => e.toString()).toList() ?? [];

    // 2. Correctly parse the date string
    final availableFromDate = _parseGermanDateString(data['available_from'] as String?);

    // --- END OF COMBINED LOGIC ---

    return Product(
      id: id,
      store: (data['store'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? '').trim(),
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0.0,
      normalPrice: (data['normalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: data['discountPercentage']?.toString() ?? '0',
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      url: data['url'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',

      // Assign BOTH correctly parsed fields
      searchKeywords: keywords,
      availableFrom: availableFromDate,

      sonderkondition: data['Sonderkondition'] as String?,
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
    'available_from': availableFrom?.toIso8601String(),
    'Sonderkondition': sonderkondition,
  };
}
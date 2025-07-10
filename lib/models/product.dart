import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'product.g.dart';

// --- UPDATED AND CORRECTED HELPER FUNCTION ---
DateTime? _parseGermanDateString(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return null;
  }

  final lowercased = dateString.toLowerCase();

  // Case 1: The offer is available now. Return null as there's no *future* start date.
  if (lowercased.contains('jetzt verfügbar')) {
    return null;
  }

  // Case 2: Use regex to find the first date pattern (e.g., "08.07." or "14.07.")
  final regex = RegExp(r'(\d{1,2}\.\d{1,2}\.)');
  final match = regex.firstMatch(lowercased);

  if (match == null) {
    // If no date pattern is found, we can't parse it.
    print('Could not find a date pattern (dd.mm.) in "$dateString"');
    return null;
  }

  try {
    // Extract the matched date part, e.g., "08.07."
    final datePart = match.group(0)!;

    // Smartly determine the year (handle year-end rollovers)
    final now = DateTime.now();
    int year = now.year;

    // First, try parsing with the current year
    final formatter = DateFormat('d.M.yyyy');
    DateTime prospectiveDate = formatter.parse('$datePart$year');

    // If the resulting date is more than a week in the past (e.g., it's December
    // and the offer is for January), assume it's for the next year.
    if (prospectiveDate.isBefore(now.subtract(const Duration(days: 7)))) {
      year++;
      prospectiveDate = formatter.parse('$datePart$year');
    }

    return prospectiveDate;

  } catch (e) {
    print('Could not parse extracted date from: "$dateString". Error: $e');
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
  final List<String> searchKeywords;
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
    required this.searchKeywords,
    this.availableFrom,
    this.sonderkondition,
  });

  factory Product.fromJson(String id, Map<String, dynamic> data) {
    final keywordsData = data['searchKeywords'] as List<dynamic>?;
    final keywords = keywordsData?.map((e) => e.toString()).toList() ?? [];

    // This now calls the new, robust parsing function
    final availableFromDate = _parseGermanDateString(data['available_from'] as String?);

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
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';


/// Defines the exact order in which category groups should be displayed in the UI.
/// --- "Getränke" has been moved to its new position. ---
const List<String> categoryDisplayOrder = [
  'Brot & Backwaren',
  'Fisch & Fleisch',
  'Früchte & Gemüse',
  'Getränke',
  'Milchprodukte & Eier',
  'Salzige Snacks & Süsswaren',
  'Spezifische Ernährung',
  'Vorräte',
  'Sonstiges',
];

/// A data class to hold a group's style and its list of products.
/// Using a class is cleaner than using MapEntry.
class ProductGroup {
  final CategoryStyle style;
  final List<Product> products;
  ProductGroup({required this.style, required this.products});
}

/// This provider takes the flat list of products and transforms it into a
/// list of structured, sorted groups ready for the UI.
final groupedProductsProvider = Provider.autoDispose<List<ProductGroup>>((ref) {
  // 1. Watch the filtered list directly. It's now a List<Product>, not AsyncValue.
  final products = ref.watch(filteredProductsProvider);

  // 2. Handle the loading and error states from the source provider.
  // If the source is loading or has an error, we pass that state right through.
  if (products.isEmpty) {
    return [];
  }

  final groupedByDisplayName = groupBy(
    products,
        (Product product) => categoryStyles[product.category]?.displayName ?? defaultCategoryStyle.displayName,
  );

  final sortedGroups = <ProductGroup>[];
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!;
      final style = categoryStyles[productList.first.category] ?? defaultCategoryStyle;
      sortedGroups.add(ProductGroup(style: style, products: productList));
    }
  }

  return sortedGroups;
});
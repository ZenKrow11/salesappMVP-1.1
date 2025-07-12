import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- 1. IMPORT our new service and data models ---
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/products_provider.dart';

/// Defines the exact order in which category groups should be displayed in the UI.
/// This list remains important for controlling the visual order.
const List<String> categoryDisplayOrder = [
  'Brot & Backwaren',
  'Fisch & Fleisch',
  'Früchte & Gemüse',
  'Getränke', // Both alcoholic and non-alcoholic will group here.
  'Milchprodukte & Eier',
  'Snacks & Süsswaren',
  'Spezifische Ernährung',
  'Vorräte',
  'Sonstiges',
];

/// A data class to hold a group's style and its list of products.
/// This class remains unchanged and is perfect for our needs.
class ProductGroup {
  final CategoryStyle style;
  final List<Product> products;
  ProductGroup({required this.style, required this.products});
}

/// This provider takes the flat list of products and transforms it into a
/// list of structured, sorted groups ready for the UI.
final groupedProductsProvider = Provider.autoDispose<List<ProductGroup>>((ref) {
  // Watch the filtered list of products.
  final products = ref.watch(filteredProductsProvider);

  if (products.isEmpty) {
    return [];
  }

  // --- 2. UPDATE the grouping logic to use the CategoryService ---
  // We now group products by the `displayName` provided by our intelligent service.
  // This correctly maps both 'Alkoholische Getränke' and 'Bier' to the 'Getränke' group.
  final groupedByDisplayName = groupBy(
    products,
        (Product product) => CategoryService.getStyleForCategory(product.category).displayName,
  );

  final sortedGroups = <ProductGroup>[];
  for (final displayName in categoryDisplayOrder) {
    if (groupedByDisplayName.containsKey(displayName)) {
      final productList = groupedByDisplayName[displayName]!;

      // --- 3. UPDATE style lookup to also use the CategoryService ---
      // We get the style from the first product in the list. The service ensures
      // we get the correct parent style, regardless of whether the product's
      // category is a main or subcategory.
      final style = CategoryService.getStyleForCategory(productList.first.category);

      sortedGroups.add(ProductGroup(style: style, products: productList));
    }
  }

  return sortedGroups;
});
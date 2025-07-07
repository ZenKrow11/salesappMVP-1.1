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
final groupedProductsProvider = Provider.autoDispose<AsyncValue<List<ProductGroup>>>((ref) {
  // 1. Watch the source provider that gives us the filtered list from Firestore.
  final asyncProducts = ref.watch(filteredProductsProvider);

  // 2. Handle the loading and error states from the source provider.
  // If the source is loading or has an error, we pass that state right through.
  return asyncProducts.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (products) {
      // 3. This is the success case, where we have a list of products.
      if (products.isEmpty) {
        // If there are no products, return an empty list of groups.
        return const AsyncValue.data([]);
      }

      // 4. GROUP THE PRODUCTS
      // We use the powerful `groupBy` from the collection package.
      // It creates a Map where the key is the result of the function (our display name)
      // and the value is a list of all products that produced that key.
      final groupedByDisplayName = groupBy(
        products,
            (Product product) {
          // For each product, find its style and return the displayName.
          // This is how "Alkoholische Getränke" becomes "Getränke".
          return categoryStyles[product.category]?.displayName ?? defaultCategoryStyle.displayName;
        },
      );

      // 5. SORT THE GROUPS
      // The map from groupBy is unordered. We now create a sorted list.
      final sortedGroups = <ProductGroup>[];
      for (final displayName in categoryDisplayOrder) {
        // Check if our grouped map actually contains products for this category.
        if (groupedByDisplayName.containsKey(displayName)) {
          final productList = groupedByDisplayName[displayName]!;
          // Find the style for this group. We can safely get it from the
          // first product in the list, as all products in this group share a style.
          final style = categoryStyles[productList.first.category] ?? defaultCategoryStyle;

          sortedGroups.add(ProductGroup(style: style, products: productList));
        }
      }

      // 6. Return the final, structured, and sorted list of groups.
      return AsyncValue.data(sortedGroups);
    },
  );
});
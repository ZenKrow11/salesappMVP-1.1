// lib/models/list_item.dart

import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart'; // Add this import

/// A sealed class to represent the different types of items that can appear
/// in our home page grid. This ensures at compile time that we handle all
/// possible item types in our UI code.
sealed class ListItem {}

/// Represents a product in the list. It holds the actual product data.
class ProductListItem extends ListItem {
  final PlainProduct product;
  ProductListItem(this.product);
}

/// A simple marker class to represent that an ad should be shown at this position.
class AdListItem extends ListItem {}

/// Represents a group header in the list (e.g., "Beverages").
class HeaderListItem extends ListItem {
  final ProductGroup group;
  HeaderListItem(this.group);
}

/// Represents a "Show More" button for a specific group.
class ShowMoreListItem extends ListItem {
  final ProductGroup group;
  ShowMoreListItem(this.group);
}
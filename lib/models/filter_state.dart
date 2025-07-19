// lib/models/filter_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_state.freezed.dart';

enum SortOption {
  storeAlphabetical,
  productAlphabetical,
  discountHighToLow,
  discountLowToHigh,
  priceLowToHigh,
  priceHighToLow,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.storeAlphabetical:
        return 'Store: A-Z';
      case SortOption.productAlphabetical:
        return 'Product: A-Z';
      case SortOption.discountHighToLow:
        return 'Discount: High-Low';
      case SortOption.discountLowToHigh:
        return 'Discount: Low-High';
      case SortOption.priceHighToLow:
        return 'Price: High-Low';
      case SortOption.priceLowToHigh:
        return 'Price: Low-High';
    }
  }
}

@freezed
class FilterState with _$FilterState {
  const factory FilterState({
    @Default('') String searchQuery,
    @Default([]) List<String> selectedStores,
    @Default([]) List<String> selectedCategories,
    @Default([]) List<String> selectedSubcategories,
    @Default(SortOption.storeAlphabetical) SortOption sortOption,
  }) = _FilterState;

  // Optional: Keep this only if you define custom methods (not needed here)
  const FilterState._();
}

// ✅ Extension for derived logic like `isDefault`
extension FilterStateX on FilterState {
  bool get isDefault =>
      selectedStores.isEmpty &&
          selectedCategories.isEmpty &&
          selectedSubcategories.isEmpty &&
          searchQuery.isEmpty &&
          sortOption == SortOption.storeAlphabetical;
}

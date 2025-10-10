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
      case SortOption.discountHighToLow:
        return 'Discount: High-Low';
      case SortOption.discountLowToHigh:
        return 'Discount: Low-High';
      case SortOption.priceLowToHigh:
        return 'Price: Low-High';
      case SortOption.priceHighToLow:
        return 'Price: High-Low';
      case SortOption.storeAlphabetical:
        return 'Store: A-Z';
      case SortOption.productAlphabetical:
        return 'Product: A-Z';
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
    @Default(SortOption.discountHighToLow) SortOption sortOption,
  }) = _FilterState;

  // Private constructor to allow for custom getters
  const FilterState._();

  // --- GETTERS THAT WERE MISSING ---
  bool get isSearchActive => searchQuery.isNotEmpty;
  bool get isFilterActive =>
      selectedStores.isNotEmpty ||
          selectedCategories.isNotEmpty ||
          selectedSubcategories.isNotEmpty;

  // Also including isDefault, as other parts of the app need it
  bool get isDefault =>
      !isSearchActive &&
          !isFilterActive &&
          sortOption == SortOption.storeAlphabetical;

  bool get isFilterActiveForShoppingList =>
      selectedStores.isNotEmpty || selectedCategories.isNotEmpty;
}
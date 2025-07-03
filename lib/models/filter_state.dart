import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_state.freezed.dart';

// THIS is the enum you need to modify.
enum SortOption {
  // Add all the options you need here
  storeAlphabetical,
  productAlphabetical,
  discountHighToLow,
  discountLowToHigh,
  priceLowToHigh,
  priceHighToLow,
  // Add new options like date sorting
  // dateAddedNewest,
  // dateAddedOldest,
}

@freezed
class FilterState with _$FilterState {
  const factory FilterState({
    @Default('') String searchQuery,
    @Default([]) List<String> selectedStores,
    @Default([]) List<String> selectedCategories,
    @Default([]) List<String> selectedSubcategories,
    // Change the default to a more sensible option
    @Default(SortOption.storeAlphabetical) SortOption sortOption,
  }) = _FilterState;
}
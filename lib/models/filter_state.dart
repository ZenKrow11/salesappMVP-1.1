// lib/models/filter_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_state.freezed.dart'; // This file will be generated

// This enum defines the available sorting options for your products.
enum SortOption { alphabetical, priceLowToHigh, discountHighToLow }

// This is the data class that holds all filter and sort information.
@freezed
class FilterState with _$FilterState {
  const factory FilterState({
    @Default('') String searchQuery,
    @Default([]) List<String> selectedStores,
    @Default([]) List<String> selectedCategories,
    @Default([]) List<String> selectedSubcategories,
    @Default(SortOption.alphabetical) SortOption sortOption,
  }) = _FilterState;
}
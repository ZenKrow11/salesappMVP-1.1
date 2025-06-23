import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortOption {
  alphabeticalStore,
  alphabetical,
  priceLowToHigh,
  discountHighToLow,
}

final sortOptionProvider = StateProvider<SortOption>((ref) {
  return SortOption.alphabeticalStore;
});

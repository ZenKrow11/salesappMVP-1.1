import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_mode_provider.freezed.dart';

// 1. Define the state object using Freezed for immutability
@freezed
class ShoppingModeState with _$ShoppingModeState {
  const factory ShoppingModeState({
    @Default({}) Map<String, int> productQuantities,
    @Default({}) Set<String> checkedProductIds,
  }) = _ShoppingModeState;
}

// 2. Create the Notifier to manage the state
class ShoppingModeNotifier extends StateNotifier<ShoppingModeState> {
  ShoppingModeNotifier() : super(const ShoppingModeState());

  void toggleChecked(String productId) {
    final newCheckedIds = Set<String>.from(state.checkedProductIds);
    if (newCheckedIds.contains(productId)) {
      newCheckedIds.remove(productId);
    } else {
      newCheckedIds.add(productId);
    }
    state = state.copyWith(checkedProductIds: newCheckedIds);
  }

  void incrementQuantity(String productId) {
    final newQuantities = Map<String, int>.from(state.productQuantities);
    newQuantities[productId] = (newQuantities[productId] ?? 1) + 1;
    state = state.copyWith(productQuantities: newQuantities);
  }

  void decrementQuantity(String productId) {
    final newQuantities = Map<String, int>.from(state.productQuantities);
    if ((newQuantities[productId] ?? 1) > 1) {
      newQuantities[productId] = newQuantities[productId]! - 1;
      state = state.copyWith(productQuantities: newQuantities);
    }
  }

  void clearChecks() {
    state = state.copyWith(checkedProductIds: {});
  }

  // Resets the entire state to its initial condition
  void resetState() {
    state = const ShoppingModeState();
  }
}

// 3. Define the global provider
final shoppingModeProvider = StateNotifierProvider.autoDispose<ShoppingModeNotifier, ShoppingModeState>(
      (ref) => ShoppingModeNotifier(),
);
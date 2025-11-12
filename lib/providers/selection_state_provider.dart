// lib/providers/selection_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selection_state_provider.freezed.dart';

@freezed
class SelectionState with _$SelectionState {
  const factory SelectionState({
    @Default(false) bool isSelectionModeActive,
    @Default(<String>{}) Set<String> selectedItemIds,
  }) = _SelectionState;
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void enableSelectionMode(String initialItemId) {
    state = state.copyWith(
      isSelectionModeActive: true,
      selectedItemIds: {initialItemId},
    );
  }

  void disableSelectionMode() {
    state = state.copyWith(
      isSelectionModeActive: false,
      selectedItemIds: {},
    );
  }

  void toggleItem(String itemId) {
    if (!state.isSelectionModeActive) return;

    final newSet = Set<String>.from(state.selectedItemIds);
    if (newSet.contains(itemId)) {
      newSet.remove(itemId);
    } else {
      newSet.add(itemId);
    }

    // If the last item is deselected, turn off selection mode
    if (newSet.isEmpty) {
      disableSelectionMode();
    } else {
      state = state.copyWith(selectedItemIds: newSet);
    }
  }
}

final selectionStateProvider = StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
  return SelectionNotifier();
});
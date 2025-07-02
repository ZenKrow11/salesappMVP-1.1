// lib/providers/filter_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart'; // Import the model from its new file

// This provider's only job is to hold the current state of the filters.
// It has no other logic.
final filterStateProvider = StateProvider<FilterState>((ref) {
  return const FilterState();
});
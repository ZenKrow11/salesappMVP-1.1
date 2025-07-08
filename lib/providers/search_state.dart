import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This provider holds the text that is *actually being used to filter* the products.
/// It is only updated when the user explicitly performs a search.
final committedSearchQueryProvider = StateProvider<String>((ref) => '');

/// This provider is a placeholder. Your SearchBarWidget will manage its own text controller.
/// We are keeping it simple by removing the old searchQueryProvider.
/// If you need other parts of the UI to react to live typing, we can re-introduce a
/// live query provider later.
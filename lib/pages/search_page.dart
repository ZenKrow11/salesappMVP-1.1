// lib/pages/search_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(homePageFilterStateProvider).searchQuery;
    _textController.text = initialQuery;

    _textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.refresh(searchSuggestionsProvider(_textController.text));
        }
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onApply(String query) {
    ref.read(homePageFilterStateProvider.notifier)
        .update((state) => state.copyWith(searchQuery: query.trim()));
    if (mounted) Navigator.pop(context);
  }

  void _clearSearch() {
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final suggestions = ref.watch(searchSuggestionsProvider(_textController.text));

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        title: Text(l10n.searchProducts, style: TextStyle(color: theme.secondary)),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: theme.secondary, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            Expanded(
              child: suggestions.when(
                data: (suggestionList) {
                  if (_textController.text.isNotEmpty && suggestionList.isEmpty) {
                    return Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(color: theme.inactive.withOpacity(0.7)),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: suggestionList.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestionList[index];
                      return ListTile(
                        title: Text(suggestion, style: TextStyle(color: theme.inactive)),
                        onTap: () => _onApply(suggestion),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: theme.accent))),
              ),
            ),
            _buildSearchBar(theme, l10n),
          ],
        ),
      ),
    );
  }

  // === THIS WIDGET CONTAINS THE FIX ===
  Widget _buildSearchBar(AppThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                onSubmitted: _onApply,
                style: TextStyle(color: theme.secondary),
                decoration: InputDecoration(
                  hintText: l10n.searchProductsHint,
                  hintStyle: TextStyle(color: theme.inactive),
                  prefixIcon: Icon(Icons.search, color: theme.secondary),
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.backspace, color: theme.secondary),
                    onPressed: _clearSearch,
                  )
                      : null,
                  filled: true,
                  fillColor: theme.inactive.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // The ElevatedButton is now a direct child of the Row.
            // Its size is controlled by its own style properties.
            ElevatedButton(
              onPressed: () => _onApply(_textController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Match the TextField's border radius
                ),
                // Use fixedSize to create a perfect square.
                // You can adjust the value (e.g., 56) to get the exact size you want.
                fixedSize: const Size(56, 56),
                padding: EdgeInsets.zero, // Remove padding to center the icon
              ),
              child: Icon(
                Icons.arrow_forward,
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
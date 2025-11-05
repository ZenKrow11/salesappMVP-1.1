// lib/components/search_bottom_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SearchBottomSheet extends ConsumerStatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  ConsumerState<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends ConsumerState<SearchBottomSheet> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialQuery = ref
        .read(homePageFilterStateProvider)
        .searchQuery;
    _textController.text = initialQuery;
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
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
    final showClearButton = _textController.text.isNotEmpty;
    final suggestions = ref.watch(searchSuggestionsProvider(_textController.text));

    // The Padding and Container are replaced by a Scaffold.
    // This gives the bottom sheet a solid background and respects the top safe area.
    return Scaffold(
      backgroundColor: theme.background,
      // The body is now wrapped in a SafeArea that respects BOTH top and bottom
      body: SafeArea(
        // --- FIX #1: Tell the SafeArea to also avoid the top status bar ---
        top: true,
        left: false,
        right: false,
        child: Padding(
          // --- FIX #2: Remove the hardcoded top padding ---
          // Let the SafeArea handle the top space dynamically.
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            children: [
              // Add a little space for aesthetics that was previously in the Padding
              const SizedBox(height: 20),
              _buildHeader(theme, l10n),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                autofocus: true,
                onSubmitted: _onApply,
                style: TextStyle(color: theme.secondary),
                decoration: InputDecoration(
                  hintText: l10n.searchProductsHint,
                  hintStyle: TextStyle(color: theme.inactive),
                  prefixIcon: Icon(Icons.search, color: theme.secondary),
                  suffixIcon: showClearButton
                      ? IconButton(
                    icon: Icon(Icons.backspace, color: theme.accent),
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
              const SizedBox(height: 10),
              Expanded(
                child: suggestions.when(
                  data: (suggestionList) {
                    if (suggestionList.isEmpty) {
                      return const SizedBox.shrink();
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
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
              // The action bar remains the same, but it's now inside the Scaffold's body.
              _buildActionBar(theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.searchProducts,
          style: TextStyle(
            fontSize: 20,
            color: theme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// Builds the action bar with "Cancel" and "Apply" buttons.
  Widget _buildActionBar(AppThemeData theme, AppLocalizations l10n) {
    // --- THIS IS THE FIX ---
    // Wrap the entire bar in a SafeArea, but only for the bottom.
    // This ensures it always stays above the keyboard.
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.inactive),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context), // Just close the sheet
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: theme.inactive,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _onApply(_textController.text),
                child: Text(
                  l10n.apply,
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
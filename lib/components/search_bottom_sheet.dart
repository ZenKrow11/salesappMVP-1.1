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
    final initialQuery = ref.read(homePageFilterStateProvider).searchQuery;
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        // Allow the sheet to be taller to fit content
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            // --- FIX: The Column now expands to fill the available space ---
            child: Column(
              children: [
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
                      icon: Icon(Icons.clear, color: theme.accent),
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
                // --- FIX: The suggestions list is now wrapped in Expanded ---
                // This makes it take up the available space and become scrollable.
                Expanded(
                  child: suggestions.when(
                    data: (suggestionList) {
                      // We don't need to show a message, just an empty space
                      // if there are no suggestions.
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
                // This action bar will now be "pushed" to the bottom by the Expanded widget above.
                _buildActionBar(theme, l10n),
              ],
            ),
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
    return Padding(
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
    );
  }
}
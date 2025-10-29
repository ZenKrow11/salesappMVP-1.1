// lib/widgets/search_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/search_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- ADDED IMPORT ---
import 'package:sales_app_mvp/generated/app_localizations.dart';

class SearchButton extends ConsumerWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- GET LOCALIZATIONS ---
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final isSearchActive = ref.watch(homePageFilterStateProvider.select((s) => s.isSearchActive));

    return ElevatedButton.icon(
      icon: Icon(Icons.search, color: theme.secondary, size: 22.0),
      label: Row(
        children: [
          Expanded(
            child: Text(
              // --- USE LOCALIZED STRING ---
              l10n.search,
              style: TextStyle(color: theme.inactive),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSearchActive)
            _ClearButton(
              onPressed: () {
                ref.read(homePageFilterStateProvider.notifier).update((state) => state.copyWith(searchQuery: ''));
              },
            ),
        ],
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const SearchBottomSheet(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.background.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}

// Helper widget for the clear button (No text, so no changes needed)
class _ClearButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ClearButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.close, color: theme.inactive, size: 16),
      ),
    );
  }
}
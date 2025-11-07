// lib/components/sort_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

extension SortOptionLocalization on SortOption {
  String getLocalizedDisplayName(AppLocalizations l10n) {
    switch (this) {
      case SortOption.priceLowToHigh:
        return l10n.sortPriceLowToHigh;
      case SortOption.priceHighToLow:
        return l10n.sortPriceHighToLow;
      case SortOption.discountLowToHigh:
        return l10n.sortDiscountLowToHigh;
      case SortOption.discountHighToLow:
        return l10n.sortDiscountHighToLow;
      case SortOption.productAlphabetical:
        return l10n.sortProductAZ;
      case SortOption.storeAlphabetical:
        return l10n.sortStoreAZ;
    }
  }
}

class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterNotifier = ref.read(homePageFilterStateProvider.notifier);
    final currentSortOption = ref.watch(homePageFilterStateProvider).sortOption;
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    // --- THIS IS THE FIX ---
    // Create a list with your desired display order.
    const List<SortOption> displayOrder = [
      SortOption.discountHighToLow,
      SortOption.discountLowToHigh,
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
      SortOption.storeAlphabetical,
      SortOption.productAlphabetical,
    ];
    // --- END OF FIX ---

    return Container(
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.sortBy,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.secondary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.accent),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  // --- CHANGE: Iterate over your new ordered list ---
                  ...displayOrder.map((option) {
                    final bool isSelected = option == currentSortOption;

                    return Card(
                      elevation: 0,
                      color: isSelected ? theme.secondary : theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          option.getLocalizedDisplayName(l10n),
                          style: TextStyle(
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.primary : theme.inactive,
                          ),
                        ),
                        onTap: () {
                          filterNotifier.update(
                                  (state) => state.copyWith(sortOption: option));
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ));
  }
}
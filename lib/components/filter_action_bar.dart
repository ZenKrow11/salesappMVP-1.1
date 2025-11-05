// lib/components/filter_action_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/widgets/app_theme.dart';

class FilterActionBar extends ConsumerWidget {
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool isLoading;

  const FilterActionBar({
    super.key,
    required this.onReset,
    required this.onApply,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        // Adjust padding slightly to account for SafeArea
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                onPressed: onReset,
                child: Text(
                  l10n.reset,
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
                onPressed: isLoading ? null : onApply,
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
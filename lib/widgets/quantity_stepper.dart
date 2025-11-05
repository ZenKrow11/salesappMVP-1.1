// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';

class QuantityStepper extends ConsumerWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    // --- NEW MODERNIZED LAYOUT ---
    // The stepper is now just two large, distinct buttons.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // DECREMENT BUTTON
        Expanded(
          child: OutlinedButton(
            onPressed: quantity > 1 ? onDecrement : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Icon(Icons.remove, color: theme.accent, size: 28),
          ),
        ),

        const SizedBox(width: 16),

        // INCREMENT BUTTON
        Expanded(
          child: OutlinedButton(
            onPressed: onIncrement,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.secondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Icon(Icons.add, color: theme.secondary, size: 28),
          ),
        ),
      ],
    );
  }
}
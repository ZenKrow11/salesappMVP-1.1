// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

class QuantityStepper extends ConsumerWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  // The generic 'color' property is removed to use specific theme colors.

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // 2. GET A REFERENCE TO THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          // Changed color to use theme.inactive for the minus button
          icon: Icon(Icons.remove_circle_outline, color: theme.accent),
          onPressed: quantity > 1 ? onDecrement : null,
          // 3. USE THE LOCALIZED TOOLTIP
          tooltip: l10n.decreaseQuantity,
          splashRadius: 20,
        ),
        Text(
          quantity.toString(),
          // Changed text color to secondary to match the theme from the image
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: theme.secondary),
        ),
        IconButton(
          // Changed color to use theme.secondary for the add button
          icon: Icon(Icons.add_circle_outline, color: theme.secondary),
          onPressed: onIncrement,
          // 4. USE THE LOCALIZED TOOLTIP
          tooltip: l10n.increaseQuantity,
          splashRadius: 20,
        ),
      ],
    );
  }
}
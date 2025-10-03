// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color? color;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 2. GET A REFERENCE TO THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: color),
          onPressed: quantity > 1 ? onDecrement : null,
          // 3. USE THE LOCALIZED TOOLTIP
          tooltip: l10n.decreaseQuantity,
          splashRadius: 20,
        ),
        Text(
          quantity.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: color),
          onPressed: onIncrement,
          // 4. USE THE LOCALIZED TOOLTIP
          tooltip: l10n.increaseQuantity,
          splashRadius: 20,
        ),
      ],
    );
  }
}
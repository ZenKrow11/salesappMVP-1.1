// lib/components/shopping_mode_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
// REMOVED: No longer need to import QuantityStepper here.

class ShoppingModeListItemTile extends ConsumerWidget {
  final Product product;
  final bool isChecked;
  final VoidCallback onCheckTap;
  final VoidCallback onInfoTap; // This is now used for both quantity and info icon
  final int quantity;
  // REMOVED: onIncrement and onDecrement are no longer needed on the tile.

  const ShoppingModeListItemTile({
    super.key,
    required this.product,
    required this.isChecked,
    required this.onCheckTap,
    required this.onInfoTap,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return InkWell(
      onTap: onCheckTap, // Tapping anywhere on the tile still checks it
      child: Opacity(
        opacity: isChecked ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // --- NEW: Tappable Quantity Display ---
              // Wrapped in an InkWell to make it a button that opens the info dialog.
              InkWell(
                onTap: onInfoTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  // Fixed width ensures all titles align perfectly in the list.
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '${quantity}x',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // [Product Title]
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(
                    color: theme.inactive,
                    fontSize: 16,
                    decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // [ info ]
              IconButton(
                icon: Icon(Icons.info_outline, color: theme.inactive),
                onPressed: onInfoTap, // Also triggers the info dialog
                tooltip: 'View details',
                splashRadius: 24,
              ),

              // [ checkmark ]
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? theme.secondary : theme.inactive,
                size: 26,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/components/shopping_mode_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ShoppingModeListItemTile extends ConsumerWidget {
  final Product product;
  final bool isChecked;
  final int quantity;
  final VoidCallback onCheckTap;
  final VoidCallback onInfoTap;

  const ShoppingModeListItemTile({
    super.key,
    required this.product,
    required this.isChecked,
    required this.quantity,
    required this.onCheckTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final textStyle = TextStyle(
      color: theme.inactive,
      fontSize: 16,
      decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: theme.inactive, // Ensures line-through is visible
      decorationThickness: 2.0,
    );

    return InkWell(
      onTap: onCheckTap, // Tapping anywhere on the tile checks it
      child: Opacity(
        opacity: isChecked ? 0.5 : 1.0, // Fades out the entire tile when checked
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Tappable Quantity Display ---
              InkWell(
                onTap: onInfoTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40, // Fixed width ensures alignment
                  alignment: Alignment.center,
                  child: Text(
                    '${quantity}x',
                    style: TextStyle(
                      color: isChecked ? theme.secondary.withOpacity(0.8) : theme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // --- Product Title ---
              Expanded(
                child: Text(
                  product.name,
                  style: textStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // --- Info Icon ---
              IconButton(
                icon: Icon(Icons.info_outline, color: theme.inactive.withOpacity(0.7)),
                onPressed: onInfoTap,
                tooltip: 'View details',
                splashRadius: 24,
              ),

              // --- Custom Checkbox Icon ---
              // The outer InkWell handles the tap, so this is just for display
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? theme.secondary : theme.inactive.withOpacity(0.7),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
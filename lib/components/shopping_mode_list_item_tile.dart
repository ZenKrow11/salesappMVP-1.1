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

    // --- MODIFICATION: Updated text style for better visibility ---
    final textStyle = TextStyle(
      // Unchecked items are now brighter
      color: isChecked ? theme.inactive : Colors.white,
      fontSize: 16,
      decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
      // Strikethrough color is now the theme's secondary color
      decorationColor: theme.secondary,
      decorationThickness: 2.0,
    );

    return InkWell(
      onTap: onCheckTap, // This correctly handles the tap for the whole tile
      child: Opacity(
        opacity: isChecked ? 0.6 : 1.0, // Fades the tile slightly when checked
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
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${quantity}x',
                    style: TextStyle(
                      color: theme.secondary,
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
                icon: Icon(Icons.info_outline, color: theme.inactive.withAlpha(179)),
                onPressed: onInfoTap,
                tooltip: 'View details',
                splashRadius: 24,
              ),

              // --- MODIFICATION: The custom checkbox icon has been removed ---
            ],
          ),
        ),
      ),
    );
  }
}
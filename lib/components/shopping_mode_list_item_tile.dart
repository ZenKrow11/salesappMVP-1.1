// lib/components/shopping_mode_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ShoppingModeListItemTile extends ConsumerWidget {
  final Product product;
  final bool isChecked;
  final VoidCallback onCheckTap;
  final VoidCallback onInfoTap; // Renamed for clarity, triggered by tapping title area
  final int quantity;

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

    return Opacity(
      opacity: isChecked ? 0.5 : 1.0, // Dim the entire tile when checked
      child: Padding(
        // FIX: Reduced vertical padding from 12 to 6 to make the list more compact.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // --- NEW: Tappable Area for Info/Quantity Dialog ---
            // This InkWell covers the quantity and the title.
            Expanded(
              child: InkWell(
                onTap: onInfoTap,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    // [Quantity] - More prominent and aligned
                    Container(
                      width: 40, // Fixed width for alignment
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${quantity}x',
                        style: TextStyle(
                          color: theme.secondary, // Use highlight color
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // [Product Title]
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          color: theme.inactive,
                          fontSize: 16,
                          decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationThickness: 2.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // --- MODIFIED: Dedicated Checkbox Button ---
            // The IconButton provides a larger, more reliable tap area.
            IconButton(
              onPressed: onCheckTap,
              icon: Icon(
                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isChecked ? theme.secondary : theme.inactive.withOpacity(0.8),
                size: 28,
              ),
              splashRadius: 24,
              tooltip: isChecked ? 'Uncheck item' : 'Check item',
            ),
          ],
        ),
      ),
    );
  }
}
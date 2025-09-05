// lib/components/shopping_mode_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';

class ShoppingModeListItemTile extends ConsumerWidget {
  final Product product;
  final bool isChecked;
  final VoidCallback onTap;

  const ShoppingModeListItemTile({
    super.key,
    required this.product,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

    return Opacity(
      opacity: isChecked ? 0.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Image (unchanged)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  maxWidth: 50,
                  maxHeight: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Title (unchanged)
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
              const SizedBox(width: 16),
              // Price and Checkbox section
              SizedBox(
                // The fixed-width container is good for overall alignment.
                width: 110, // Let's give it a little more space to be safe.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // --- MODIFICATION START ---
                    // Using Expanded is the correct solution here.
                    // It forces the Text to use only the space not occupied by the other widgets in the Row.
                    Expanded(
                      child: Text(
                        '$priceString Fr.',
                        style: TextStyle(
                          color: theme.inactive,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right, // Align text to the right within its available space
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // --- MODIFICATION END ---
                    const SizedBox(width: 8), // Reduced spacer slightly
                    // The icon has a fixed size and will be laid out first.
                    Icon(
                      isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isChecked ? theme.secondary : theme.inactive,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
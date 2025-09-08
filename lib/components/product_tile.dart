// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/notification_helper.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProductTile extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  Color _darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStyle = CategoryService.getStyleForCategory(product.category);
    final Color backgroundTint = _darken(categoryStyle.color, 0.4).withOpacity(0.15);
    final theme = ref.watch(themeProvider);

    // --- THIS IS THE CRITICAL UI CHANGE ---
    // 1. Watch the new global provider to get the Set of all listed IDs.
    final listedProductIds = ref.watch(listedProductIdsProvider).value ?? {};

    // 2. The logic is now a simple, fast lookup in the Set.
    final isInShoppingList = listedProductIds.contains(product.id);
    // --- END OF CHANGE ---

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        final notifier = ref.read(shoppingListsProvider.notifier);
        final theme = ref.read(themeProvider);

        if (isInShoppingList) {
          // IMPORTANT: We now need a way to know which list to remove from.
          // For now, we'll assume removing from the active list. This is a UX decision
          // that can be refined later (e.g., by showing a dialog).
          notifier.removeItemFromList(product);
          showTopNotification(
            context,
            message: 'Removed from list', // Generic message
            theme: theme,
          );
        } else {
          // Add to the currently active list.
          notifier.addToList(product);
          showTopNotification(
            context,
            message: 'Added to active list', // Generic message
            theme: theme,
          );
        }
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.background,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          // Pass the product to the bottom sheet to add it to a specific list
          builder: (ctx) => ShoppingListBottomSheet(product: product),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundTint,
              borderRadius: BorderRadius.circular(12.0),
              border: isInShoppingList
                  ? Border.all(color: theme.secondary, width: 2.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildContent(context, ref),
              ),
            ),
          ),
          if (isInShoppingList)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: theme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1))
                    ]),
                child: Icon(
                  Icons.check,
                  color: theme.primary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The rest of the file (_buildContent, etc.) does not need any changes.
  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(context, ref),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.white,
                ),
                ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  maxHeight: double.infinity,
                  maxWidth: double.infinity,
                  fit: BoxFit.contain,
                ),
                if (product.sonderkondition != null)
                  Positioned(
                    top: 0,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        String.fromCharCode(Icons.star.codePoint),
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: Icons.star.fontFamily,
                          package: Icons.star.fontPackage,
                          color: theme.secondary,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: theme.primary,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(context, ref),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return SizedBox(
      height: 38.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StoreLogo(
            storeName: product.store,
            height: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.inactive,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${product.discountPercentage}%',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AutoSizeText(
            '${product.currentPrice.toStringAsFixed(2)} Fr.',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.inactive,
            ),
            minFontSize: 16,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
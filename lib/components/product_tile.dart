// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductTile extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  // Utility from the new script: darkens a color
  Color _darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic from the new script to determine background color
    final categoryStyle =
    CategoryService.getStyleForCategory(product.category);
    final Color backgroundTint =
    _darken(categoryStyle.color, 0.4).withOpacity(0.15);
    final theme = ref.watch(themeProvider);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        final activeListName = ref.read(activeShoppingListProvider);
        final notifier = ref.read(shoppingListsProvider.notifier);

        if (activeListName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active list. Long press to choose one.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          notifier.addToList(activeListName, product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to "$activeListName"'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: theme.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) =>
              ShoppingListBottomSheet(
                product: product,
                onConfirm: (String selectedListName) {},
              ),
        );
      },
      child: Container(
        // Decoration combines ideas from both scripts:
        // - backgroundTint from the new script for the color.
        // - A standard black shadow for better contrast on a colored background.
        decoration: BoxDecoration(
          color: backgroundTint,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            // The existing, feature-rich content structure is fully preserved.
            child: _buildContent(context, ref),
          ),
        ),
      ),
    );
  }

  // The rest of the widget's methods are from the original script and are unchanged.

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(context, ref),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  maxHeight: double.infinity,
                  maxWidth: double.infinity,
                ),
                if (product.sonderkondition != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        String.fromCharCode(Icons.star.codePoint),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: Icons.star.fontFamily,
                          package: Icons.star.fontPackage,
                          color: Colors.yellow,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(0, 0),
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
    return Row(
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
        const Spacer(),
        Text(
          '${product.currentPrice.toStringAsFixed(2)} Fr.',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.inactive,
          ),
        ),
      ],
    );
  }
}
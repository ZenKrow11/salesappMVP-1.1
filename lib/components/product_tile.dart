// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/named_list.dart';
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
    final Color backgroundTint = _darken(categoryStyle.color, 0.4).withOpacity(
        0.15);
    final theme = ref.watch(themeProvider);

    final allLists = ref.watch(shoppingListsProvider);
    final isInShoppingList = allLists.any((list) =>
        list.items.any((item) => item.id == product.id));

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        final activeListName = ref.read(activeShoppingListProvider);
        final notifier = ref.read(shoppingListsProvider.notifier);
        final theme = ref.read(themeProvider);

        final targetListName = activeListName ?? merklisteListName;

        final allLists = ref.read(shoppingListsProvider);
        final targetList = allLists.firstWhere(
              (list) => list.name == targetListName,
          orElse: () => NamedList(name: '', items: [], index: -1),
        );

        if (targetList.name.isEmpty) {
          showModalBottomSheet(
            context: context,
            // --- THIS IS THE FIX ---
            isScrollControlled: true,
            backgroundColor: theme.background,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => const ShoppingListBottomSheet(),
          );
          return;
        }

        final isItemInList = targetList.items.any((item) => item.id == product.id);

        if (isItemInList) {
          notifier.removeItemFromList(targetListName, product);
          showTopNotification(
            context,
            message: 'Removed ${product.name} from "$targetListName"',
            theme: theme,
          );
        } else {
          notifier.addToList(targetListName, product);
          showTopNotification(
            context,
            message: 'Added ${product.name} to "$targetListName"',
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
          builder: (ctx) => const ShoppingListBottomSheet(),
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
        // 1. The discount percentage widget, which you correctly noted was missing.
        Text(
          '${product.discountPercentage}%',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        // Adds a nice space between the two elements

        // 2. The adaptive price widget, which will take up the rest of the space.
        Expanded(
          child: AutoSizeText(
            '${product.currentPrice.toStringAsFixed(2)} Fr.',
            style: GoogleFonts.montserrat(
              fontSize: 24, // This is the maximum font size
              fontWeight: FontWeight.bold,
              color: theme.inactive,
            ),
            minFontSize: 16, // It will not shrink smaller than this
            maxLines: 1,
            textAlign: TextAlign.right, // Aligns the text to the right
          ),
        ),
      ],
    );
  }
}
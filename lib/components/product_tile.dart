// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/pages/manage_shopping_list.dart';
import 'package:sales_app_mvp/services/notification_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sales_app_mvp/models/categorizable.dart';
import 'package:sales_app_mvp/widgets/slide_in_page_route.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';


class ProductTile extends ConsumerWidget {
  final PlainProduct product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  void _navigateToAddToListPage(
      BuildContext context, WidgetRef ref, Product product) async {
    final l10n = AppLocalizations.of(context)!;

    final selectedListName =
    await Navigator.of(context, rootNavigator: true).push<String>(
      SlidePageRoute(
        page: ManageShoppingListsPage(product: product),
        direction: SlideDirection.rightToLeft,
      ),
    );

    if (selectedListName != null && context.mounted) {
      NotificationManager.show(
        context,
        l10n.itemAddedToList(product.name, selectedListName),
      );
    }
  }

  Color _darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categorizableProduct = product as Categorizable;
    final categoryStyle =
    CategoryService.getStyleForCategory(categorizableProduct.category);
    final Color backgroundBase = HSLColor.fromColor(categoryStyle.color).withLightness(0.15).toColor();
    final Color backgroundTint = backgroundBase.withAlpha((255 * 0.15).round());
    final theme = ref.watch(themeProvider);
    final listedProductIds = ref.watch(listedProductIdsProvider).value ?? {};
    final isInShoppingList = listedProductIds.contains(product.id);

    Product createHiveProduct() {
      return Product(
          id: product.id,
          store: product.store,
          name: product.name,
          currentPrice: product.currentPrice,
          normalPrice: product.normalPrice,
          discountPercentage: product.discountPercentage,
          category: product.category.isEmpty
              ? 'categoryUncategorized'
              : product.category,
          subcategory: product.subcategory,
          url: product.url,
          imageUrl: product.imageUrl,
          nameTokens: product.nameTokens,
          dealStart: product.dealStart,
          specialCondition: product.specialCondition,
          dealEnd: product.dealEnd,
          isCustom: product.isCustom,
          isOnSale: product.isOnSale);
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        final notifier = ref.read(shoppingListsProvider.notifier);
        final hiveProduct = createHiveProduct();

        if (isInShoppingList) {
          // --- FIX: Method call no longer needs context ---
          notifier.removeItemFromList(hiveProduct);
          NotificationManager.show(context, l10n.removedFromList);
          return;
        }

        final activeListId = ref.read(activeShoppingListProvider);
        if (activeListId == null) {
          NotificationManager.show(context, "Please create a shopping list first.");
          return;
        }

        // --- FIX: Method call no longer needs context ---
        notifier.addToList(hiveProduct);

        final allLists = ref.read(allShoppingListsProvider).valueOrNull ?? [];
        final activeList = allLists.firstWhere(
              (list) => list.id == activeListId,
          orElse: () => ShoppingListInfo(id: '', name: l10n.yourList, itemCount: 0),
        );
        NotificationManager.show(
            context, l10n.itemAddedToList(hiveProduct.name, activeList.name));
      },
      onLongPress: () {
        final hiveProduct = createHiveProduct();
        _navigateToAddToListPage(context, ref, hiveProduct);
      },
      child: Container(
        // ... rest of the widget is unchanged
        decoration: BoxDecoration(
          color: backgroundTint,
          borderRadius: BorderRadius.circular(12.0),
          border: isInShoppingList
              ? Border.all(color: theme.secondary, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000), // Colors.black.withOpacity(0.2)
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContent(context, ref, l10n, isInShoppingList),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, bool isInShoppingList) {
    // ... This method is unchanged
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
                if (product.specialCondition != null)
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
                          color: ref.watch(themeProvider).secondary,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: ref.watch(themeProvider).primary,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
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
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0x80000000), // Colors.black.withOpacity(0.5)
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
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(context, ref, l10n),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref) {
    // ... This method is unchanged
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

  Widget _buildPriceRow(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    // ... This method is unchanged
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
            '${product.currentPrice.toStringAsFixed(2)} ${l10n.currencyFrancs}',
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
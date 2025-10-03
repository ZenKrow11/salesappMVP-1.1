// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

class ShoppingListItemTile extends ConsumerWidget {
  final Product product;
  final List<Product> allProductsInList;
  final bool isGridView;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGridView) {
      return _buildGridTile(context, ref);
    } else {
      return GestureDetector(
        onTap: () => _onTap(context),
        onDoubleTap: () => _onDoubleTap(context, ref),
        child: _buildListTile(context, ref),
      );
    }
  }

  void _onTap(BuildContext context) {
    final initialIndex = allProductsInList.indexWhere((p) => p.id == product.id);
    if (initialIndex != -1) {
      final plainProducts = allProductsInList.map((p) => p.toPlainObject()).toList();
      Navigator.of(context).push(SlideUpPageRoute(
        page: ProductSwiperScreen(
          products: plainProducts,
          initialIndex: initialIndex,
        ),
      ));
    }
  }

  void _onDoubleTap(BuildContext context, WidgetRef ref) {
    // 2. GET THE LOCALIZATIONS OBJECT FOR THE NOTIFICATION
    final l10n = AppLocalizations.of(context)!;
    ref.read(shoppingListsProvider.notifier).removeItemFromList(product);
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // 3. USE THE PARAMETERIZED LOCALIZED STRING
          content: Text(l10n.removedItem(product.name)),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Widget _buildGridTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);
    final nameTextStyle = TextStyle(
      color: theme.inactive,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      height: 1.3,
    );
    final double twoLineTextHeight =
        nameTextStyle.fontSize! * nameTextStyle.height! * 2;
    // GET LOCALIZATIONS FOR THE TILE UI
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: theme.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => _onTap(context),
        onDoubleTap: () => _onDoubleTap(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                child: ImageWithAspectRatio(
                  imageUrl: product.imageUrl ?? '',
                  fit: BoxFit.contain,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: twoLineTextHeight,
                    alignment: Alignment.topLeft,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameTextStyle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StoreLogo(storeName: product.store, height: 18),
                      Text(
                        // 4. USE THE LOCALIZED CURRENCY SYMBOL
                        '$priceString ${l10n.currencyFrancs}',
                        style: TextStyle(
                          color: theme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);
    // GET LOCALIZATIONS FOR THE TILE UI
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageWithAspectRatio(
                imageUrl: product.imageUrl ?? '',
                fit: BoxFit.cover,
                maxWidth: 70,
                maxHeight: 70,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                color: theme.inactive,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StoreLogo(storeName: product.store, height: 24),
              const SizedBox(height: 8),
              Text(
                // USE THE LOCALIZED CURRENCY SYMBOL
                '$priceString ${l10n.currencyFrancs}',
                style: TextStyle(
                  color: theme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
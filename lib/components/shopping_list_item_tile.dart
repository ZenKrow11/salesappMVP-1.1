// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_in_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'dart:math' as math;
import 'package:sales_app_mvp/services/notification_manager.dart';

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
    Widget tile;
    if (isGridView) {
      tile = _buildGridTile(context, ref);
    } else {
      tile = GestureDetector(
        onTap: () => _onTap(context),
        onDoubleTap: () => _onDoubleTap(context, ref),
        child: _buildListTile(context, ref),
      );
    }

    if (!product.isOnSale) {
      return Opacity(
        opacity: 0.6,
        child: tile,
      );
    }
    return tile;
  }

  void _onTap(BuildContext context) {
    final initialIndex =
    allProductsInList.indexWhere((p) => p.id == product.id);
    if (initialIndex != -1) {
      final plainProducts =
      allProductsInList.map((p) => p.toPlainObject()).toList();

      Navigator.of(context).push(SlidePageRoute(
        page: ProductSwiperScreen(
          products: plainProducts,
          initialIndex: initialIndex,
        ),
        direction: SlideDirection.rightToLeft,
      ));
    }
  }

  void _onDoubleTap(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(shoppingListsProvider.notifier).removeItemFromList(product);
    NotificationManager.show(context, l10n.removedItem(product.name));
  }

  Widget _buildExpiredBadge(AppLocalizations l10n) {
    return Positioned.fill(
      child: Center(
        child: Transform.rotate(
          angle: -math.pi / 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              l10n.dealExpired,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
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
    final l10n = AppLocalizations.of(context)!;

    // --- NEW: Check if the imageUrl is valid ---
    final imageUrl = product.imageUrl;
    final bool hasValidImage = imageUrl != null && imageUrl.isNotEmpty;

    return Stack(
      children: [
        Card(
          color: theme.primary,
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    // --- THIS IS THE FIX ---
                    // Conditionally show the image or a placeholder
                    child: hasValidImage
                        ? ImageWithAspectRatio(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                    )
                        : Center(
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        color: Colors.grey[300],
                        size: 40,
                      ),
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
        ),
        if (!product.isOnSale) _buildExpiredBadge(l10n),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);
    final l10n = AppLocalizations.of(context)!;

    // --- NEW: Check if the imageUrl is valid ---
    final imageUrl = product.imageUrl;
    final bool hasValidImage = imageUrl != null && imageUrl.isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Colors.white,
                    // --- THIS IS THE FIX ---
                    // Conditionally show the image or a placeholder
                    child: hasValidImage
                        ? ImageWithAspectRatio(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      maxWidth: 60,
                      maxHeight: 60,
                    )
                        : Center(
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        color: Colors.grey[300],
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(
                    color: theme.inactive,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StoreLogo(storeName: product.store, height: 22),
                  const SizedBox(height: 4),
                  Text(
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
        ),
        if (!product.isOnSale) _buildExpiredBadge(l10n),
      ],
    );
  }
}
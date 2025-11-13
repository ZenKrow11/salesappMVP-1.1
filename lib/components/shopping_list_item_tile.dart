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
import 'package:sales_app_mvp/providers/selection_state_provider.dart';

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
    final selectionState = ref.watch(selectionStateProvider);
    final isSelected = selectionState.selectedItemIds.contains(product.id);
    final theme = ref.watch(themeProvider);

    Widget tile;
    if (isGridView) {
      tile = _buildGridTile(context, ref);
    } else {
      tile = _buildListTile(context, ref);
    }

    final tileWithSelection = Stack(
      children: [
        tile,
        if (isSelected)
          Positioned.fill(
            // --- THIS IS THE FIX ---
            // Wrap the overlay in an IgnorePointer. This allows the
            // GestureDetector underneath it to receive tap events.
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isGridView ? 12 : 8),
                  // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                  color: theme.secondary.withAlpha((255 * 0.4).round()),
                ),
                child: Icon(
                  Icons.check_circle,
                  // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                  color: Colors.white.withAlpha((255 * 0.9).round()),
                  size: 36,
                ),
              ),
            ),
          ),
      ],
    );

    if (!product.isOnSale) {
      return Opacity(
        opacity: 0.6,
        child: tileWithSelection,
      );
    }
    return tileWithSelection;
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    final selectionNotifier = ref.read(selectionStateProvider.notifier);
    final isSelectionModeActive = ref.read(selectionStateProvider).isSelectionModeActive;

    if (isSelectionModeActive) {
      selectionNotifier.toggleItem(product.id);
      return;
    }

    // Original tap action
    final initialIndex = allProductsInList.indexWhere((p) => p.id == product.id);
    if (initialIndex != -1) {
      final plainProducts = allProductsInList.map((p) => p.toPlainObject()).toList();
      Navigator.of(context).push(SlidePageRoute(
        page: ProductSwiperScreen(
          products: plainProducts,
          initialIndex: initialIndex,
        ),
        direction: SlideDirection.rightToLeft,
      ));
    }
  }

  void _onLongPress(WidgetRef ref) {
    // Only enable selection mode if it's not already active
    if (!ref.read(selectionStateProvider).isSelectionModeActive) {
      ref.read(selectionStateProvider.notifier).enableSelectionMode(product.id);
    }
  }


  void _onDoubleTap(BuildContext context, WidgetRef ref) {
    if (ref.read(selectionStateProvider).isSelectionModeActive) return;

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
              // --- FIX: Replaced deprecated withOpacity with withAlpha ---
              color: Colors.red.withAlpha((255 * 0.85).round()),
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
    final double twoLineTextHeight = nameTextStyle.fontSize! * nameTextStyle.height! * 2;
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = product.imageUrl;
    // --- FIX: Removed unnecessary null check ---
    final bool hasValidImage = imageUrl.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _onTap(context, ref),
          onLongPress: () => _onLongPress(ref),
          onDoubleTap: () => _onDoubleTap(context, ref),
          child: Card(
            color: theme.primary,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
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
    final imageUrl = product.imageUrl;
    // --- FIX: Removed unnecessary null check ---
    final bool hasValidImage = imageUrl.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _onTap(context, ref),
          onLongPress: () => _onLongPress(ref),
          onDoubleTap: () => _onDoubleTap(context, ref),
          child: Container(
            color: Colors.transparent,
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
        ),
        if (!product.isOnSale) _buildExpiredBadge(l10n),
      ],
    );
  }
}
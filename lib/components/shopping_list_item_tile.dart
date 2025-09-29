// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
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
      },
      onDoubleTap: () {
        ref.read(shoppingListsProvider.notifier).removeItemFromList(product);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed "${product.name}"'),
              duration: const Duration(seconds: 1),
            ),
          );
      },
      child: isGridView
          ? _buildGridTile(context, ref)
          : _buildListTile(context, ref),
    );
  }

  Widget _buildGridTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

    return Card(
      color: theme.primary, // Background color if image fails
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Important for clipping the image and gradients
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- Layer 1: The Image (fills the whole card) ---
          CachedNetworkImage(
            imageUrl: product.imageUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
            ),
          ),

          // --- Layer 2: Top overlay for the Product Name ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Text(
                product.name,
                // FIX: Title is now a single line
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                ),
              ),
            ),
          ),

          // --- Layer 3: Bottom overlay for Store and Price ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // FIX: Using the smaller logo size
                  StoreLogo(storeName: product.store, height: 18),
                  Text(
                    '$priceString Fr.',
                    style: TextStyle(
                      color: theme.secondary,
                      fontWeight: FontWeight.bold,
                      // FIX: Using the smaller font size
                      fontSize: 14,
                      shadows: const [Shadow(blurRadius: 2.0, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- No changes needed for the list tile layout ---
  Widget _buildListTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

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
              style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
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
                '$priceString Fr.',
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
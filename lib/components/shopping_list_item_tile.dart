// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for direct use
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
    this.isGridView = false, // Defaults to list view
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shared gesture handler for both grid and list views
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final initialIndex = allProductsInList.indexWhere((p) => p.id == product.id);
        if (initialIndex != -1) {
          Navigator.of(context).push(SlideUpPageRoute(
            page: ProductSwiperScreen(
              products: allProductsInList,
              initialIndex: initialIndex,
            ),
          ));
        }
      },
      onDoubleTap: () {
        // This logic now applies to the grid view as well, fixing the bug.
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

  // --- NEW: Method to build the grid tile with the requested layout ---
  Widget _buildGridTile(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

    return Card(
      color: Colors.white, // White background for the image
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures Stack children respect the border radius
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- FIX: Using CachedNetworkImage directly to fill the space ---
          // This resolves the missing parameter error.
          CachedNetworkImage(
            imageUrl: product.imageUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
          ),

          // Price in top-right corner
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)
                  ]
              ),
              child: Text(
                '$priceString Fr.',
                style: const TextStyle(
                  color: Colors.black, // Explicitly black as requested
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Store logo in top-left
          Positioned(
            top: 6,
            left: 6,
            child: StoreLogo(storeName: product.store, height: 24),
          ),

          // Title at the bottom with a gradient for readability
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
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                ),
              ),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- This is the original list tile layout from your file ---
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
              // Using ImageWithAspectRatio here is correct because we have a fixed size
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
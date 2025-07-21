// lib/pages/product_details.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/components/category_chip.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class ProductDetails extends ConsumerWidget {
  final Product product;
  final int currentIndex;
  final int totalItems;

  const ProductDetails({
    super.key,
    required this.product,
    required this.currentIndex,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Dismissible(
        key: ValueKey('dismissible_${product.id}'),
        direction: DismissDirection.endToStart,
        background: Container(color: Colors.transparent),
        secondaryBackground: Container(
          color: AppColors.primary,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Open Link',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.open_in_new, color: Colors.white, size: 28),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          _launchURL(context, product.url);
          return false;
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary,
                blurRadius: 10.0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            // ===================================================================
            // === KEY CHANGE: Use LayoutBuilder to create an adaptive layout ===
            // ===================================================================
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    // 1. Force the content column to fill the available height
                    height: constraints.maxHeight,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, ref),
                        const SizedBox(height: 12),
                        _buildCategoryRows(),
                        const SizedBox(height: 12),
                        _buildProductName(),

                        // 2. Add a Spacer to push content apart vertically
                        const Spacer(),

                        _buildImageContainer(context, ref),

                        // 3. Add another Spacer to push the prices to the bottom
                        const Spacer(),

                        _buildAvailabilityInfo(),
                        _buildSonderkonditionInfo(),
                        _buildPriceRow(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ALL OTHER METHODS BELOW THIS LINE ARE UNCHANGED.

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: StoreLogo(storeName: product.store, height: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: _buildCombinedHeaderButton(context, ref),
        ),
      ],
    );
  }

  Widget _buildCombinedHeaderButton(BuildContext context, WidgetRef ref) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Merkl...';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '$currentIndex / $totalItems',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inactive,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                color: AppColors.inactive.withOpacity(0.4),
                thickness: 1,
                width: 1,
              ),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => const ShoppingListBottomSheet(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.playlist_add_check,
                        color: AppColors.secondary,
                        size: 24.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: AppColors.inactive,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRows() {
    return Row(
      children: [
        Expanded(child: CategoryChip(categoryName: product.category)),
        if (product.subcategory.isNotEmpty) ...[
          const SizedBox(width: 16.0),
          Expanded(child: CategoryChip(categoryName: product.subcategory)),
        ],
      ],
    );
  }

  Widget _buildProductName() {
    return Text(
      product.name,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildImageContainer(BuildContext context, WidgetRef ref) {
    final double imageMaxHeight = MediaQuery.of(context).size.height * 0.3;

    return Stack(
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: imageMaxHeight),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageWithAspectRatio(
              imageUrl: product.imageUrl,
              maxWidth: double.infinity,
              maxHeight: imageMaxHeight,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildOverlayButton(
            icon: Icons.add_shopping_cart,
            onPressed: () {
              final activeList = ref.read(activeShoppingListProvider);
              if (activeList != null) {
                ref.read(shoppingListsProvider.notifier).addToList(activeList, product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added to "$activeList"')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No active list. Please select one.')),
                );
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const ShoppingListBottomSheet(),
                );
              }
            },
            onLongPress: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => ShoppingListBottomSheet(
                product: product,
                onConfirm: (String selectedListName) {},
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _buildOverlayButton(
            icon: Icons.open_in_new,
            onPressed: () => _launchURL(context, product.url),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.availableFrom,
              style: const TextStyle(color: AppColors.inactive, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSonderkonditionInfo() {
    if (product.sonderkondition == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.star_border, color: Colors.yellow, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.sonderkondition!,
              style: const TextStyle(
                color: AppColors.inactive,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    final cleanPercentage = product.discountPercentage;
    const double priceFontSize = 24;

    return Row(
      children: [
        Expanded(
          child: _priceBox(
            product.normalPrice.toStringAsFixed(2),
            Colors.grey.shade300,
            TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _priceBox(
            '$cleanPercentage%',
            Colors.redAccent,
            TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _priceBox(
            product.currentPrice.toStringAsFixed(2),
            Colors.yellow.shade600,
            TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceBox(String value, Color bgColor, TextStyle textStyle) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: textStyle, textAlign: TextAlign.center),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open product link")),
        );
      }
    }
  }
}
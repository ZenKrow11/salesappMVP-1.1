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
    return Dismissible(
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
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.open_in_new, color: AppColors.primary, size: 28),
          ],
        ),
      ),

      // The rest of the Dismissible is unchanged.
      confirmDismiss: (direction) async {
        _launchURL(context, product.url);
        return false;
      },

      // The child is your original SingleChildScrollView with all its contents.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 16),
            _buildCategoryRows(),
            const SizedBox(height: 16),
            _buildProductName(),
            const SizedBox(height: 12),
            _buildImageContainer(context, ref),
            const SizedBox(height: 20),
            _buildAvailabilityInfo(),
            _buildSonderkonditionInfo(),
            if (product.sonderkondition != null)
              const Divider(height: 32, color: Colors.white24),
            _buildPriceRow(),
          ],
        ),
      ),
    );
  }

  // ALL OTHER METHODS BELOW THIS LINE ARE COMPLETELY UNCHANGED.

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: StoreLogo(storeName: product.store, height: 48),
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: 2,
          child: _buildCounter(),
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: 3,
          child: _buildActiveListButton(context, ref),
        ),
      ],
    );
  }

  Widget _buildCounter() {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(
        '$currentIndex / $totalItems',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.inactive,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActiveListButton(BuildContext context, WidgetRef ref) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';
    return TextButton.icon(
      icon: const Icon(Icons.playlist_add_check, color: AppColors.secondary, size: 24.0),
      label: Text(
        buttonText,
        style: const TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => const ShoppingListBottomSheet(),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        minimumSize: const Size(0, 48),
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
    return SizedBox(
      height: 85.0,
      child: Text(
        product.name,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
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
    return Stack(
      children: [
        Container(
          height: 300,
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
              maxHeight: 300,
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
    return Row(
      children: [
        Expanded(
          child: _priceBox(
            product.normalPrice.toStringAsFixed(2),
            Colors.grey.shade300,
            const TextStyle(
              fontSize: 30,
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
            const TextStyle(
              fontSize: 30,
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
            const TextStyle(
              fontSize: 30,
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
      height: 75,
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
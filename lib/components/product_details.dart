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

  const ProductDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StoreLogo(storeName: product.store, height: 48),
        const Spacer(),
        _buildActiveListButton(context, ref),
      ],
    );
  }

  // --- UPDATED to use the new unified bottom sheet ---
  Widget _buildActiveListButton(BuildContext context, WidgetRef ref) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';

    return TextButton.icon(
      icon: const Icon(Icons.playlist_add_check, color: AppColors.secondary, size: 20),
      label: Text(
        buttonText,
        style: const TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // This opens the sheet in "select active list" mode.
        builder: (ctx) => const ShoppingListBottomSheet(),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: AppColors.inactive.withAlpha(128)),
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

  // --- UPDATED to accept onLongPress ---
  Widget _buildOverlayButton({
    required IconData icon,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
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

  // --- UPDATED with quick add (onPressed) and choose list (onLongPress) ---
  Widget _buildImageContainer(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
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
            // Quick Add: Add to active list on short press
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
            // Choose List: Open bottom sheet to choose a list on long press
            onLongPress: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => ShoppingListBottomSheet(
                product: product,
                onConfirm: (String selectedListName) {
                  // The sheet already shows a snackbar, but you could add more logic here.
                },
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
    final cleanPercentage = product.discountPercentage.replaceAll(RegExp(r'[^0-9.]'), '');

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
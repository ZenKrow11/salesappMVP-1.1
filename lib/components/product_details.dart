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
import 'package:sales_app_mvp/widgets/app_theme.dart';

// Back to a simple, stateless ConsumerWidget.
class ProductDetails extends ConsumerWidget {
  final Product product;
  final int currentIndex;
  final int totalItems;

  // NEW: Callbacks to communicate with the parent screen.
  final Function(double progress) onDragUpdate;
  final VoidCallback onDismissCancelled;

  const ProductDetails({
    super.key,
    required this.product,
    required this.currentIndex,
    required this.totalItems,
    required this.onDragUpdate,
    required this.onDismissCancelled,
  });

  void _handleDoubleTapSave(BuildContext context, WidgetRef ref) {
    final activeList = ref.read(activeShoppingListProvider);
    final theme = ref.read(themeProvider);

    if (activeList != null) {
      ref.read(shoppingListsProvider.notifier).addToList(activeList, product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to "$activeList"')),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const ShoppingListBottomSheet(),
      );
    }
  }

  void _handleFlickUpOpenURL(BuildContext context) {
    _launchURL(context, product.url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Center(
      child: Dismissible(
        key: ValueKey('dismissible_product_${product.id}'),
        direction: DismissDirection.vertical,

        // KEY CHANGE: Report the drag progress up to the parent.
        onUpdate: (details) {
          onDragUpdate(details.progress);
        },

        onDismissed: (direction) {
          if (direction == DismissDirection.down) {
            Navigator.of(context).pop();
          }
        },

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.down) {
            return true;
          }
          if (direction == DismissDirection.up) {
            _handleFlickUpOpenURL(context);
            // Tell the parent to reset its opacity because the dismiss was cancelled.
            onDismissCancelled();
            return false;
          }
          return false;
        },

        background: Container(color: Colors.transparent),

        // The child card is now fully opaque at all times.
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: theme.primary,
                blurRadius: 10.0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    height: constraints.maxHeight,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, ref, theme),
                        const SizedBox(height: 12),
                        _buildCategoryRows(),
                        const SizedBox(height: 12),
                        _buildProductName(theme),
                        const Spacer(),
                        _buildImageContainer(context, ref, theme, onDoubleTap: () => _handleDoubleTapSave(context, ref)),
                        const Spacer(),
                        _buildAvailabilityInfo(theme),
                        _buildSonderkonditionInfo(theme),
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

  Widget _buildImageContainer(BuildContext context, WidgetRef ref, AppThemeData theme, {required VoidCallback onDoubleTap}) {
    final double imageMaxHeight = MediaQuery.of(context).size.height * 0.3;

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
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

  // --- All other helper methods are unchanged ---
  Widget _buildHeader(BuildContext context, WidgetRef ref, AppThemeData theme) {
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
          child: _buildCombinedHeaderButton(context, ref, theme),
        ),
      ],
    );
  }

  Widget _buildCombinedHeaderButton(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Merkl...';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.primary,
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
                    style: TextStyle(
                      color: theme.inactive,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                color: theme.inactive.withOpacity(0.4),
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
                    backgroundColor: theme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => const ShoppingListBottomSheet(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_add_check,
                        color: theme.secondary,
                        size: 24.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        buttonText,
                        style: TextStyle(
                          color: theme.inactive,
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

  Widget _buildProductName(AppThemeData theme) {
    return Text(
      product.name,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: theme.inactive,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAvailabilityInfo(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.availableFrom,
              style: TextStyle(color: theme.inactive, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSonderkonditionInfo(AppThemeData theme) {
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
              style: TextStyle(
                color: theme.inactive,
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
}
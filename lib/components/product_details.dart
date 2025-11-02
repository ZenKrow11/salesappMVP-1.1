// lib/components/product_details.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/components/category_chip.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_app_mvp/services/notification_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProductDetails extends ConsumerWidget {
  final PlainProduct product;
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
    return SafeArea(
      // Using `SafeArea` at the top level is good practice
      child: GestureDetector(
        onDoubleTap: () => _toggleItemInList(context, ref),
        onLongPress: () {
          final theme = ref.read(themeProvider);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: theme.background,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => const ShoppingListBottomSheet(),
          );
        },
        child: _buildCardContent(context, ref),
      ),
    );
  }

  void _toggleItemInList(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeList = ref.read(activeShoppingListProvider);

    final notifier = ref.read(shoppingListsProvider.notifier);
    final theme = ref.read(themeProvider);
    final hiveProduct = Product(
        id: product.id,
        store: product.store,
        name: product.name,
        currentPrice: product.currentPrice,
        normalPrice: product.normalPrice,
        discountPercentage: product.discountPercentage,
        category: product.category.isEmpty ? 'categoryUncategorized' : product.category,
        subcategory: product.subcategory,
        url: product.url,
        imageUrl: product.imageUrl,
        nameTokens: product.nameTokens,
        dealStart: product.dealStart,
        specialCondition: product.specialCondition,
        dealEnd: product.dealEnd,
        isCustom: product.isCustom,
        isOnSale: product.isOnSale);
    final shoppingListProducts =
        ref.read(shoppingListWithDetailsProvider).value ?? [];
    final isItemInList =
    shoppingListProducts.any((item) => item.id == product.id);
    if (isItemInList) {
      notifier.removeItemFromList(hiveProduct);
      // 2. UPDATE THIS LINE
      NotificationManager.show(context, l10n.removedFrom(activeList));
    } else {
      notifier.addToList(hiveProduct, context);
      // 3. UPDATE THIS LINE
      NotificationManager.show(context, l10n.addedTo(activeList));
    }
  }

  void _launchURL(BuildContext context, WidgetRef ref, String url) async {
    final uri = Uri.parse(url);
    // theme is no longer needed here
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (context.mounted) {
        // 4. UPDATE THIS LINE
        NotificationManager.show(context, l10n.couldNotOpenProductLink);
      }
    }
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final shoppingListProducts = asyncShoppingList.value ?? [];
    final isInShoppingList =
    shoppingListProducts.any((item) => item.id == product.id);

    // --- The changes are in this Container and the removed ClipRRect ---
    return Container(
      // REMOVED: margin, boxShadow, and borderRadius.
      // The color now acts as the page's background.
      color: theme.primary,
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            height: constraints.maxHeight,
            // The padding is kept to prevent content from touching the screen edges.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref, theme),
                  const SizedBox(height: 12),
                  _buildCategoryRow(context),
                  const SizedBox(height: 12),
                  _buildProductName(theme),
                  const Spacer(),
                  _buildSpecialConditionInfo(theme),
                  const SizedBox(height: 8),
                  // The image container itself still has rounded corners, which looks nice.
                  _buildImageContainer(context, ref, theme, isInShoppingList),
                  const SizedBox(height: 12),
                  _buildPriceRow(ref),
                  _buildAvailabilityInfo(context, theme),
                  const Spacer(),
                  _buildActionRow(context, ref, theme, isInShoppingList),
                ]),
          ),
        );
      }),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, AppThemeData theme,
      bool isInShoppingList) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: _buildCloseButton(context, theme, l10n)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildAddToListButton(
                  context, ref, theme, isInShoppingList, l10n)),
        ],
      ),
    );
  }

  Widget _buildCloseButton(
      BuildContext context, AppThemeData theme, AppLocalizations l10n) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(color: theme.accent, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.close, color: theme.accent),
      label: Text(
        l10n.close,
        style: TextStyle(
          color: theme.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddToListButton(BuildContext context, WidgetRef ref,
      AppThemeData theme, bool isInShoppingList, AppLocalizations l10n) {
    if (isInShoppingList) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: theme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _toggleItemInList(context, ref),
        icon: Icon(Icons.remove, color: theme.primary),
        label: Text(
          l10n.remove, // Assumes 'remove' key exists in your l10n file
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(color: theme.secondary, width: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _toggleItemInList(context, ref),
        icon: Icon(Icons.add, color: theme.secondary),
        label: Text(
          l10n.add,
          style: TextStyle(
            color: theme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildImageContainer(BuildContext context, WidgetRef ref,
      AppThemeData theme, bool isInShoppingList) {
    final double imageMaxHeight = MediaQuery.of(context).size.height * 0.3;
    return Container(
      constraints: BoxConstraints(maxHeight: imageMaxHeight),
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isInShoppingList
              ? Border.all(color: theme.secondary, width: 2.5)
              : null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white),
            ImageWithAspectRatio(
                imageUrl: product.imageUrl,
                maxWidth: double.infinity,
                maxHeight: imageMaxHeight),
            if (isInShoppingList)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: theme.secondary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1))
                      ]),
                  child: Icon(
                    Icons.check,
                    color: theme.primary,
                    size: 20,
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _launchURL(context, ref, product.url),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfo(BuildContext context, AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    String formatDate(DateTime? date) {
      if (date == null) return '';
      return DateFormat.yMd(Localizations.localeOf(context).toString())
          .format(date);
    }

    final fromDate = formatDate(product.dealStart);
    final toDate = formatDate(product.dealEnd);
    String availabilityText;
    if (fromDate.isNotEmpty && toDate.isNotEmpty) {
      availabilityText = l10n.validFromTo(fromDate, toDate);
    } else if (fromDate.isNotEmpty) {
      availabilityText = l10n.validFrom(fromDate);
    } else if (toDate.isNotEmpty) {
      availabilityText = l10n.validUntil(toDate);
    } else {
      availabilityText = l10n.validityUnknown;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(children: [
        Icon(Icons.calendar_today, color: theme.secondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: AutoSizeText(
            availabilityText,
            style: TextStyle(color: theme.inactive, fontSize: 18),
            maxLines: 1,
            minFontSize: 10,
          ),
        ),
      ]),
    );
  }

  Widget _buildPriceRow(WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(ref.context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${product.normalPrice.toStringAsFixed(2)} ${l10n.currencyFrancs}',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.lineThrough,
            color: theme.inactive.withAlpha(150),
          ),
        ),
        Text(
          '${product.discountPercentage}%',
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        Text(
          '${product.currentPrice.toStringAsFixed(2)} ${l10n.currencyFrancs}',
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: theme.inactive,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        StoreLogo(storeName: product.store, height: 40),
        Expanded(
          child: Text(
            '$currentIndex / $totalItems',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.inactive.withAlpha(180),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ),
        _buildSelectListButton(context, ref, theme),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CategoryChip(categoryKey: product.category),
        ),
        if (product.subcategory.isNotEmpty && product.subcategory != 'categoryUncategorized') ...[
          const SizedBox(width: 8),
          Expanded(
            child: CategoryChip(categoryKey: product.subcategory),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectListButton(
      BuildContext context, WidgetRef ref, AppThemeData theme) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList;
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: theme.background,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => const ShoppingListBottomSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: theme.primary, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.playlist_add_check, color: theme.secondary, size: 20.0),
          const SizedBox(width: 8),
          Text(buttonText,
              style: TextStyle(
                  color: theme.inactive,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildProductName(AppThemeData theme) {
    return AutoSizeText(
      product.name,
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: theme.inactive),
      maxLines: 3,
      minFontSize: 14,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpecialConditionInfo(AppThemeData theme) {
    if (product.specialCondition == null) return const SizedBox.shrink();
    return Row(children: [
      Icon(Icons.star, color: theme.secondary, size: 26),
      const SizedBox(width: 8),
      Expanded(
        child: AutoSizeText(
          product.specialCondition!,
          style: TextStyle(
              color: theme.inactive,
              fontSize: 18,
              fontWeight: FontWeight.w500),
          maxLines: 2,
          minFontSize: 12,
        ),
      ),
    ]);
  }
}
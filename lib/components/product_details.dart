// lib/components/product_details.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales_app_mvp/components/category_chip.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/plain_product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:url_launcher/url_launcher.dart';
// Note: This path points to the file we just refactored
import 'package:sales_app_mvp/widgets/notification_helper.dart';

enum _GestureType { none, swipingUp, swipingDown }

class ProductDetails extends ConsumerStatefulWidget {
  final PlainProduct product;
  final int currentIndex;
  final int totalItems;
  final Function(double progress) onDragUpdate;
  final VoidCallback onDismissCancelled;
  final VoidCallback onDismissConfirmed;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ProductDetails({
    super.key,
    required this.product,
    required this.currentIndex,
    required this.totalItems,
    required this.onDragUpdate,
    required this.onDismissCancelled,
    required this.onDismissConfirmed,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  ConsumerState<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends ConsumerState<ProductDetails>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeUpController;
  _GestureType _gestureType = _GestureType.none;
  double _dragDownOffset = 0.0;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _swipeUpController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _swipeUpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _launchURL(context, widget.product.url);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _swipeUpController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _swipeUpController.dispose();
    super.dispose();
  }

  // --- GESTURE HANDLING (Unchanged) ---
  void _onVerticalDragStart(DragStartDetails details) {
    _gestureType = _GestureType.none;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissed) return;
    if (_gestureType == _GestureType.none) {
      _gestureType =
      details.delta.dy < 0 ? _GestureType.swipingUp : _GestureType.swipingDown;
      setState(() {});
    }
    if (_gestureType == _GestureType.swipingDown) {
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() => _dragDownOffset += details.delta.dy);
      widget.onDragUpdate(_dragDownOffset.abs() / screenHeight);
    } else if (_gestureType == _GestureType.swipingUp) {
      final screenHeight = MediaQuery.of(context).size.height;
      double progress =
          _swipeUpController.value - (details.delta.dy / (screenHeight * 0.5));
      _swipeUpController.value = progress.clamp(0.0, 1.0);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissed) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final flingVelocity = details.velocity.pixelsPerSecond.dy;
    if (_gestureType == _GestureType.swipingDown) {
      if (_dragDownOffset > screenHeight / 3 || flingVelocity > 800) {
        setState(() => _isDismissed = true);
        widget.onDismissConfirmed();
        Navigator.of(context).pop();
      } else {
        setState(() => _dragDownOffset = 0.0);
        widget.onDismissCancelled();
      }
    } else if (_gestureType == _GestureType.swipingUp) {
      if (_swipeUpController.value > 0.4 || flingVelocity < -800) {
        _swipeUpController.forward();
      } else {
        _swipeUpController.reverse();
      }
    }
    _gestureType = _GestureType.none;
  }
  // --- END GESTURE HANDLING ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onDoubleTap: () => _handleDoubleTapSave(context, ref),
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
      child: AnimatedBuilder(
        animation: _swipeUpController,
        builder: (context, _) {
          final cardContent = _buildCardContent(context, ref);
          if (_gestureType == _GestureType.swipingUp ||
              _swipeUpController.isAnimating ||
              _swipeUpController.isCompleted) {
            final scale = 1.0 - (_swipeUpController.value * 0.25);
            final slideOffset = _swipeUpController.value * -1.0;
            final opacity = 1.0 - (_swipeUpController.value * 0.5);
            return Stack(children: [
              cardContent,
              Transform.translate(
                  offset: Offset(0, slideOffset * MediaQuery.of(context).size.height),
                  child: Transform.scale(
                      scale: scale,
                      child: Opacity(opacity: opacity, child: cardContent))),
            ]);
          } else {
            return Transform.translate(
                offset: Offset(0, _dragDownOffset), child: cardContent);
          }
        },
      ),
    );
  }

  void _handleDoubleTapSave(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(shoppingListsProvider.notifier);

    // Create the Hive-compatible object from the PlainProduct
    final hiveProduct = Product(
        id: widget.product.id,
        store: widget.product.store,
        name: widget.product.name,
        currentPrice: widget.product.currentPrice,
        normalPrice: widget.product.normalPrice,
        discountPercentage: widget.product.discountPercentage,
        category: widget.product.category,
        subcategory: widget.product.subcategory,
        url: widget.product.url,
        imageUrl: widget.product.imageUrl,
        nameTokens: widget.product.nameTokens,
        dealStart: widget.product.dealStart,
        sonderkondition: widget.product.sonderkondition,
        dealEnd: widget.product.dealEnd,
        isCustom: widget.product.isCustom,
        isOnSale: widget.product.isOnSale
    );

    final shoppingListProducts = ref.read(shoppingListWithDetailsProvider).value ?? [];
    final isItemInList = shoppingListProducts.any((item) => item.id == widget.product.id);

    if (isItemInList) {
      notifier.removeItemFromList(hiveProduct);
      // --- FIX 1 ---
      showAppNotification(context, ref, message: 'Removed from "Merkliste"', position: NotificationPosition.top);
    } else {
      notifier.addToList(hiveProduct);
      // --- FIX 2 ---
      showAppNotification(context, ref, message: 'Added to "Merkliste"', position: NotificationPosition.top);
    }
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
        // --- FIX 3 ---
        showAppNotification(
          context,
          ref,
          message: "Could not open product link",
          position: NotificationPosition.top,
          icon: Icons.error_outline, // Good to use an error icon here
        );
      }
    }
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final shoppingListProducts = asyncShoppingList.value ?? [];
    final isInShoppingList = shoppingListProducts.any((item) => item.id == widget.product.id);

    final cardUi = Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                  color: _isDismissed ? Colors.transparent : theme.primary,
                  blurRadius: 10.0,
                  offset: const Offset(0, 5))
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: LayoutBuilder(builder: (context, constraints) {
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
                      _buildCategoryRow(),
                      const SizedBox(height: 12),
                      _buildProductName(theme),
                      const Spacer(),
                      _buildSonderkonditionInfo(theme),
                      const SizedBox(height: 8),
                      _buildImageContainer(context, theme, isInShoppingList),
                      const SizedBox(height: 12),
                      _buildPriceRow(),
                      _buildAvailabilityInfo(theme),
                      const Spacer(),
                    ]),
              ),
            );
          }),
        ),
      ),
    );

    return Stack(alignment: Alignment.center, children: [
      cardUi,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(children: [
          if (widget.currentIndex > 1)
            _NavigationButton(icon: Icons.arrow_back_ios_new, onTap: widget.onPrevious),
          const Spacer(),
          if (widget.currentIndex < widget.totalItems)
            _NavigationButton(icon: Icons.arrow_forward_ios, onTap: widget.onNext),
        ]),
      ),
    ]);
  }

  // --- WIDGET BUILDER METHODS (mostly unchanged) ---
  // (No changes needed in the rest of the file)
  Widget _buildHeader(BuildContext context, WidgetRef ref, AppThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        StoreLogo(storeName: widget.product.store, height: 40),
        Expanded(
          child: Text(
            '${widget.currentIndex} / ${widget.totalItems}',
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

  Widget _buildCategoryRow() {
    return Row(
      children: [
        Expanded(
          child: CategoryChip(categoryName: widget.product.category),
        ),
        if (widget.product.subcategory.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: CategoryChip(categoryName: widget.product.subcategory),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectListButton(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';
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
    return Text(widget.product.name,
        style: TextStyle(
            fontSize: 25, fontWeight: FontWeight.bold, color: theme.inactive),
        maxLines: 3,
        overflow: TextOverflow.ellipsis);
  }

  Widget _buildSonderkonditionInfo(AppThemeData theme) {
    if (widget.product.sonderkondition == null) return const SizedBox.shrink();
    return Row(children: [
      Icon(Icons.star,
          color: theme.secondary, size: 26),
      const SizedBox(width: 8),
      Expanded(
          child: Text(widget.product.sonderkondition!,
              style: TextStyle(
                  color: theme.inactive,
                  fontSize: 18,
                  fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildImageContainer(
      BuildContext context, AppThemeData theme, bool isInShoppingList) {
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
                imageUrl: widget.product.imageUrl,
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
                      shape: BoxShape.circle,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfo(AppThemeData theme) {
    String formatDate(DateTime? date) {
      if (date == null) return '';
      return DateFormat('dd.MM.yyyy').format(date);
    }

    final fromDate = formatDate(widget.product.dealStart);
    final toDate = formatDate(widget.product.dealEnd);

    String availabilityText;

    if (fromDate.isNotEmpty && toDate.isNotEmpty) {
      availabilityText = 'Gültig vom $fromDate bis $toDate';
    } else if (fromDate.isNotEmpty) {
      availabilityText = 'Gültig ab $fromDate';
    } else if (toDate.isNotEmpty) {
      availabilityText = 'Gültig bis $toDate';
    } else {
      availabilityText = 'Gültigkeit unbekannt';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(children: [
        Icon(Icons.calendar_today, color: theme.secondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                availabilityText,
                style: TextStyle(color: theme.inactive, fontSize: 18)
            )
        ),
      ]),
    );
  }

  Widget _buildPriceRow() {
    final theme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${widget.product.normalPrice.toStringAsFixed(2)} Fr.',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.lineThrough,
            color: theme.inactive.withAlpha(150),
          ),
        ),
        Text(
          '${widget.product.discountPercentage}%',
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        Text(
          '${widget.product.currentPrice.toStringAsFixed(2)} Fr.',
          style: GoogleFonts.montserrat(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: theme.inactive,
          ),
        ),
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavigationButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 28.0),
      ),
    );
  }
}
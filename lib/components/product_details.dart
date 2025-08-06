// lib/components/product_details.dart

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

// Enum to manage the gesture state.
enum _GestureType { none, swipingUp, swipingDown }

class ProductDetails extends ConsumerStatefulWidget {
  final Product product;
  final int currentIndex;
  final int totalItems;
  final Function(double progress) onDragUpdate;
  final VoidCallback onDismissCancelled;
  final VoidCallback onDismissConfirmed;

  const ProductDetails({
    super.key,
    required this.product,
    required this.currentIndex,
    required this.totalItems,
    required this.onDragUpdate,
    required this.onDismissCancelled,
    required this.onDismissConfirmed,
  });

  @override
  ConsumerState<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends ConsumerState<ProductDetails>
    with SingleTickerProviderStateMixin {
  // --- STATE MANAGEMENT ---

  // Controller for the "swipe up" animation (fly away/snap back).
  late final AnimationController _swipeUpController;

  // Tracks the current gesture mode.
  _GestureType _gestureType = _GestureType.none;

  // Tracks the vertical drag offset for the "swipe down" gesture.
  double _dragDownOffset = 0.0;

  // Tracks if the card has been dismissed to prevent further interaction.
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _swipeUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swipeUpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // The card has flown off screen. Now launch the URL.
        _launchURL(context, widget.product.url);

        // After a delay, reset the controller so the user can interact again
        // if they return to the screen without switching pages.
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _swipeUpController.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _swipeUpController.dispose();
    super.dispose();
  }

  // --- GESTURE HANDLERS ---

  void _onVerticalDragStart(DragStartDetails details) {
    // Reset state at the beginning of a new drag.
    _gestureType = _GestureType.none;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissed) return;

    // Determine gesture type on the first update.
    if (_gestureType == _GestureType.none) {
      _gestureType =
      details.delta.dy < 0 ? _GestureType.swipingUp : _GestureType.swipingDown;
      setState(() {}); // Rebuild to show the correct UI (single card vs stack).
    }

    if (_gestureType == _GestureType.swipingDown) {
      final screenHeight = MediaQuery.of(context).size.height;
      // Update the drag offset.
      setState(() {
        _dragDownOffset += details.delta.dy;
      });
      // Update the parent's background opacity based on drag progress.
      widget.onDragUpdate(_dragDownOffset.abs() / screenHeight);
    } else if (_gestureType == _GestureType.swipingUp) {
      final screenHeight = MediaQuery.of(context).size.height;
      // Directly drive the animation controller with the drag progress.
      // We use a negative delta because swiping up gives a negative dy.
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
      // Dismiss if dragged more than 1/3 of the screen or with a high velocity.
      if (_dragDownOffset > screenHeight / 3 || flingVelocity > 800) {
        setState(() {
          _isDismissed = true;
        });
        widget.onDismissConfirmed(); // Disable parent gestures.
        Navigator.of(context).pop();
      } else {
        // Snap back to place.
        setState(() {
          _dragDownOffset = 0.0;
        });
        widget.onDismissCancelled(); // Reset parent background.
      }
    } else if (_gestureType == _GestureType.swipingUp) {
      // Complete the "fly away" if dragged more than 40% or with a high velocity.
      if (_swipeUpController.value > 0.4 || flingVelocity < -800) {
        _swipeUpController.forward();
      } else {
        // Reverse the animation to snap back.
        _swipeUpController.reverse();
      }
    }

    // Reset gesture type for the next interaction.
    _gestureType = _GestureType.none;
  }

  // --- UI BUILDER ---

  @override
  @override
  Widget build(BuildContext context) {
    // GestureDetector is now the root controller.
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
          // This is the single, reusable card content widget.
          final cardContent = _buildCardContent(context, ref);

          if (_gestureType == _GestureType.swipingUp ||
              _swipeUpController.isAnimating ||
              _swipeUpController.isCompleted) {
            // --- UI FOR SWIPE UP ---
            // Build the Stack with a static clone and a transformed top card.

            final scale = 1.0 - (_swipeUpController.value * 0.25); // 1.0 -> 0.75
            final slideOffset =
                _swipeUpController.value * -1.0; // 0.0 -> -1.0

            // NEW: Calculate the opacity. 1.0 -> 0.5 as the controller goes from 0.0 to 1.0
            final opacity = 1.0 - (_swipeUpController.value * 0.5);

            return Stack(
              children: [
                // The static "clone" card. It never moves.
                cardContent,

                // The top card that transforms.
                Transform.translate(
                  offset: Offset(
                      0, slideOffset * MediaQuery.of(context).size.height * 0.7),
                  child: Transform.scale(
                    scale: scale,
                    // NEW: Wrap the cardContent in an Opacity widget.
                    child: Opacity(
                      opacity: opacity,
                      child: cardContent,
                    ),
                  ),
                ),
              ],
            );
          } else {
            // --- UI FOR SWIPE DOWN or NO GESTURE ---
            // Build a single card, translated based on the drag-down offset.
            return Transform.translate(
              offset: Offset(0, _dragDownOffset),
              child: cardContent,
            );
          }
        },
      ),
    );
  }

  // --- HELPER WIDGETS AND FUNCTIONS ---
  // These remain unchanged from the original text file.

  void _handleDoubleTapSave(BuildContext context, WidgetRef ref) {
    final activeList = ref.read(activeShoppingListProvider);
    final theme = ref.read(themeProvider);
    if (activeList != null) {
      ref
          .read(shoppingListsProvider.notifier)
          .addToList(activeList, widget.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to "$activeList"')),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.background,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const ShoppingListBottomSheet(),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open product link")),
        );
      }
    }
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: _isDismissed ? Colors.transparent : theme.primary,
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
                      CategoryChip(categoryName: widget.product.category),
                      if (widget.product.subcategory.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        CategoryChip(categoryName: widget.product.subcategory),
                      ],
                      const SizedBox(height: 12),
                      _buildProductName(theme),
                      const Spacer(),
                      _buildSonderkonditionInfo(theme),
                      const SizedBox(height: 8),
                      _buildImageContainer(context, ref, theme),
                      const SizedBox(height: 12),
                      _buildPriceRow(),
                      const Spacer(),
                      _buildAvailabilityInfo(theme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AppThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        StoreLogo(storeName: widget.product.store, height: 40),
        const SizedBox(width: 16),
        Text(
          '${widget.currentIndex} / ${widget.totalItems}',
          style: TextStyle(
            color: theme.inactive.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _buildSelectListButton(context, ref, theme),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => const ShoppingListBottomSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_check,
              color: theme.secondary,
              size: 20.0,
            ),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: TextStyle(
                color: theme.inactive,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductName(AppThemeData theme) {
    return Text(
      widget.product.name,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: theme.inactive,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSonderkonditionInfo(AppThemeData theme) {
    if (widget.product.sonderkondition == null) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.star_border, color: Colors.yellow, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.product.sonderkondition!,
            style: TextStyle(
              color: theme.inactive,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(
      BuildContext context, WidgetRef ref, AppThemeData theme) {
    final double imageMaxHeight = MediaQuery.of(context).size.height * 0.3;

    return Container(
      constraints: BoxConstraints(maxHeight: imageMaxHeight),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageWithAspectRatio(
          imageUrl: widget.product.imageUrl,
          maxWidth: double.infinity,
          maxHeight: imageMaxHeight,
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfo(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.product.availableFrom,
              style: TextStyle(color: theme.inactive, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    final theme = ref.watch(themeProvider);
    final cleanPercentage = widget.product.discountPercentage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${widget.product.normalPrice.toStringAsFixed(2)} Fr.',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.lineThrough,
            color: theme.inactive.withOpacity(0.6),
          ),
        ),
        Text(
          '$cleanPercentage%',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        Text(
          '${widget.product.currentPrice.toStringAsFixed(2)} Fr.',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: theme.inactive,
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
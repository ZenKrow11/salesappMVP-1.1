// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductTile extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  Color _darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStyle = CategoryService.getStyleForCategory(product.category);
    final Color backgroundTint = _darken(categoryStyle.color, 0.4).withOpacity(0.15);
    final theme = ref.watch(themeProvider);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        // ... (your existing logic is perfect)
      },
      onLongPress: () {
        // ... (your existing logic is perfect)
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundTint,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContent(context, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(context, ref),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- LAYER 1: The Clean White Background ---
                Container(
                  color: Colors.white,
                ),

                // --- LAYER 2: The Product Image ---
                ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  maxHeight: double.infinity,
                  maxWidth: double.infinity,
                  fit: BoxFit.contain,
                ),

                // --- LAYER 3: The Star Icon ---
                if (product.sonderkondition != null)
                  Positioned(
                    top: 0,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        String.fromCharCode(Icons.star.codePoint),
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: Icons.star.fontFamily,
                          package: Icons.star.fontPackage,
                          color: theme.secondary,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: theme.primary,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(context, ref),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // --- WRAP THE ROW IN A SIZEDBOX TO ENSURE CONSISTENT HEIGHT ---
    return SizedBox(
      height: 38.0, // This forces space for two lines of text
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StoreLogo(
            storeName: product.store,
            height: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.inactive,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${product.discountPercentage}%',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        const Spacer(),
        Text(
          '${product.currentPrice.toStringAsFixed(2)} Fr.',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.inactive,
          ),
        ),
      ],
    );
  }
}
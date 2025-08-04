//lib/components/draggable_card_overlay.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';

/// A widget that provides the visual representation of the card being dragged.
/// It's designed to be shown in an Overlay.
class DraggableCardOverlay extends StatelessWidget {
  final Product product;
  final AppThemeData theme;

  const DraggableCardOverlay({
    super.key,
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is a smaller, translucent version of the main card.
    // We can tweak the scale and opacity values later.
    return Transform.scale(
      scale: 0.8, // Make it slightly smaller than the original
      child: Opacity(
        opacity: 0.85, // Make it slightly translucent
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // Fixed width
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // The card should only be as tall as its content
              children: [
                // Simplified content: just the image and name
                ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  // --- FIX APPLIED HERE ---
                  // It should take the full width of its parent container.
                  maxWidth: double.infinity,
                  // And have a reasonable max height to prevent it from being huge.
                  maxHeight: 300,
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    product.name,
                    style: TextStyle(
                      color: theme.inactive,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
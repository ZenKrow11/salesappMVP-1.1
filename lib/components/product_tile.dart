import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Store and product name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.store,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Image with aspect-ratio check
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AspectRatioFittingImage(
                imageUrl: product.imageUrl,
                maxHeight: 100,
                maxWidth: double.infinity,
              ),
            ),

            // Price details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _priceBox(
                    text: product.normalPrice.toStringAsFixed(2),
                    bgColor: Colors.grey[300],
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _priceBox(
                    text: '${product.discountPercentage}%',
                    bgColor: Colors.red,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _priceBox(
                    text: product.currentPrice.toStringAsFixed(2),
                    bgColor: Colors.yellow[600],
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox({required String text, required Color? bgColor, required TextStyle textStyle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}

class AspectRatioFittingImage extends StatelessWidget {
  final String imageUrl;
  final double maxHeight;
  final double maxWidth;

  const AspectRatioFittingImage({
    super.key,
    required this.imageUrl,
    required this.maxHeight,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty || !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No Image")),
      );
    }

    return FutureBuilder<Image>(
      future: _getSizedImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return snapshot.data!;
      },
    );
  }

  Future<Image> _getSizedImage() async {
    final image = Image.network(imageUrl);
    final completer = Completer<ImageInfo>();
    final stream = image.image.resolve(const ImageConfiguration());

    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    });

    stream.addListener(listener);
    final info = await completer.future;
    stream.removeListener(listener);

    final width = info.image.width.toDouble();
    final height = info.image.height.toDouble();
    final isWide = width >= height;

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: isWide ? maxWidth : null,
      height: isWide ? null : maxHeight,
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        height: 100,
        child: Center(child: Text("No Image")),
      ),
    );
  }
}

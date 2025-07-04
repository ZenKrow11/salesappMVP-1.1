import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageWithAspectRatio extends StatelessWidget {
  final String imageUrl;
  final double maxHeight;
  final double maxWidth;
  final BoxFit fit;

  const ImageWithAspectRatio({
    super.key,
    required this.imageUrl,
    required this.maxHeight,
    required this.maxWidth,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      height: maxHeight,
      width: maxWidth,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
    );
  }
}
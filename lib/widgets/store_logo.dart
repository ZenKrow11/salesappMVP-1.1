// lib/widgets/store_logo.dart

import 'package:flutter/material.dart';

class StoreLogo extends StatelessWidget {
  /// The name of the store to find a logo for.
  final String storeName;

  /// The height of the logo image.
  final double height;

  /// A map that connects store names (case-insensitive) to their asset paths.
  /// The keys should be the lowercase version of the store name from your data.
  static const Map<String, String> _logoMap = {
    'aldi': 'assets/images/store_logos/aldi_logo.png',
    'aligro': 'assets/images/store_logos/aligro_logo.png',
    'coop': 'assets/images/store_logos/coop_logo.png',
    'denner': 'assets/images/store_logos/denner_logo.png',
    'eurospar': 'assets/images/store_logos/eurospar_logo.png',
    'lidl': 'assets/images/store_logos/lidl_logo.png',
    'migros': 'assets/images/store_logos/migros_logo.png',
    "ottos": 'assets/images/store_logos/ottos_logo.png',
    'spar': 'assets/images/store_logos/spar_logo.png',
    'volg': 'assets/images/store_logos/volg_logo.png',
  };

  /// The fallback asset to use if a specific store logo isn't found.
  static const String _defaultLogoPath = 'assets/images/store_logos/default_store_logo.png';

  const StoreLogo({
    super.key,
    required this.storeName,
    this.height = 24, // A good default height
  });

  static Null get assets => null;

  @override
  Widget build(BuildContext context) {

    final logoPath = _logoMap[storeName.toLowerCase()] ?? _defaultLogoPath;

    return Image.asset(
      logoPath,
      height: height,
      // This is a good practice for handling errors if an asset is missing
      // or if the default logo itself can't be found.
      errorBuilder: (context, error, stackTrace) {
        // If the logo fails to load, show a generic store icon as a final fallback.
        return Icon(
          Icons.storefront_outlined,
          size: height,
          color: Colors.grey[600],
        );
      },
    );
  }
}
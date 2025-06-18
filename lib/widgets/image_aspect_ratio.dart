import 'package:flutter/material.dart';
import 'dart:async';

class ImageWithAspectRatio extends StatelessWidget {
  final String imageUrl;
  final double maxHeight;
  final double maxWidth;

  const ImageWithAspectRatio({
    super.key,
    required this.imageUrl,
    required this.maxHeight,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Image>(
      future: _getImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final image = snapshot.data!;
        return image;
      },
    );
  }

  Future<Image> _getImage() async {
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
      height: isWide ? null : maxHeight,
      width: isWide ? maxWidth : null,
    );
  }
}

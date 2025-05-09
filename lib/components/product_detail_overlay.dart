import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import 'shopping_list_dialog.dart';
import '../providers/shopping_list_provider.dart';



class ProductDetailOverlay extends ConsumerWidget {
  final Product product;

  const ProductDetailOverlay({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final isFavorite = ref.watch(favoritesProvider).any((p) => p.id == product.id);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // dismiss when tapping outside
      behavior: HitTestBehavior.opaque,
      child: Stack(
          children: [
          GestureDetector(
          onTap: () {}, // absorb taps inside sheet
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40), // space for close button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.store,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            product.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 300,
                              width: 300,
                              child: (product.imageUrl.isEmpty || !(Uri.tryParse(product.imageUrl)?.hasAbsolutePath ?? false))
                                  ? const Center(child: Text("Placeholder Picture"))
                                  : Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Text("Placeholder Picture"));
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Chip(
                              label: Text(product.category),
                              backgroundColor: Colors.orangeAccent,
                              labelStyle: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(product.subcategory),
                              backgroundColor: Colors.orangeAccent.shade100,
                              labelStyle: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _PriceBox(
                              value: '${product.normalPrice.toStringAsFixed(2)}.-',
                              bgColor: Colors.grey.shade200,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                            _PriceBox(
                              value: '-${product.discountPercentage}%',
                              bgColor: Colors.redAccent,
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            _PriceBox(
                              value: '${product.currentPrice.toStringAsFixed(2)}.-',
                              bgColor: Colors.yellow,
                              textStyle: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SquareButton(
                              icon: Icons.open_in_new,
                              onPressed: () async {
                                final uri = Uri.parse(product.url);

                                try {
                                  final launched = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!launched) {
                                    throw 'Could not launch $uri';
                                  }
                                } catch (e) {
                                  debugPrint('Error launching URL: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Could not open link"),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),

                            _SquareButton(
                              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                              onPressed: () {
                                favoritesNotifier.toggleFavorite(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),

                            _SquareButton(
                              icon: Icons.view_list,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ShoppingListDialog(
                                    product: product,
                                    onConfirm: (listName) {
                                      ref.read(shoppingListsProvider.notifier).addItemToList(listName, product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Added to "$listName"'),
                                          duration: const Duration(seconds: 1),),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, size: 30, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
          );
        },
      ),
    ),
    ]
    )
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String value;
  final TextStyle textStyle;
  final Color bgColor;

  const _PriceBox({
    required this.value,
    required this.textStyle,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: textStyle),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const _SquareButton({required this.onPressed, required this.icon});

//bottom buttons layout
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Center(
          child: Icon(icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}
/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../models/product.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];
          return FavoriteItemTile(
            product: product,
            onRemove: () {
              favoritesNotifier.toggleFavorite(product);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from favorites'),
                  duration: const Duration(seconds: 1),),
              );
            },
          );
        },
      ),
    );
  }
}

class FavoriteItemTile extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;

  const FavoriteItemTile({
    super.key,
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.store,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.heart_broken,
                  size: 40,
                  color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
*/
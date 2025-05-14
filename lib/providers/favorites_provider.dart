/*import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/hive_storage_service.dart';


class FavoritesNotifier extends StateNotifier<List<Product>> {
  final HiveStorageService _hiveStorageService;

  FavoritesNotifier(this._hiveStorageService)
      : super(_hiveStorageService.getFavorites());

  void toggleFavorite(Product product) async {
    if (isFavorite(product)) {
      await _hiveStorageService.toggleFavorite(product);
      state = state.where((p) => p.id != product.id).toList();
    } else {
      await _hiveStorageService.toggleFavorite(product);
      state = [...state, product];
    }
  }

  bool isFavorite(Product product) {
    return state.any((p) => p.id == product.id);
  }
}

final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService.instance;
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Product>>((ref) {
  final hiveService = ref.watch(hiveStorageServiceProvider);
  return FavoritesNotifier(hiveService);
});
*/